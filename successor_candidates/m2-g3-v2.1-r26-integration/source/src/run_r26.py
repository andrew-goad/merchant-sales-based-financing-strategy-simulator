#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv,getpass,hashlib,io,json,os,re,shutil,sys,traceback,zipfile
from pathlib import Path
from datetime import datetime,timezone

import wave_a_engine_r17 as wave
import r26_policy
import r19_engine as eng
import wave_b_engine_r19 as waveb
import schema_contract
from common import PgTools,PgContext,canonical_hash,sha256_bytes,sha256_file,normalize_pg_dump_schema_bytes,write_json,run

ROOT=Path(__file__).resolve().parents[1]
R4=ROOT/'inputs'/'PHASE2C_R4_STRATEGY.zip'
R19_DDL=(ROOT/'src'/'R19_M2_11_M2_12_G3V2_DDL.sql').read_text(encoding='utf-8').replace('msbf_r1_g3v2_r19','msbf_r1_g3v2_r26')
BUILD_ID='MSBF_M1M2_R26_M2_5_M2_12_MONITORING_CALIBRATION_RECERTIFICATION'


def utcnow(): return datetime.now(timezone.utc).isoformat()
def stamp(): return datetime.now().strftime('%Y%m%d_%H%M%S')
def canon(x): return json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=True)
def hobj(x): return hashlib.sha256(canon(x).encode()).hexdigest()

def deterministic_zip(src:Path,out:Path):
    epoch=(1980,1,1,0,0,0)
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9,allowZip64=True) as z:
        for p in sorted(src.rglob('*'),key=lambda x:x.relative_to(src).as_posix()):
            if not p.is_file(): continue
            rel=p.relative_to(src).as_posix(); zi=zipfile.ZipInfo(rel,epoch);zi.compress_type=zipfile.ZIP_DEFLATED
            zi.external_attr=(0o100644 & 0xFFFF)<<16
            z.writestr(zi,p.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    return sha256_file(out)

def schema_fp(pg:PgContext,db:str,scratch:Path):
    p=scratch/f'{db}.schema.sql'
    run([str(pg.tools.pg_dump),'-h',pg.host,'-p',str(pg.port),'-U',pg.user,'-d',db,'--schema-only','--no-owner','--no-privileges','-f',str(p)],env=pg.env)
    raw=p.read_bytes();norm=normalize_pg_dump_schema_bytes(raw);p.unlink(missing_ok=True)
    return {'normalized_schema_sha256':sha256_bytes(norm),'raw_schema_sha256_observational':sha256_bytes(raw),'normalized_bytes':len(norm),'raw_bytes':len(raw)}

def patch_wave_engine():
    original_transform=wave.transform
    original_overlay=wave.strategy.overlay_payload
    def transform(stage,src_class,txt,prior_hash):
        out=original_transform(stage,src_class,txt,prior_hash)
        if stage=='5':
            out=r26_policy.patch_schema(out) if src_class=='SCHEMA' else r26_policy.patch_generation(out)
        return out
    def overlay(stage):
        return r26_policy.overlay_payload(stage,original_overlay(stage))
    wave.transform=transform
    wave.strategy.overlay_payload=overlay
    return original_transform

def static_preflight(original_transform):
    rows=[];placeholder='0123456789abcdef0123456789abcdef'
    for stage in wave.STAGES:
        m=wave.META[stage];srcs={r['source_class']:r for r in wave.SRC_MAN if r['stage']==m['stage']}
        for cls in ['SCHEMA','GEN']:
            raw=(ROOT/srcs[cls]['package_path']).read_text(encoding='utf-8')
            base=original_transform(stage,cls,raw,placeholder)
            out=(r26_policy.patch_schema(base) if (stage=='5' and cls=='SCHEMA') else
                 r26_policy.patch_generation(base) if (stage=='5' and cls=='GEN') else base)
            wave.core.lexical_sql_check(out)
            rows.append({'stage':m['stage'],'source_class':cls,'status':'PASS','sha256':hashlib.sha256(out.encode()).hexdigest(),'bytes':len(out.encode())})
            if stage=='5' and cls=='SCHEMA': r26_schema=out
            if stage=='5' and cls=='GEN': r26_gen=out
    policy_checks=r26_policy.static_checks(r26_schema,r26_gen)
    if any(x['status']!='PASS' for x in policy_checks): raise RuntimeError('R26 policy static controls failed')
    return {'status':'PASS','transforms':rows,'policy_controls':policy_checks}

def r26_controls(pg:PgContext,db:str):
    controls=[]
    def scalar(sql): return pg.scalar(db,sql,read_only=True)
    def add(cid,actual,expected):
        ok=(str(actual)==str(expected));controls.append({'control_id':cid,'status':'PASS' if ok else 'FAIL','observed':actual,'expected':expected});return ok
    add('R26_POLICY_OVERLAY_ROWS',scalar("SELECT count(*) FROM msbf_m12r1e.r26_m2_5_policy_overlay"),1)
    add('R26_POLICY_SHA256_EXACT',scalar("SELECT policy_sha256 FROM msbf_m12r1e.r26_m2_5_policy_overlay"),r26_policy.POLICY_SHA256)
    add('R26_POLICY_PARAMETER_EXACT',scalar("SELECT watch_start_day||'|'||underperforming_start_day||'|'||severe_start_day FROM msbf_ctl.m2_5_policy_profile"),'21|30|30')
    add('R26_OPERATIONAL_FAMILY_ROWS',scalar("SELECT count(*) FROM msbf_m2.monitoring_operational_alert_family_daily"),15600)
    add('R26_OPERATIONAL_FAMILY_KEY_UNIQUE',scalar("SELECT count(*)-count(DISTINCT (module1_run_id,scenario_id,merchant_application_id,monitoring_day_index)) FROM msbf_m2.monitoring_operational_alert_family_daily"),0)
    add('R26_OPERATIONAL_FAMILY_POLICY_EXACT',scalar("SELECT count(*) FROM msbf_m2.monitoring_operational_alert_family_daily WHERE policy_sha256<>'"+r26_policy.POLICY_SHA256+"'"),0)
    add('R26_RAW_COUNT_RECONCILES',scalar("""SELECT count(*) FROM msbf_m2.monitoring_operational_alert_family_daily o JOIN msbf_m2.advance_daily_remittance_monitoring d USING(module1_run_id,scenario_id,merchant_application_id,monitoring_day_index) WHERE o.raw_alert_condition_count<>(d.daily_shortfall_alert_flag::int+d.cumulative_pace_watch_alert_flag::int+d.cumulative_pace_high_alert_flag::int+d.zero_sales_streak_alert_flag::int+d.liquidity_stress_alert_flag::int+d.horizon_overrun_alert_flag::int)"""),0)
    add('R26_PACE_FAMILY_NOT_BEFORE_DAY23',scalar("SELECT count(*) FROM msbf_m2.monitoring_operational_alert_family_daily WHERE pace_family_active_flag AND monitoring_day_index<23"),0)
    add('R26_PACE_ONLY_ADVERSE_NOT_BEFORE_DAY32',scalar("""SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring d WHERE d.monitoring_day_index<32 AND d.raw_monitoring_status_code IN ('UNDERPERFORMING','SEVERE_SHORTFALL') AND d.days_since_last_positive_remittance<7 AND d.zero_sales_streak_days<10 AND NOT d.liquidity_stress_alert_flag AND NOT d.horizon_overrun_alert_flag"""),0)
    add('R26_EXPECTED_DAILY_HORIZON_BASIS',scalar("""SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring d JOIN msbf_m2.advance_monitoring_source_snapshot s USING(module1_run_id,scenario_id,merchant_application_id) WHERE d.expected_daily_remittance_amount IS DISTINCT FROM round(s.total_repayment_amount/nullif(s.collection_horizon_days,0),2)::numeric(18,2)"""),0)
    checkpoints={
      ('BASELINE',14):(100,12,11),('BASELINE',23):(90,29,11),('BASELINE',30):(82,30,0),('BASELINE',32):(80,30,19),('RECESSION_ENERGY',14):(25,2,2)
    }
    for (sc,day),exp in checkpoints.items():
        raw=scalar(f"""SELECT (count(*) FILTER(WHERE NOT d.paid_off_flag))||'|'||(count(*) FILTER(WHERE NOT d.paid_off_flag AND o.operational_alert_family_count>0))||'|'||(count(*) FILTER(WHERE NOT d.paid_off_flag AND d.monitoring_status_code IN ('UNDERPERFORMING','SEVERE_SHORTFALL','DORMANT_NO_REMITTANCE'))) FROM msbf_m2.advance_daily_remittance_monitoring d JOIN msbf_m2.monitoring_operational_alert_family_daily o USING(module1_run_id,scenario_id,merchant_application_id,monitoring_day_index) WHERE d.scenario_code='{sc}' AND d.monitoring_day_index={day}""")
        add(f'R26_CHECKPOINT_{sc}_{day}',raw,'|'.join(map(str,exp)))
    add('R26_M2_6_ENDPOINT_OUTCOME_DISTRIBUTION',scalar("""SELECT string_agg(strategy_outcome_code||':'||n,',' ORDER BY strategy_outcome_code) FROM (SELECT strategy_outcome_code,count(*) n FROM msbf_m2.advance_intervention_strategy_latest GROUP BY strategy_outcome_code) x"""),'CLOSED_NO_FURTHER_ACTION:126,TARGETED_MERCHANT_OUTREACH_REVIEW:3,TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW:1')
    add('R26_M2_6_REVIEW_ROWS',scalar("SELECT count(*) FROM msbf_m2.advance_intervention_strategy_latest WHERE review_required_flag"),4)
    if any(x['status']!='PASS' for x in controls):
        raise RuntimeError('R26 physical controls failed: '+json.dumps([x for x in controls if x['status']=='FAIL'],separators=(',',':')))
    return controls

def export_wave_a_csvs(pg:PgContext,db:str,outdir:Path):
    specs={
      'stage_registry':('msbf_m12r1e.wave_a_stage_registry','stage_code'),
      'validation':('msbf_m12r1e.wave_a_validation_result','stage_code,control_id'),
      'm2_5':('msbf_m2.v_m2_5_power_bi_daily_monitoring','module1_run_id,scenario_code,merchant_application_id,monitoring_day_index'),
      'm2_5_r26':('msbf_m2.v_m2_5_power_bi_daily_monitoring_r26','module1_run_id,scenario_code,merchant_application_id,monitoring_day_index'),
      'm2_6':('msbf_m2.v_m2_6_power_bi_intervention_strategy','module1_run_id,scenario_code,merchant_application_id'),
      'm2_7':('msbf_m2.v_m2_7_power_bi_operational_setup','module1_run_id,scenario_code,merchant_application_id'),
      'm2_8':('msbf_m2.v_m2_8_power_bi_servicing_execution','module1_run_id,scenario_code,merchant_application_id'),
      'm2_9':('msbf_m2.v_m2_9_power_bi_account_certification','module1_run_id,scenario_code,merchant_application_id'),
      'm2_10':('msbf_m2.v_m2_10_power_bi_portfolio_analytics','module1_run_id,scenario_code,merchant_application_id'),
    }
    out={};outdir.mkdir(parents=True,exist_ok=True)
    for name,(obj,order) in specs.items():
        b=pg.copy_to_csv(db,f'SELECT * FROM {obj} ORDER BY {order}')
        p=outdir/f'{name}.csv';p.write_bytes(b);rows=sum(1 for _ in csv.reader(io.StringIO(b.decode('utf-8-sig'))))-1
        out[name]={'object':obj,'rows':rows,'sha256':sha256_bytes(b),'file':p.name}
    return out

R26_WAVE_A_SEMANTIC_CANON_VERSION='R26_WAVE_A_SEMANTIC_CANON_V1'
R26_VOLATILE_TIME_KEYS={'created_at','updated_at','generated_at','validated_at','accepted_at','archived_at','captured_at','evaluated_at'}


def _drop_volatile_time_keys(value):
    if isinstance(value,dict):
        return {k:_drop_volatile_time_keys(v) for k,v in value.items() if k not in R26_VOLATILE_TIME_KEYS}
    if isinstance(value,list):
        return [_drop_volatile_time_keys(v) for v in value]
    return value


def canonical_stage_registry_rows(data:bytes):
    rows=eng.csv_rows(data);out=[]
    for row in rows:
        r=dict(row)
        r.pop('validated_at',None)
        authority=r.get('contract_authority','')
        r['contract_authority']=re.sub(r'_(COMPILER|FINAL)$','_CANONICAL',authority)
        payload=r.get('legacy_registry_payload','')
        if payload:
            parsed=json.loads(payload)
            r['legacy_registry_payload']=json.dumps(_drop_volatile_time_keys(parsed),sort_keys=True,separators=(',',':'),ensure_ascii=False)
        out.append(r)
    return sorted(out,key=lambda r:r.get('stage_code',''))


def canonical_validation_rows(data:bytes):
    rows=eng.csv_rows(data);out=[]
    for row in rows:
        r=dict(row);r.pop('evaluated_at',None);out.append(r)
    return sorted(out,key=lambda r:(r.get('stage_code',''),r.get('control_id','')))


def wave_a_semantic_payload(wave_exports:dict,wave_dir:Path):
    stage_raw=(wave_dir/'stage_registry.csv').read_bytes()
    validation_raw=(wave_dir/'validation.csv').read_bytes()
    m27_raw=(wave_dir/'m2_7.csv').read_bytes()
    m210_raw=(wave_dir/'m2_10.csv').read_bytes()
    stage_rows=canonical_stage_registry_rows(stage_raw)
    validation_rows=canonical_validation_rows(validation_raw)
    m27_rows=eng.csv_rows(m27_raw);m210_rows=eng.csv_rows(m210_raw)
    members={
      'stage_registry':{'rows':len(stage_rows),'semantic_sha256':canonical_hash(stage_rows)},
      'validation':{'rows':len(validation_rows),'semantic_sha256':canonical_hash(validation_rows)},
      'm2_7':{'rows':len(m27_rows),'sha256':sha256_bytes(m27_raw)},
      'm2_10':{'rows':len(m210_rows),'sha256':sha256_bytes(m210_raw)},
    }
    raw_observational={k:{'rows':wave_exports[k]['rows'],'sha256':wave_exports[k]['sha256']} for k in ['stage_registry','validation','m2_7','m2_10']}
    return {
      'canonicalization_version':R26_WAVE_A_SEMANTIC_CANON_VERSION,
      'stage_registry_rows':stage_rows,'validation_rows':validation_rows,
      'm2_7_rows':m27_rows,'m2_10_rows':m210_rows,
      'members':members,'raw_observational':raw_observational,
      'semantic_bundle_sha256':canonical_hash({'policy_sha256':r26_policy.POLICY_SHA256,'members':members,'stage':'M2.5-M2.10','canonicalization_version':R26_WAVE_A_SEMANTIC_CANON_VERSION})
    }


def r2_failure_reperformance():
    result=ROOT/'inputs'/'msbf_r1_r26_20260902_024119_M2_5_M2_12_G3V2_RESULTS.zip'
    expected='f140d5f51d464b379dc218902f1b61844914a86207665b4ff0699aab8bbe4329'
    if not result.is_file() or sha256_file(result)!=expected:
        raise RuntimeError('R26 R2 failure evidence identity mismatch')
    with zipfile.ZipFile(result) as z:
        phase={}
        for name in ['stage_registry','validation','m2_7','m2_10']:
            phase[('compiler',name)]=z.read(f'evidence/compiler/wave_a_exports/{name}.csv')
            phase[('final',name)]=z.read(f'evidence/final/wave_a_exports/{name}.csv')
    raw={'stage_registry_equal':phase[('compiler','stage_registry')]==phase[('final','stage_registry')],
         'validation_equal':phase[('compiler','validation')]==phase[('final','validation')],
         'm2_7_equal':phase[('compiler','m2_7')]==phase[('final','m2_7')],
         'm2_10_equal':phase[('compiler','m2_10')]==phase[('final','m2_10')]}
    cstage=canonical_stage_registry_rows(phase[('compiler','stage_registry')]);fstage=canonical_stage_registry_rows(phase[('final','stage_registry')])
    cval=canonical_validation_rows(phase[('compiler','validation')]);fval=canonical_validation_rows(phase[('final','validation')])
    semantic={'stage_registry_equal':cstage==fstage,'validation_equal':cval==fval,
              'stage_registry_sha256':canonical_hash(cstage),'validation_sha256':canonical_hash(cval)}
    source_base,_=r4_source_rows()
    def one(which):
        source=dict(source_base)
        source['r17_stage_registry']=canonical_stage_registry_rows(phase[(which,'stage_registry')])
        source['r17_validation']=canonical_validation_rows(phase[(which,'validation')])
        source['r17_m2_7']=eng.csv_rows(phase[(which,'m2_7')]);source['r17_m2_10']=eng.csv_rows(phase[(which,'m2_10')])
        members={'stage_registry':{'rows':len(source['r17_stage_registry']),'semantic_sha256':canonical_hash(source['r17_stage_registry'])},
                 'validation':{'rows':len(source['r17_validation']),'semantic_sha256':canonical_hash(source['r17_validation'])},
                 'm2_7':{'rows':len(source['r17_m2_7']),'sha256':sha256_bytes(phase[(which,'m2_7')])},
                 'm2_10':{'rows':len(source['r17_m2_10']),'sha256':sha256_bytes(phase[(which,'m2_10')])}}
        wave_sha=canonical_hash({'policy_sha256':r26_policy.POLICY_SHA256,'members':members,'stage':'M2.5-M2.10','canonicalization_version':R26_WAVE_A_SEMANTIC_CANON_VERSION})
        source_root=canonical_hash({'r4_sha256':sha256_file(R4),'r26_wave_a_sha256':wave_sha,'r26_policy_sha256':r26_policy.POLICY_SHA256,'wave_members':members})
        ident=eng.identity(eng.build_simulation(source,source_root))
        return {'wave_a_semantic_sha256':wave_sha,'source_root_sha256':source_root,'simulation_identity':ident}
    c=one('compiler');f=one('final')
    status=(not raw['stage_registry_equal'] and not raw['validation_equal'] and raw['m2_7_equal'] and raw['m2_10_equal'] and semantic['stage_registry_equal'] and semantic['validation_equal'] and c==f)
    return {'status':'PASS' if status else 'FAIL','r2_result_sha256':expected,'raw_identity':raw,'semantic_identity':semantic,
            'compiler':c,'final':f,'diagnosis':'R2 raw Wave A evidence fed volatile timestamps and compiler/final role labels into the M2.11 source root; business outputs were exact.'}


def r4_source_rows():
    if sha256_file(R4)!=eng.EXPECTED_R4_SHA: raise RuntimeError('R4 evidence carrier SHA mismatch')
    out={};members={}
    with zipfile.ZipFile(R4) as z:
      for role,name in eng.R4_MEMBER.items():
        b=z.read(name);rows=eng.csv_rows(b);members[role]={'member':name,'rows':len(rows),'sha256':sha256_bytes(b),'bytes':len(b)}
        if len(rows)!=eng.EXPECTED_R4_ROWS[role] or sha256_bytes(b)!=eng.EXPECTED_R4_MEMBER_SHA[role]: raise RuntimeError('R4 member mismatch '+role)
        if role not in {'gate','feature'}: out['r4_'+role]=rows
    return out,members

def build_g3(pg:PgContext,db:str,wave_exports:dict,wave_dir:Path,outdir:Path,expected_sim=None):
    source,r4_members=r4_source_rows()
    semantic=wave_a_semantic_payload(wave_exports,wave_dir)
    source['r17_stage_registry']=semantic['stage_registry_rows']
    source['r17_validation']=semantic['validation_rows']
    source['r17_m2_7']=semantic['m2_7_rows']
    source['r17_m2_10']=semantic['m2_10_rows']
    wave_sha=semantic['semantic_bundle_sha256']
    verification={
      'r4':{'sha256':sha256_file(R4),'members':r4_members,'policy_profile_sha256':eng.EXPECTED_OWNER_PROFILE_SHA,'accepted_method_source_set_sha256':eng.EXPECTED_METHOD_SOURCE_SET_SHA},
      'r17':{'sha256':wave_sha,'members':semantic['members'],'raw_observational':semantic['raw_observational'],'canonicalization_version':R26_WAVE_A_SEMANTIC_CANON_VERSION},
      'r18_failure':{'sha256':'R26_NOT_APPLICABLE','compiler_created':False,'final_created':False}
    }
    source_root=canonical_hash({'r4_sha256':sha256_file(R4),'r26_wave_a_sha256':wave_sha,'r26_policy_sha256':r26_policy.POLICY_SHA256,'wave_members':semantic['members']})
    sim=eng.build_simulation(source,source_root);simid=eng.identity(sim)
    if expected_sim is not None and simid!=expected_sim: raise RuntimeError('R26 M2.11 compiler/final simulation identity mismatch')
    # Rebind R19 control machinery to the exact R26 Wave A evidence while preserving the accepted eight-profile method.
    eng.EXPECTED_R17_SHA=wave_sha;eng.EXPECTED_R17_ROWS={'stage_registry':6,'validation':len(source['r17_validation']),'m2_7':130,'m2_10':130}
    eng.EXPECTED_R17_MEMBER_SHA={'m2_7':wave_exports['m2_7']['sha256'],'m2_10':wave_exports['m2_10']['sha256']};eng.EXPECTED_R18_FAIL_SHA='R26_NOT_APPLICABLE'
    orig_bc=eng.build_controls
    def bc(ver,src,sm,ident,exp=None):
        rows=orig_bc(ver,src,sm,ident,exp)
        for r in rows:
            r['control_id']=r['control_id'].replace('R19_','R26_')
            if r.get('observed')=='PACKAGED_R4_AND_R17_EVIDENCE': r['observed']='PACKAGED_R4_AND_R26_WAVE_A_EVIDENCE'
            if r.get('expected')=='PACKAGED_R4_AND_R17_EVIDENCE': r['expected']='PACKAGED_R4_AND_R26_WAVE_A_EVIDENCE'
            r['evidence_sha256']=eng.canon_hash({k:v for k,v in r.items() if k!='evidence_sha256'})
        return rows
    eng.build_controls=bc
    orig_db=waveb.db_controls
    def dbc(pgctx,database,sroot):
        rows=orig_db(pgctx,database,sroot)
        for r in rows:
            r['control_id']=r['control_id'].replace('R19_','R26_');r['evidence_sha256']=eng.canon_hash({k:v for k,v in r.items() if k!='evidence_sha256'})
        return rows
    waveb.db_controls=dbc
    waveb.SCHEMA='msbf_r1_g3v2_r26';waveb.DDL=R19_DDL;waveb.EXPECTED=simid
    outdir.mkdir(parents=True,exist_ok=True)
    schema_receipt=waveb.load_rows(pg,db,sim);write_json(outdir/'DATABASE_SCHEMA_CONTRACT.json',schema_receipt)
    ident=waveb.state(pg,db,source,sim,verification,source_root,outdir,schema_receipt)
    eng.build_controls=orig_bc;waveb.db_controls=orig_db
    return {'identity':ident,'simulation_identity':simid,'source_root_sha256':source_root,'wave_a_bundle_sha256':wave_sha,'wave_a_semantic_identity':{'canonicalization_version':R26_WAVE_A_SEMANTIC_CANON_VERSION,'members':semantic['members'],'semantic_bundle_sha256':wave_sha},'wave_a_raw_observational':semantic['raw_observational']}

def combined_identity(wave_result,wave_db_identity,r26_ctrl,g3):
    return {'wave_a_normalized':wave.normalized_result(wave_result),'wave_a_database_identity':wave_db_identity,
            'r26_policy_sha256':r26_policy.POLICY_SHA256,'r26_controls':r26_ctrl,
            'g3_identity':g3['identity'],'g3_simulation_identity':g3['simulation_identity'],'g3_source_root_sha256':g3['source_root_sha256']}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source-db',default='msbf_r1_m2_4_r6_20260830_030634');ap.add_argument('--pg-bin',default=r'C:\Program Files\PostgreSQL\17\bin');ap.add_argument('--host',default='localhost');ap.add_argument('--port',type=int,default=5432);ap.add_argument('--user',default='postgres');args=ap.parse_args()
    original_transform=patch_wave_engine();static=static_preflight(original_transform)
    runstamp=stamp();compiler=f'msbf_r1_r26_compile_{runstamp}';final=f'msbf_r1_r26_g3v2_{runstamp}'
    work=ROOT/'results'/f'msbf_r1_r26_{runstamp}_WORK';work.mkdir(parents=True);ev=work/'evidence';ev.mkdir();(work/'logs').mkdir();(work/'transformed_sources').mkdir();scratch=work/'scratch';scratch.mkdir()
    write_json(ev/'00_STATIC_PREFLIGHT.json',static)
    receipt={'runtime_id':BUILD_ID,'status':'RUNNING','started_at_utc':utcnow(),'last_stage':'INITIALIZE','source_db':args.source_db,'compiler_db':compiler,'final_db':final,'compiler_retained':False,'final_retained':False,'source_modified':None,'policy_sha256':r26_policy.POLICY_SHA256,'policy':r26_policy.POLICY,'operator_package_revision':'R3','r2_correction':'WAVE_A_SEMANTIC_CANONICALIZATION','failure':None}
    log=work/'logs'/'R26.log';origout,origerr=sys.stdout,sys.stderr
    class Tee:
      def __init__(self,*fs):self.fs=fs
      def write(self,s):
        for f in self.fs:f.write(s);f.flush()
      def flush(self):
        for f in self.fs:f.flush()
    pg=None;before_schema=None;before_control=None
    with log.open('w',encoding='utf-8',newline='\n') as lf:
      sys.stdout=Tee(origout,lf);sys.stderr=Tee(origerr,lf)
      try:
        print(BUILD_ID+' starting',flush=True)
        tools=PgTools.from_bin(Path(args.pg_bin));env=os.environ.copy()
        if not env.get('PGPASSWORD'): env['PGPASSWORD']=getpass.getpass(f'PostgreSQL password for local user {args.user} (not stored): ')
        pg=PgContext(tools,args.host,args.port,args.user,env)
        receipt['last_stage']='IMMUTABLE_R6_PREFLIGHT'
        if not pg.db_exists(args.source_db): raise RuntimeError('Immutable R6 source database not found: '+args.source_db)
        before_control=wave.source_control(str(tools.psql),['-h',args.host,'-p',str(args.port),'-U',args.user],args.source_db,{**env,'PGOPTIONS':'-c default_transaction_read_only=on'},log);wave.validate_source_control(before_control)
        before_schema=schema_fp(pg,args.source_db,scratch);write_json(ev/'01_R6_PREFLIGHT.json',{'source_control':before_control,'schema':before_schema})
        receipt['last_stage']='COMPILER_CLONE';clone=pg.clone_database(args.source_db,compiler,scratch);receipt['compiler_retained']=True;write_json(ev/'02_COMPILER_CLONE.json',clone)
        conn=['-h',args.host,'-p',str(args.port),'-U',args.user];env_ro={**env,'PGOPTIONS':'-c default_transaction_read_only=on'}
        cwa=ev/'compiler'/'wave_a';cwa.mkdir(parents=True);receipt['last_stage']='COMPILER_M2_5_M2_10'
        comp_wave=wave.execute_wave(str(tools.psql),conn,compiler,env,log,'COMPILER',cwa,work/'transformed_sources',before_control['m2_4_combined_set_hash'],prepared=False)
        comp_ctrl=r26_controls(pg,compiler);write_json(ev/'compiler'/'R26_POLICY_CONTROLS.json',{'status':'PASS','controls':comp_ctrl})
        comp_exports=export_wave_a_csvs(pg,compiler,ev/'compiler'/'wave_a_exports')
        comp_dbid=wave.stable_database_identity(str(tools.psql),conn,compiler,env_ro,log);write_json(ev/'compiler'/'WAVE_A_DATABASE_IDENTITY.json',comp_dbid)
        receipt['last_stage']='COMPILER_M2_11_M2_12';comp_g3=build_g3(pg,compiler,comp_exports,ev/'compiler'/'wave_a_exports',ev/'compiler'/'g3')
        comp_identity=combined_identity(comp_wave,comp_dbid,comp_ctrl,comp_g3);write_json(ev/'03_COMPILER_COMBINED_IDENTITY.json',comp_identity)
        receipt['last_stage']='DROP_COMPILER';pg.drop_database(compiler);receipt['compiler_retained']=False
        receipt['last_stage']='FINAL_CLONE';clone2=pg.clone_database(args.source_db,final,scratch);receipt['final_retained']=True;write_json(ev/'04_FINAL_CLONE.json',clone2)
        fwa=ev/'final'/'wave_a';fwa.mkdir(parents=True);receipt['last_stage']='FINAL_M2_5_M2_10'
        final_wave=wave.execute_wave(str(tools.psql),conn,final,env,log,'FINAL',fwa,work/'transformed_sources',before_control['m2_4_combined_set_hash'],compiler_receipts=comp_wave['stage_receipts'],prepared=False)
        final_ctrl=r26_controls(pg,final);write_json(ev/'final'/'R26_POLICY_CONTROLS.json',{'status':'PASS','controls':final_ctrl})
        final_exports=export_wave_a_csvs(pg,final,ev/'final'/'wave_a_exports')
        final_dbid=wave.stable_database_identity(str(tools.psql),conn,final,env_ro,log);write_json(ev/'final'/'WAVE_A_DATABASE_IDENTITY.json',final_dbid)
        receipt['last_stage']='FINAL_M2_11_M2_12';final_g3=build_g3(pg,final,final_exports,ev/'final'/'wave_a_exports',ev/'final'/'g3',expected_sim=comp_g3['simulation_identity'])
        final_identity=combined_identity(final_wave,final_dbid,final_ctrl,final_g3);write_json(ev/'05_FINAL_COMBINED_IDENTITY.json',final_identity)
        comparison={'status':'PASS' if comp_identity==final_identity else 'FAIL','compiler_sha256':hobj(comp_identity),'final_sha256':hobj(final_identity)};write_json(ev/'06_COMPILER_FINAL_EXACT_IDENTITY.json',comparison)
        if comparison['status']!='PASS': raise RuntimeError('R26 compiler/final exact combined identity mismatch')
        receipt['last_stage']='R6_NONMUTATION'
        after_control=wave.source_control(str(tools.psql),conn,args.source_db,env_ro,log);after_schema=schema_fp(pg,args.source_db,scratch)
        nonmutation={'source_control_exact':before_control==after_control,'normalized_schema_exact':before_schema['normalized_schema_sha256']==after_schema['normalized_schema_sha256'],'before':{'source_control':before_control,'schema':before_schema},'after':{'source_control':after_control,'schema':after_schema}}
        nonmutation['status']='PASS' if nonmutation['source_control_exact'] and nonmutation['normalized_schema_exact'] else 'FAIL';write_json(ev/'07_R6_NONMUTATION.json',nonmutation)
        if nonmutation['status']!='PASS': raise RuntimeError('Immutable R6 source changed')
        receipt.update({'status':'PASS','last_stage':'COMPLETE','completed_at_utc':utcnow(),'compiler_retained':False,'final_retained':True,'source_modified':False,'final_database':final,'compiler_final_identity_sha256':hobj(final_identity),'g3v2_certification_id':final_g3['identity']['master']['certification_id'],'g3v2_status':'PASS','authority_state':'CANDIDATE_ONLY_PENDING_FOCUSED_INDEPENDENT_AUDIT','publication_state':'NOT_AUTHORIZED','m2_5_daily_rows':final_exports['m2_5']['rows'],'m2_5_r26_daily_rows':final_exports['m2_5_r26']['rows'],'m2_6_rows':final_exports['m2_6']['rows'],'candidate_evaluations':52152,'application_simulations':12000,'account_simulations':1040})
      except Exception as ex:
        receipt.update({'status':'FAIL','completed_at_utc':utcnow(),'failure':repr(ex),'traceback':traceback.format_exc()});print('FAILURE: '+repr(ex));traceback.print_exc()
        if pg:
          try:receipt['compiler_retained']=pg.db_exists(compiler)
          except:pass
          try:receipt['final_retained']=pg.db_exists(final)
          except:pass
        try:
          if pg and before_control is not None:
            ac=wave.source_control(str(pg.tools.psql),['-h',args.host,'-p',str(args.port),'-U',args.user],args.source_db,{**pg.env,'PGOPTIONS':'-c default_transaction_read_only=on'},log);asch=schema_fp(pg,args.source_db,scratch)
            receipt['source_modified']=not(before_control==ac and before_schema['normalized_schema_sha256']==asch['normalized_schema_sha256'])
        except Exception as px: receipt['failure_nonmutation_probe_error']=repr(px)
      finally:
        write_json(work/'R26_RECEIPT.json',receipt);shutil.rmtree(scratch,ignore_errors=True);sys.stdout,sys.stderr=origout,origerr
    out=ROOT/'results'/f'msbf_r1_r26_{runstamp}_M2_5_M2_12_G3V2_RESULTS.zip';sh=deterministic_zip(work,out);(Path(str(out)+'.sha256')).write_text(f'{sh}  {out.name}\n',encoding='ascii')
    print(f'R26 M2.5-M2.12/G3-v2 finished: {receipt["status"]}')
    print(f'R6 source modified: {receipt.get("source_modified")}')
    print(f'Compiler clone retained: {compiler if receipt.get("compiler_retained") else "NO"}')
    print(f'Final clone retained: {final if receipt.get("final_retained") else "NO"}')
    print(f'Last stage: {receipt.get("last_stage")}')
    print(f'Results: {out}')
    print(f'SHA-256: {sh}')
    if receipt['status']!='PASS': print(f'Failure: {receipt.get("failure")}');return 1
    return 0

if __name__=='__main__': raise SystemExit(main())
