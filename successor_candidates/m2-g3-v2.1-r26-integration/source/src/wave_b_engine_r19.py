from __future__ import annotations
import argparse, csv, datetime as dt, io, json, os, re, shutil, sys, traceback, zipfile
from pathlib import Path
from collections import Counter
from common import (PgTools, PgContext, canonical_hash, sha256_bytes, sha256_file,
                    copy_csv_into, rows_to_csv_bytes, read_json, write_json, run,
                    qident, sql_literal, normalize_pg_dump_schema_bytes)
import r19_engine as eng
import schema_contract as schema_contract
ROOT=Path(__file__).resolve().parents[1]
SCHEMA='msbf_r1_g3v2_r26'
BUILD_ID='MSBF_M1M2_R26_M2_11_M2_12_G3V2_RECERTIFICATION'
R4=ROOT/'inputs'/'PHASE2C_R4_STRATEGY.zip'; R17=ROOT/'inputs'/'msbf_r1_wave_a_r17_20260831_061333_WAVE_A_R17_RESULTS.zip'; R18=ROOT/'inputs'/'msbf_r1_wave_b_r18_20260831_091707_M2_11_M2_12_G3V2_RESULTS.zip'
DDL=(ROOT/'src'/'R19_M2_11_M2_12_G3V2_DDL.sql').read_text(encoding='utf-8')
CONTRACT=read_json(ROOT/'config'/'R19_RUNTIME_CONTRACT.json'); EXPECTED=read_json(ROOT/'config'/'R19_EXPECTED_SIMULATION_IDENTITY.json'); PROFILE=read_json(ROOT/'config'/'R19_STRATEGY_PROFILE_CONTRACT.json'); TABLE_CONTRACT=read_json(ROOT/'config'/'R19_TABLE_CONTRACT.json')

def nowstamp():return dt.datetime.now().strftime('%Y%m%d_%H%M%S')
def utcnow():return dt.datetime.now(dt.timezone.utc).isoformat()
def db_schema_fp(pg, db, scratch):
    out = scratch / (db + '.schema.sql')
    run([str(pg.tools.pg_dump), '-h', pg.host, '-p', str(pg.port), '-U', pg.user,
         '-d', db, '--schema-only', '--no-owner', '--no-privileges', '-f', str(out)], env=pg.env)
    raw = out.read_bytes()
    normalized = normalize_pg_dump_schema_bytes(raw)
    receipt = {
        'normalized_schema_sha256': sha256_bytes(normalized),
        'raw_schema_sha256_observational': sha256_bytes(raw),
        'raw_bytes': len(raw),
        'normalized_bytes': len(normalized),
        'pg17_guard_lines_removed': sum(
            1 for line in raw.decode('utf-8-sig', 'replace').replace('\r\n', '\n').split('\n')
            if re.match(r'^\\(?:un)?restrict(?:\s|$)', line)
        ),
        'normalization': 'LINE_ENDINGS_LF_AND_REMOVE_PG17_RANDOM_RESTRICT_GUARDS_ONLY',
    }
    out.unlink(missing_ok=True)
    return receipt


def schema_fp_equal(before, after):
    return before['normalized_schema_sha256'] == after['normalized_schema_sha256']


R6_EXPECTED_CONTROL = {
    'run_row_count': 1,
    'run_status': 'M2_4_ACCEPTED',
    'm2_4_registry_row_count': 1,
    'm2_4_contract_status': 'ACCEPTED',
    'm2_4_combined_set_hash': 'deedb8bd7696e441126a6f4526fc4842',
    'm2_4_gate_row_count': 1,
    'm2_4_gate_status': 'PASS',
    'm2_4_rebase_row_count': 1,
    'm2_4_rebase_status': 'VALIDATED_CANDIDATE',
    'account_rows': 130,
    'advance_rows': 130,
    'portfolio_rows': 130,
    'baseline_funded_rows': 103,
    'stress_funded_rows': 27,
    'physical_m2_4_rows': 6390,
    'downstream_pending': 8,
    'active_downstream_registries': 0,
    'active_downstream_gates': 0,
    'rebase_status_rows': 9,
    'rebase_status_exact_domain_rows': 9,
    'r4_application_rows': 1500,
    'r4_candidate_rows': 6519,
    'r4_final_decision_rows': 1500,
    'r4_gate_rows': 84228,
    'r4_proof_rows': 652,
    'source_integration_rows': 1,
    'compatibility_rows': 1500,
}


def r6_control_snapshot(pg, db):
    sql = r"""
    WITH r AS (
      SELECT count(*)::bigint row_count,max(rr.run_id)::bigint run_id,max(rr.run_status)::text run_status
      FROM msbf_ctl.run_registry rr
      WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1
    ), reg AS (
      SELECT count(*)::bigint row_count,max(cr.contract_status)::text contract_status,max(cr.combined_set_hash)::text combined_set_hash
      FROM msbf_ctl.m2_4_portfolio_activation_contract_registry cr CROSS JOIN r
      WHERE cr.module1_run_id=r.run_id
    ), gate AS (
      SELECT count(*)::bigint row_count,(array_agg(agr.result_status ORDER BY agr.review_version DESC))[1]::text result_status
      FROM msbf_ctl.acceptance_gate_result agr CROSS JOIN r
      WHERE agr.run_id=r.run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
    ), rb AS (
      SELECT count(*)::bigint row_count,max(ds.rebase_status)::text rebase_status
      FROM msbf_m12r1e.downstream_rebase_status ds WHERE ds.stage_code='M2_4'
    )
    SELECT jsonb_build_object(
      'run_row_count',r.row_count,'run_id',r.run_id,'run_status',r.run_status,
      'm2_4_registry_row_count',reg.row_count,'m2_4_contract_status',reg.contract_status,
      'm2_4_combined_set_hash',reg.combined_set_hash,
      'm2_4_gate_row_count',gate.row_count,'m2_4_gate_status',gate.result_status,
      'm2_4_rebase_row_count',rb.row_count,'m2_4_rebase_status',rb.rebase_status,
      'account_rows',(SELECT count(*) FROM msbf_m2.synthetic_account_activation),
      'advance_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding),
      'portfolio_rows',(SELECT count(*) FROM msbf_m2.initial_portfolio_activation),
      'baseline_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE scenario_code='BASELINE'),
      'stress_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE scenario_code='RECESSION_ENERGY'),
      'physical_m2_4_rows',(SELECT sum(n) FROM (
        SELECT count(*) n FROM msbf_m2.application_booking_funding_source_snapshot
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive
        UNION ALL SELECT count(*) FROM msbf_m2.synthetic_account_activation
        UNION ALL SELECT count(*) FROM msbf_m2.synthetic_advance_funding
        UNION ALL SELECT count(*) FROM msbf_m2.initial_portfolio_activation
      ) x),
      'downstream_pending',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status
        WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12') AND rebase_status='PENDING_REBASE'),
      'active_downstream_registries',(SELECT sum(n) FROM (
        SELECT count(*) n FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_6_intervention_strategy_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_8_servicing_execution_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
      ) x),
      'rebase_status_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status),
      'rebase_status_exact_domain_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status
        WHERE stage_code IN ('M2_4','M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12')),
      'r4_application_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_application_scenario),
      'r4_candidate_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_offer_candidate),
      'r4_final_decision_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_final_decision),
      'r4_gate_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_decision_gate),
      'r4_proof_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_no_feasible_structure_proof),
      'source_integration_rows',(SELECT count(*) FROM msbf_m12r1e.source_integration_registry),
      'compatibility_rows',(SELECT count(*) FROM msbf_m12r1e.application_final_offer_decision_compatibility),
      'active_downstream_gates',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE gate_id IN (
        'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING','M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY',
        'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL',
        'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION',
        'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'))
    )::text FROM r CROSS JOIN reg CROSS JOIN gate CROSS JOIN rb;
    """
    raw = pg.scalar(db, sql, read_only=True)
    if not raw:
        raise RuntimeError('Immutable R6 source-control query returned no row')
    snapshot = json.loads(raw)
    mismatches = {k: {'expected': v, 'actual': snapshot.get(k)} for k, v in R6_EXPECTED_CONTROL.items() if snapshot.get(k) != v}
    if mismatches:
        raise RuntimeError('Immutable R6 carrier control mismatch: ' + json.dumps(mismatches, sort_keys=True, separators=(',', ':')))
    return snapshot

def profile_rows():
    return schema_contract.profile_rows(PROFILE)

def database_schema_receipt(pg,db):
    expected=schema_contract.contract_tables(TABLE_CONTRACT)
    query=("SELECT c.table_name,c.column_name,c.data_type,c.ordinal_position "
           "FROM information_schema.columns AS c "
           "JOIN information_schema.tables AS t "
           "  ON t.table_schema=c.table_schema AND t.table_name=c.table_name "
           f"WHERE c.table_schema={sql_literal(SCHEMA)} AND t.table_type='BASE TABLE' "
           "ORDER BY c.table_name,c.ordinal_position")
    data=pg.copy_to_csv(db,query)
    rows=list(csv.DictReader(io.StringIO(data.decode('utf-8'))))
    actual={}
    for row in rows:
        actual.setdefault(row['table_name'],[]).append({'name':row['column_name'],'type':row['data_type']})
    view_data=pg.copy_to_csv(
        db,
        "SELECT table_name FROM information_schema.views "
        f"WHERE table_schema={sql_literal(SCHEMA)} ORDER BY table_name",
    )
    view_rows=list(csv.DictReader(io.StringIO(view_data.decode('utf-8'))))
    actual_views=[row['table_name'] for row in view_rows]
    expected_views=sorted(TABLE_CONTRACT.get('view_contracts',{}))
    checks={name:actual.get(name)==cols for name,cols in expected.items()}
    checks['table_domain_exact']=set(actual)==set(expected)
    checks['view_domain_exact']=actual_views==expected_views
    receipt={'status':'PASS' if all(checks.values()) else 'FAIL','checks':checks,
             'expected_tables':expected,'actual_tables':actual,
             'expected_views':expected_views,'actual_views':actual_views,
             'schema_contract_sha256':canonical_hash({'tables':actual,'views':actual_views})}
    if receipt['status']!='PASS':
        raise RuntimeError('Physical PostgreSQL schema does not match R19 table contract')
    return receipt

def database_payload_receipt(pg, db):
    table_map={
        'm2_11_candidate_profile_evaluation':'candidate_evaluation',
        'm2_11_application_strategy_simulation':'application_simulation',
        'm2_11_account_strategy_simulation':'account_simulation',
        'm2_11_portfolio_strategy_summary':'portfolio_summary',
        'm2_11_portfolio_strategy_frontier':'portfolio_frontier',
        'm2_11_portfolio_strategy_comparison':'portfolio_comparison',
    }
    objects=[]
    for table,identity_key in table_map.items():
        data=pg.copy_to_csv(db,f'SELECT row_hash FROM {SCHEMA}.{table} ORDER BY row_hash')
        hashes=[row['row_hash'] for row in csv.DictReader(io.StringIO(data.decode('utf-8')))]
        observed={'rows':len(hashes),'row_hash_root':canonical_hash(hashes)}
        expected=EXPECTED[identity_key]
        objects.append({'table':table,'identity_key':identity_key,'status':'PASS' if observed==expected else 'FAIL','observed':observed,'expected':expected})
    receipt={'status':'PASS' if all(x['status']=='PASS' for x in objects) else 'FAIL','objects':objects,'payload_identity_root_sha256':canonical_hash(objects)}
    if receipt['status']!='PASS':
        raise RuntimeError('Physical PostgreSQL payload identity does not match deterministic R19 simulation')
    return receipt


def load_rows(pg,db,sim):
    pg.script(db,DDL)
    schema_receipt=database_schema_receipt(pg,db)
    tables=[('m2_11_strategy_profile',profile_rows()),('m2_11_candidate_profile_evaluation',sim['candidate_evaluation']),('m2_11_application_strategy_simulation',sim['application_simulation']),('m2_11_account_strategy_simulation',sim['account_simulation']),('m2_11_portfolio_strategy_summary',sim['portfolio_summary']),('m2_11_portfolio_strategy_frontier',sim['portfolio_frontier']),('m2_11_portfolio_strategy_comparison',sim['portfolio_comparison'])]
    for t,rows in tables:
        cols=list(rows[0]); copy_csv_into(pg,db,f'{SCHEMA}.{t}',cols,rows_to_csv_bytes(rows,cols))
    schema_receipt['payload_identity']=database_payload_receipt(pg,db)
    return schema_receipt

def db_controls(pg,db,source_root):
    specs=[('R19_DB_PROFILE_ROWS','m2_11_strategy_profile',8),('R19_DB_CANDIDATE_EVALUATION_ROWS','m2_11_candidate_profile_evaluation',52152),('R19_DB_APPLICATION_SIMULATION_ROWS','m2_11_application_strategy_simulation',12000),('R19_DB_ACCOUNT_SIMULATION_ROWS','m2_11_account_strategy_simulation',1040),('R19_DB_PORTFOLIO_SUMMARY_ROWS','m2_11_portfolio_strategy_summary',24),('R19_DB_PORTFOLIO_FRONTIER_ROWS','m2_11_portfolio_strategy_frontier',24),('R19_DB_PORTFOLIO_COMPARISON_ROWS','m2_11_portfolio_strategy_comparison',21)]
    out=[]
    def add(cid,a,e):
        x={'control_id':cid,'control_scope':'DATABASE','status':'PASS' if a==e else 'FAIL','observed':a,'expected':e}; x['evidence_sha256']=canonical_hash(x);out.append(x)
    for cid,t,e in specs:add(cid,int(pg.scalar(db,f'SELECT count(*) FROM {SCHEMA}.{t};',read_only=True)),e)
    add('R19_DB_CANDIDATE_SOURCE_ROOT_EXACT',pg.scalar(db,f"SELECT count(DISTINCT source_root_sha256) || ':' || min(source_root_sha256) FROM {SCHEMA}.m2_11_candidate_profile_evaluation;",read_only=True),f'1:{source_root}')
    add('R19_DB_APPLICATION_SOURCE_ROOT_EXACT',pg.scalar(db,f"SELECT count(DISTINCT source_root_sha256) || ':' || min(source_root_sha256) FROM {SCHEMA}.m2_11_application_strategy_simulation;",read_only=True),f'1:{source_root}')
    add('R19_DB_ROW_HASH_UNIQUENESS_CANDIDATE',pg.scalar(db,f'SELECT count(*)-count(DISTINCT row_hash) FROM {SCHEMA}.m2_11_candidate_profile_evaluation;',read_only=True),'0')
    add('R19_DB_ROW_HASH_UNIQUENESS_APPLICATION',pg.scalar(db,f'SELECT count(*)-count(DISTINCT row_hash) FROM {SCHEMA}.m2_11_application_strategy_simulation;',read_only=True),'0')
    add('R19_DB_EARLY_INTERVENTION_INCREMENT',pg.scalar(db,f"SELECT coalesce(sum(incremental_servicing_burden_units),0)::text FROM {SCHEMA}.m2_11_account_strategy_simulation WHERE strategy_profile_code='EARLY_INTERVENTION';",read_only=True),'4.000000')
    add('R19_DB_ANALYTIC_ONLY_AUTHORITY',pg.scalar(db,f"SELECT count(*) FROM {SCHEMA}.m2_11_application_strategy_simulation WHERE simulation_authority_state='ANALYTIC_ONLY_NOT_PRODUCTION_AUTHORITY';",read_only=True),'12000')
    return out

def export_csv(pg,db,view,order):return pg.copy_to_csv(db,f'SELECT * FROM {SCHEMA}.{view} ORDER BY {order}')
def state(pg,db,source,sim,verification,source_root,outdir,schema_receipt):
    offline=eng.build_controls(verification,source,sim,eng.identity(sim),EXPECTED)
    dbc=db_controls(pg,db,source_root); controls=offline+dbc
    if len(controls)!=70 or any(c['status']!='PASS' for c in controls): raise RuntimeError('R19 certification controls failed')
    control_root=canonical_hash(sorted(c['evidence_sha256'] for c in controls))
    detail=[]
    for c in controls:detail.append({**c,'observed':json.dumps(c['observed'],sort_keys=True,separators=(',',':')) if isinstance(c['observed'],(dict,list)) else str(c['observed']),'expected':json.dumps(c['expected'],sort_keys=True,separators=(',',':')) if isinstance(c['expected'],(dict,list)) else str(c['expected']),'source_root_sha256':source_root,'simulation_bundle_sha256':EXPECTED['bundle_sha256']})
    cols=list(detail[0]); copy_csv_into(pg,db,f'{SCHEMA}.m2_12_g3v2_certification_detail',cols,rows_to_csv_bytes(detail,cols))
    views=[('v_p05_strategy_profile','strategy_profile_code',8),('v_p05_candidate_evaluation','module1_run_id,scenario_code,merchant_application_id,candidate_id,strategy_profile_code',52152),('v_p05_application_strategy_simulation','module1_run_id,scenario_code,merchant_application_id,strategy_profile_code',12000),('v_p06_account_strategy_simulation','module1_run_id,scenario_code,merchant_application_id,strategy_profile_code',1040),('v_p06_portfolio_strategy_analysis','reporting_scope_code,strategy_profile_code',24),('v_p06_g3v2_certification','control_id',70)]
    pbi=[]
    for name,order,expected_rows in views:
        data=export_csv(pg,db,name,order); rows=max(0,data.count(b'\n')-1)
        if rows!=expected_rows: raise RuntimeError(f'Power BI view row mismatch {name}: {rows}')
        (outdir/(name+'.csv')).write_bytes(data); pbi.append({'object_name':name,'rows':rows,'sha256':sha256_bytes(data),'order_by':order})
    pbi_root=canonical_hash(pbi)
    report_root=canonical_hash({'source_root_sha256':source_root,'simulation_bundle_sha256':EXPECTED['bundle_sha256'],'control_root_sha256':control_root,'power_bi_bundle_sha256':pbi_root})
    cert_id='G3V2_R26_'+report_root[:24].upper()
    master={'certification_id':cert_id,'certification_status':'PASS','control_count':70,'pass_count':70,'fail_count':0,'source_root_sha256':source_root,'simulation_bundle_sha256':EXPECTED['bundle_sha256'],'control_root_sha256':control_root,'power_bi_bundle_sha256':pbi_root,'report_root_sha256':report_root,'authority_state':'CANDIDATE_ONLY_PENDING_INDEPENDENT_AUDIT','audit_state':'DEFERRED','publication_state':'NOT_AUTHORIZED'}
    cols=list(master); copy_csv_into(pg,db,f'{SCHEMA}.m2_12_g3v2_certification_master',cols,rows_to_csv_bytes([master],cols))
    manifest=[]
    for x in pbi:manifest.append({'report_id':'PBI_'+x['object_name'].upper(),'report_type':'POWER_BI_CURATED_EXTRACT','object_name':x['object_name'],'grain':json.dumps(next(v['grain'] for v in CONTRACT['power_bi_views'] if v['name']==x['object_name']),separators=(',',':')),'row_count':x['rows'],'content_sha256':x['sha256'],'source_root_sha256':source_root})
    # deterministic G3 master and detail report identities
    detail_bytes=pg.copy_to_csv(db,f'SELECT * FROM {SCHEMA}.m2_12_g3v2_certification_detail ORDER BY control_id')
    master_bytes=pg.copy_to_csv(db,f'SELECT * FROM {SCHEMA}.m2_12_g3v2_certification_master ORDER BY certification_id')
    manifest += [
      {'report_id':'G3V2_CERTIFICATION_DETAIL','report_type':'G3V2_DETAIL','object_name':'m2_12_g3v2_certification_detail','grain':'control_id','row_count':70,'content_sha256':sha256_bytes(detail_bytes),'source_root_sha256':source_root},
      {'report_id':'G3V2_CERTIFICATION_MASTER','report_type':'G3V2_MASTER','object_name':'m2_12_g3v2_certification_master','grain':'certification_id','row_count':1,'content_sha256':sha256_bytes(master_bytes),'source_root_sha256':source_root},
    ]
    mcols=list(manifest[0]);copy_csv_into(pg,db,f'{SCHEMA}.m2_12_report_manifest',mcols,rows_to_csv_bytes(manifest,mcols))
    # physical deterministic identity
    exports={}
    table_orders={'m2_11_strategy_profile':'strategy_profile_code','m2_11_candidate_profile_evaluation':'module1_run_id,scenario_code,merchant_application_id,candidate_id,strategy_profile_code','m2_11_application_strategy_simulation':'module1_run_id,scenario_code,merchant_application_id,strategy_profile_code','m2_11_account_strategy_simulation':'module1_run_id,scenario_code,merchant_application_id,strategy_profile_code','m2_11_portfolio_strategy_summary':'reporting_scope_code,strategy_profile_code','m2_11_portfolio_strategy_frontier':'reporting_scope_code,strategy_profile_code','m2_11_portfolio_strategy_comparison':'reporting_scope_code,challenger_strategy_profile_code','m2_12_g3v2_certification_detail':'control_id','m2_12_g3v2_certification_master':'certification_id','m2_12_report_manifest':'report_id'}
    for t,o in table_orders.items():
        b=pg.copy_to_csv(db,f'SELECT * FROM {SCHEMA}.{t} ORDER BY {o}');exports[t]={'rows':max(0,b.count(b'\n')-1),'sha256':sha256_bytes(b)}
    identity={'simulation_identity':eng.identity(sim),'source_root_sha256':source_root,'database_schema_contract_sha256':schema_receipt['schema_contract_sha256'],'control_root_sha256':control_root,'power_bi_objects':pbi,'power_bi_bundle_sha256':pbi_root,'report_root_sha256':report_root,'master':master,'physical_exports':exports,'physical_export_root_sha256':canonical_hash(exports)}
    write_json(outdir/'STATE_IDENTITY.json',identity);write_json(outdir/'G3V2_CERTIFICATION_MASTER.json',master);write_json(outdir/'G3V2_CONTROLS.json',{'total':70,'pass':70,'fail':0,'controls':controls});write_json(outdir/'POWER_BI_P05_P06_IDENTITY.json',{'objects':pbi,'bundle_sha256':pbi_root})
    return identity

def compare(a,b):
    keys=['simulation_identity','source_root_sha256','database_schema_contract_sha256','control_root_sha256','power_bi_objects','power_bi_bundle_sha256','report_root_sha256','master','physical_exports','physical_export_root_sha256']; checks={k:a[k]==b[k] for k in keys};return {'status':'PASS' if all(checks.values()) else 'FAIL','checks':checks}

def result_zip(run_dir,out):
    with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for p in sorted(run_dir.rglob('*')):
            if p.is_file(): z.write(p,p.relative_to(run_dir).as_posix())
    sh=sha256_file(out); out.with_suffix(out.suffix+'.sha256').write_text(f'{sh}  {out.name}\n',encoding='ascii');return sh

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--immutable-r6-db',default='msbf_r1_m2_4_r6_20260830_030634');ap.add_argument('--r12-diagnostic-db',default='msbf_r1_wave_a_r12_compile_20260830_165946');ap.add_argument('--r13-diagnostic-db',default='msbf_r1_wave_a_r13_compile_20260830_190007');ap.add_argument('--r14-diagnostic-db',default='msbf_r1_wave_a_r14_compile_20260830_195709');ap.add_argument('--r16-diagnostic-db',default='msbf_r1_wave_a_r16_compile_20260830_231947');ap.add_argument('--r17-diagnostic-db',default='msbf_r1_wave_a_r17_20260831_061333');ap.add_argument('--pg-bin',required=True);ap.add_argument('--host',default='localhost');ap.add_argument('--port',type=int,default=5432);ap.add_argument('--user',default='postgres');a=ap.parse_args()
    stamp=nowstamp();compiler=f'msbf_r1_wave_b_r19_compile_{stamp}';final=f'msbf_r1_wave_b_r19_g3v2_{stamp}';rr=ROOT/'results';rr.mkdir(exist_ok=True);work=rr/f'msbf_r1_wave_b_r19_{stamp}_WORK';work.mkdir();ev=work/'evidence';ev.mkdir();(work/'logs').mkdir();scratch=work/'scratch';scratch.mkdir()
    receipt={'runtime_id':BUILD_ID,'status':'RUNNING','started_at_utc':utcnow(),'last_stage':'INITIALIZE','immutable_r6_database':a.immutable_r6_db,'compiler_database':compiler,'final_database':final,'compiler_retained':False,'final_retained':False,'source_modified':None,'diagnostic_presence':{},'failure':None}
    logp=work/'logs'/'WAVE_B_R19.log';origout,origerr=sys.stdout,sys.stderr
    class Tee:
        def __init__(self,*f):self.f=f
        def write(self,s):
            for x in self.f:x.write(s);x.flush()
        def flush(self):
            for x in self.f:x.flush()
    pg=None;fps={}
    with logp.open('w',encoding='utf-8',newline='\n') as lf:
      sys.stdout=Tee(origout,lf);sys.stderr=Tee(origerr,lf)
      try:
        print(BUILD_ID+' starting',flush=True);receipt['last_stage']='PACKAGED_EVIDENCE_VERIFICATION_AND_OFFLINE_REPLAY'
        ver=eng.verify_inputs(str(R4),str(R17),str(R18));source=eng.load_source_rows(str(R4),str(R17));source_root=eng.build_source_root(ver);sim=eng.build_simulation(source,source_root);sid=eng.identity(sim)
        if sid!=EXPECTED:raise RuntimeError('Offline deterministic simulation identity mismatch')
        off=eng.build_controls(ver,source,sim,sid,EXPECTED)
        if len(off)!=57 or any(x['status']!='PASS' for x in off):raise RuntimeError('Offline pre-database controls failed')
        ddl_controls=schema_contract.ddl_contract_controls(DDL,TABLE_CONTRACT)
        payload_controls=schema_contract.simulation_payload_controls(sim,PROFILE,TABLE_CONTRACT)
        contract_controls=ddl_controls+payload_controls
        if not schema_contract.all_pass(contract_controls):
            raise RuntimeError('R19 physical schema/payload contract preflight failed')
        runtime_files=['RUN_WAVE_B_R19.ps1','src/r19_engine.py','src/common.py','src/schema_contract.py','src/r19_self_test.py','src/validate_package.py','src/wave_b_runtime_r19.py','src/R19_M2_11_M2_12_G3V2_DDL.sql','config/R19_RUNTIME_CONTRACT.json','config/R19_EXPECTED_SIMULATION_IDENTITY.json','config/R19_STRATEGY_PROFILE_CONTRACT.json','config/R19_TABLE_CONTRACT.json','repository_overlay/.github/workflows/publication_integrity.yml','repository_overlay/RESTORE_PUBLICATION_INTEGRITY.py','repository_overlay/RESTORE_PUBLICATION_INTEGRITY.ps1']
        runtime_hashes={rel:sha256_file(ROOT/rel) for rel in runtime_files}
        runtime_source_root=canonical_hash(runtime_hashes)
        write_json(ev/'00_RUNTIME_SOURCE_BINDING.json',{'package_manifest_sha256':sha256_file(ROOT/'PACKAGE_MANIFEST.csv'),'runtime_files':runtime_hashes,'runtime_source_root_sha256':runtime_source_root})
        write_json(ev/'01_PACKAGED_EVIDENCE_AND_OFFLINE_REPLAY.json',{'verification':ver,'source_root_sha256':source_root,'simulation_identity':sid,'controls':{'total':57,'pass':57,'fail':0},'physical_contract_controls':{'total':len(contract_controls),'pass':len(contract_controls),'fail':0}})
        tools=PgTools.from_bin(Path(a.pg_bin));env=os.environ.copy();
        if not env.get('PGPASSWORD'):raise RuntimeError('PGPASSWORD not set by launcher')
        pg=PgContext(tools,a.host,a.port,a.user,env)
        receipt['last_stage']='IMMUTABLE_R6_AND_OPTIONAL_DIAGNOSTIC_PREFLIGHT'
        if not pg.db_exists(a.immutable_r6_db):raise RuntimeError(f'Required immutable R6 carrier database not found: {a.immutable_r6_db}')
        r6_schema_before=db_schema_fp(pg,a.immutable_r6_db,scratch)
        r6_control_before=r6_control_snapshot(pg,a.immutable_r6_db)
        r6_before={'schema':r6_schema_before,'source_control':r6_control_before,'source_control_sha256':canonical_hash(r6_control_before)}
        fps[a.immutable_r6_db]=r6_before
        for db in [a.r12_diagnostic_db,a.r13_diagnostic_db,a.r14_diagnostic_db,a.r16_diagnostic_db,a.r17_diagnostic_db]:
            present=pg.db_exists(db);receipt['diagnostic_presence'][db]=present
            if present:fps[db]={'schema':db_schema_fp(pg,db,scratch)}
        write_json(ev/'02_DATABASE_PREFLIGHT.json',{'immutable_r6':{'database':a.immutable_r6_db,**r6_before},'optional_diagnostics':receipt['diagnostic_presence'],'optional_diagnostic_fingerprints':{db:fps[db] for db in receipt['diagnostic_presence'] if receipt['diagnostic_presence'][db]},'authority_note':'R17 database is optional diagnostic only; exact R4/R17 packaged evidence governs business facts. Immutable R6 is validated and used only as the fresh PostgreSQL carrier.'})
        receipt['last_stage']='COMPILER_FULL_PATH'; clone=pg.clone_database(a.immutable_r6_db,compiler,scratch);receipt['compiler_retained']=True;write_json(ev/'03_COMPILER_CLONE.json',clone)
        cdir=ev/'compiler';cdir.mkdir();c_schema=load_rows(pg,compiler,sim);write_json(cdir/'DATABASE_SCHEMA_CONTRACT.json',c_schema);ci=state(pg,compiler,source,sim,ver,source_root,cdir,c_schema)
        receipt['last_stage']='COMPILER_PASS_DROP';pg.drop_database(compiler);receipt['compiler_retained']=False
        receipt['last_stage']='FINAL_FRESH_REPERFORMANCE';clone2=pg.clone_database(a.immutable_r6_db,final,scratch);receipt['final_retained']=True;write_json(ev/'04_FINAL_CLONE.json',clone2)
        fdir=ev/'final';fdir.mkdir();f_schema=load_rows(pg,final,sim);write_json(fdir/'DATABASE_SCHEMA_CONTRACT.json',f_schema);fi=state(pg,final,source,sim,ver,source_root,fdir,f_schema)
        comp=compare(ci,fi);write_json(ev/'05_COMPILER_FINAL_EXACT_IDENTITY.json',comp)
        if comp['status']!='PASS':raise RuntimeError('R19 compiler/final exact identity mismatch')
        receipt['last_stage']='SOURCE_AND_OPTIONAL_DIAGNOSTIC_NONMUTATION'
        after={}
        r6_schema_after=db_schema_fp(pg,a.immutable_r6_db,scratch)
        r6_control_after=r6_control_snapshot(pg,a.immutable_r6_db)
        after[a.immutable_r6_db]={'schema':r6_schema_after,'source_control':r6_control_after,'source_control_sha256':canonical_hash(r6_control_after)}
        checks={
            'R6_NORMALIZED_SCHEMA_EXACT':schema_fp_equal(fps[a.immutable_r6_db]['schema'],r6_schema_after),
            'R6_SOURCE_CONTROL_EXACT':fps[a.immutable_r6_db]['source_control_sha256']==after[a.immutable_r6_db]['source_control_sha256'],
        }
        for db,present in receipt['diagnostic_presence'].items():
            if present:
                if not pg.db_exists(db):raise RuntimeError(f'Optional diagnostic disappeared during R19: {db}')
                after[db]={'schema':db_schema_fp(pg,db,scratch)}
                checks[f'{db}_NORMALIZED_SCHEMA_EXACT']=schema_fp_equal(fps[db]['schema'],after[db]['schema'])
        write_json(ev/'06_NONMUTATION.json',{'status':'PASS' if all(checks.values()) else 'FAIL','checks':checks,'before':fps,'after':after})
        receipt['source_modified']=not (checks['R6_NORMALIZED_SCHEMA_EXACT'] and checks['R6_SOURCE_CONTROL_EXACT'])
        if not all(checks.values()):raise RuntimeError('R6 or retained optional diagnostic fingerprint changed')
        receipt.update({'status':'PASS','last_stage':'COMPLETE','completed_at_utc':utcnow(),'source_modified':False,'compiler_retained':False,'final_retained':True,'source_root_sha256':source_root,'simulation_bundle_sha256':EXPECTED['bundle_sha256'],'g3v2_certification_id':fi['master']['certification_id'],'g3v2_status':'PASS','certification_controls':{'total':70,'pass':70,'fail':0},'candidate_evaluations':52152,'application_simulations':12000,'account_simulations':1040,'authority_state':'CANDIDATE_ONLY_PENDING_INDEPENDENT_AUDIT','audit_state':'DEFERRED','publication_state':'NOT_AUTHORIZED','runtime_source_root_sha256':runtime_source_root,'package_manifest_sha256':sha256_file(ROOT/'PACKAGE_MANIFEST.csv'),'physical_contract_controls':len(contract_controls)})
      except Exception as ex:
        receipt.update({'status':'FAIL','completed_at_utc':utcnow(),'failure':repr(ex),'traceback':traceback.format_exc()})
        if pg and a.immutable_r6_db in fps:
            try:
                failure_schema=db_schema_fp(pg,a.immutable_r6_db,scratch)
                failure_control=r6_control_snapshot(pg,a.immutable_r6_db)
                failure_checks={
                    'R6_NORMALIZED_SCHEMA_EXACT':schema_fp_equal(fps[a.immutable_r6_db]['schema'],failure_schema),
                    'R6_SOURCE_CONTROL_EXACT':fps[a.immutable_r6_db]['source_control_sha256']==canonical_hash(failure_control),
                }
                receipt['source_modified']=not all(failure_checks.values())
                write_json(ev/'99_FAILURE_NONMUTATION_PROBE.json',{'status':'PASS' if all(failure_checks.values()) else 'FAIL','checks':failure_checks,'after_schema':failure_schema,'after_source_control_sha256':canonical_hash(failure_control)})
            except Exception as probe_ex:
                receipt['source_modified']=None
                receipt['failure_nonmutation_probe_error']=repr(probe_ex)
        else:
            receipt['source_modified']=None
        print('FAILURE: '+repr(ex),flush=True);traceback.print_exc()
      finally:
        if pg:
            try:receipt['compiler_retained']=pg.db_exists(compiler)
            except:pass
            try:receipt['final_retained']=pg.db_exists(final)
            except:pass
        write_json(work/'WAVE_B_R19_RECEIPT.json',receipt);shutil.rmtree(scratch,ignore_errors=True);sys.stdout,sys.stderr=origout,origerr
    out=rr/f'msbf_r1_wave_b_r19_{stamp}_M2_11_M2_12_G3V2_RESULTS.zip';sh=result_zip(work,out)
    print(f'Wave B R19 M2.11-M2.12/G3-v2 finished: {receipt["status"]}');print(f'R6 source modified: {receipt.get("source_modified")}');print(f'Compiler clone retained: {receipt.get("compiler_database") if receipt.get("compiler_retained") else "NO"}');print(f'Final clone retained: {receipt.get("final_database") if receipt.get("final_retained") else "NO"}');print(f'Last stage: {receipt.get("last_stage")}');print(f'Results: {out}');print(f'SHA-256: {sh}')
    if receipt['status']!='PASS':print(f'Failure: {receipt.get("failure")}');return 1
    return 0
if __name__=='__main__':raise SystemExit(main())
