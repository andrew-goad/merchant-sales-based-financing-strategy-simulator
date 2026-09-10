#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv,getpass,hashlib,json,os,re,shutil,subprocess,time,zipfile
from pathlib import Path
from datetime import datetime,timezone

HERE=Path(__file__).resolve().parents[1]
META=json.loads((HERE/'config/STAGE_METADATA_R3.json').read_text(encoding='utf-8'))
SRC_MAN=list(csv.DictReader((HERE/'manifests/01_ACCEPTED_SOURCE_MANIFEST.csv').open(encoding='utf-8')))
TIME_KEYS=['created_at','updated_at','generated_at','validated_at','accepted_at','archived_at','captured_at','evaluated_at']
STAGES=['5','6','7','8','9','10']

def sha256_file(p):
 h=hashlib.sha256()
 with open(p,'rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()

def hash_text(t,alg='sha256'):
 return hashlib.new(alg,t.encode('utf-8')).hexdigest()

def canon(obj):return json.dumps(obj,sort_keys=True,separators=(',',':'),ensure_ascii=True)

def run(cmd,env,log,input_text=None,check=True):
 cp=subprocess.run(cmd,text=True,input=input_text,capture_output=True,env=env)
 with open(log,'a',encoding='utf-8') as f:
  f.write('\n$ '+' '.join(map(str,cmd))+'\n');f.write(cp.stdout or '');f.write(cp.stderr or '')
 if check and cp.returncode:raise RuntimeError(f"Command failed ({cp.returncode}): {' '.join(map(str,cmd))}")
 return cp

def scalar(psql,conn,db,env,log,sql):
 return run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',sql],env,log).stdout.strip()

def qident(s):return '"'+s.replace('"','""')+'"'

def database_exists(psql,conn,env,log,db):
 return scalar(psql,conn,'postgres',env,log,"SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname='"+db.replace("'","''")+"');")=='t'

def source_control(psql,conn,db,env,log):
 sql="""
 WITH r AS (
   SELECT count(*)::bigint AS row_count,max(rr.run_id)::bigint AS run_id,max(rr.run_status)::text AS run_status
   FROM msbf_ctl.run_registry rr WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1
 ), reg AS (
   SELECT count(*)::bigint AS row_count,max(cr.contract_status)::text AS contract_status,max(cr.combined_set_hash)::text AS combined_set_hash
   FROM msbf_ctl.m2_4_booking_activation_contract_registry cr CROSS JOIN r
   WHERE cr.module1_run_id=r.run_id
 ), gate AS (
   SELECT count(*)::bigint AS row_count,(array_agg(agr.result_status ORDER BY agr.review_version DESC))[1]::text AS result_status
   FROM msbf_ctl.acceptance_gate_result agr CROSS JOIN r
   WHERE agr.run_id=r.run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
 ), rb AS (
   SELECT count(*)::bigint AS row_count,max(ds.rebase_status)::text AS rebase_status
   FROM msbf_m12r1e.downstream_rebase_status ds WHERE ds.stage_code='M2_4'
 )
 SELECT jsonb_build_object(
   'run_row_count',r.row_count,'run_id',r.run_id,'run_status',r.run_status,
   'm2_4_registry_row_count',reg.row_count,'m2_4_contract_status',reg.contract_status,'m2_4_combined_set_hash',reg.combined_set_hash,
   'm2_4_gate_row_count',gate.row_count,'m2_4_gate_status',gate.result_status,
   'm2_4_rebase_row_count',rb.row_count,'m2_4_rebase_status',rb.rebase_status,
   'account_rows',(SELECT count(*) FROM msbf_m2.synthetic_account_activation),
   'advance_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding),
   'portfolio_rows',(SELECT count(*) FROM msbf_m2.initial_portfolio_activation),
   'baseline_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding saf WHERE saf.scenario_code='BASELINE'),
   'stress_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding saf WHERE saf.scenario_code='RECESSION_ENERGY'),
   'downstream_pending',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status ds WHERE ds.stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12') AND ds.rebase_status='PENDING_REBASE')
 )::text FROM r CROSS JOIN reg CROSS JOIN gate CROSS JOIN rb;
 """
 raw=scalar(psql,conn,db,env,log,sql)
 if not raw:raise RuntimeError('R6 source-control query returned no row')
 return json.loads(raw)

def validate_source_control(c):
 expected={'run_row_count':1,'run_status':'M2_4_ACCEPTED','m2_4_registry_row_count':1,'m2_4_contract_status':'ACCEPTED','m2_4_combined_set_hash':'deedb8bd7696e441126a6f4526fc4842','m2_4_gate_row_count':1,'m2_4_gate_status':'PASS','m2_4_rebase_row_count':1,'m2_4_rebase_status':'VALIDATED_CANDIDATE','account_rows':130,'advance_rows':130,'portfolio_rows':130,'baseline_funded_rows':103,'stress_funded_rows':27,'downstream_pending':8}
 bad={k:{'expected':v,'actual':c.get(k)} for k,v in expected.items() if c.get(k)!=v}
 if bad:raise RuntimeError('R6 source control mismatch: '+canon(bad))
 return expected

def control_fingerprint(c):return hash_text(canon(c),'sha256')

def catalog_column_preflight(psql,conn,db,env,log):
    req=list(csv.DictReader((HERE/'manifests/12_SOURCE_CONTROL_COLUMN_CONTRACT.csv').open(encoding='utf-8')))
    out=[]
    for r in req:
        sql=f"SELECT data_type FROM information_schema.columns WHERE table_schema='{r['schema_name']}' AND table_name='{r['object_name']}' AND column_name='{r['column_name']}';"
        actual=scalar(psql,conn,db,env,log,sql)
        exp=r['expected_type'].strip().lower()
        act=actual.strip().lower()
        aliases={'int8':'bigint','int4':'integer','int2':'smallint','timestamp with time zone':'timestamptz','timestamp without time zone':'timestamp'}
        ok=bool(actual) and aliases.get(act,act)==aliases.get(exp,exp)
        out.append({**r,'actual_type':actual,'status':'PASS' if ok else 'FAIL'})
    if any(x['status']=='FAIL' for x in out): raise RuntimeError('Source-control column contract failed')
    return out

def remove_tagged_block(txt,tag):
 pat=re.compile(r'DO\s+\$'+re.escape(tag)+r'\$.*?\$'+re.escape(tag)+r'\$\s*;',re.S|re.I);n=len(pat.findall(txt))
 if n!=1:raise RuntimeError(f'Expected one {tag} block; found {n}')
 return pat.sub(f'/* SUCCESSOR WAVE A R3: predecessor population-bound guard {tag} superseded by successor checkpoint controls. */',txt)

def patch_m2_10_mapping(txt):
 start='DROP TABLE IF EXISTS _m2_10_source_classified;'
 end='ANALYZE _m2_10_source_classified;'
 if txt.count(start)!=1 or txt.count(end)!=1:raise RuntimeError('M2.10 source-classification block boundary mismatch')
 a=txt.index(start);b=txt.index(end,a)+len(end)
 block=r"""DROP TABLE IF EXISTS _m2_10_source_classified;
CREATE TEMP TABLE _m2_10_source_classified ON COMMIT DROP AS
WITH classified AS
(
    SELECT
        source.*,
        CASE
            WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
             AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
             AND source.state_certified_flag IS TRUE
             AND source.closed_state_flag IS TRUE
             AND source.active_state_flag IS FALSE
             AND source.review_hold_state_flag IS FALSE
             AND source.exception_case_count=0
             AND source.resolved_exception_count=0
             AND source.unresolved_exception_count=0
             AND source.certified_exposure_amount=0
             AND source.scheduled_payment_amount=0
             AND source.processed_payment_amount=0
             AND source.returned_payment_amount=0
             AND source.retry_payment_amount=0
             AND source.reconciliation_variance_amount=0
             AND source.exposure_variance_amount=0
            THEN 'CLOSED_STABLE'
            WHEN source.reconciliation_outcome_code IN ('PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')
             AND source.certified_state_code IN ('CERTIFIED_ACTIVE_CURRENT','CERTIFIED_ACTIVE_AFTER_RETRY','CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')
             AND source.state_certified_flag IS TRUE
             AND source.active_state_flag IS TRUE
             AND source.closed_state_flag IS FALSE
             AND source.review_hold_state_flag IS FALSE
             AND source.unresolved_exception_count=0
             AND source.reconciliation_variance_amount=0
             AND source.exposure_variance_amount=0
             AND source.certified_exposure_amount>=0
             AND source.scheduled_payment_amount=source.processed_payment_amount
             AND source.returned_payment_amount=source.retry_payment_amount
             AND (source.reconciliation_outcome_code<>'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
                  OR (source.exception_resolved_flag IS TRUE AND source.returned_event_count>=1 AND source.retry_event_count>=1))
            THEN 'ACTIVE_RECONCILED'
            WHEN source.reconciliation_outcome_code IN ('RECONCILIATION_REVIEW_HOLD','PAYMENT_ACTIVITY_VARIANCE','PAYMENT_EXCEPTION_UNRESOLVED','RECONCILIATION_CERTIFICATION_FAILED')
              OR source.review_hold_state_flag IS TRUE
              OR source.state_certified_flag IS FALSE
            THEN 'CONTROLLED_REVIEW'
            ELSE 'SOURCE_MAPPING_ERROR'
        END AS successor_posture_code
    FROM _m2_10_source_expected AS source
)
SELECT
    classified.*,
    successor_posture_code AS source_mapping_code,
    successor_posture_code AS performance_tier_code,
    CASE successor_posture_code
      WHEN 'CLOSED_STABLE' THEN 'NO_SERVICING_REQUIRED'
      WHEN 'ACTIVE_RECONCILED' THEN 'ACTIVE_REASSESSMENT'
      WHEN 'CONTROLLED_REVIEW' THEN 'GOVERNANCE_REVIEW_HOLD'
      ELSE 'SOURCE_MAPPING_ERROR'
    END AS servicing_queue_code,
    CASE successor_posture_code
      WHEN 'CLOSED_STABLE' THEN 'M2_10_REASON_CLOSED_STABLE'
      WHEN 'ACTIVE_RECONCILED' THEN 'M2_10_REASON_ACTIVE_RECONCILED'
      WHEN 'CONTROLLED_REVIEW' THEN 'M2_10_REASON_CONTROLLED_REVIEW'
      ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR'
    END AS primary_portfolio_reason_code
FROM classified;
CREATE UNIQUE INDEX ON _m2_10_source_classified(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX ON _m2_10_source_classified(module1_run_id,source_mapping_code);
ANALYZE _m2_10_source_classified;"""
 return txt[:a]+block+txt[b:]

def transform(stage,src_class,txt,prior_hash):
 m=META[stage];txt=txt.replace(m['old_hash'],prior_hash)
 if stage!='5':
  prev=m['prev'].replace('.','_');txt=txt.replace(prev+'_ACCEPTED',prev+'_GENERATED')
  txt=txt.replace("registry.contract_status='ACCEPTED'","registry.contract_status='GENERATED'")
  txt=txt.replace("registry.contract_status = 'ACCEPTED'","registry.contract_status = 'GENERATED'")
 if src_class=='GEN':
  for tag in m.get('remove_tags',[]):txt=remove_tagged_block(txt,tag)
  if stage=='10':txt=patch_m2_10_mapping(txt)
 return txt

def lexical_sql_check(txt):
 # Balance quotes, dollar quotes and parentheses while ignoring comments.
 i=0;n=len(txt);stack=[];paren=0;state='normal';dtag=None
 while i<n:
  c=txt[i];nxt=txt[i+1] if i+1<n else ''
  if state=='line':
   if c=='\n':state='normal'
   i+=1;continue
  if state=='block':
   if c=='*' and nxt=='/':state='normal';i+=2;continue
   i+=1;continue
  if state=='single':
   if c=="'":
    if nxt=="'":i+=2;continue
    state='normal'
   i+=1;continue
  if state=='double':
   if c=='"':
    if nxt=='"':i+=2;continue
    state='normal'
   i+=1;continue
  if state=='dollar':
   if txt.startswith(dtag,i):state='normal';i+=len(dtag);continue
   i+=1;continue
  if c=='-' and nxt=='-':state='line';i+=2;continue
  if c=='/' and nxt=='*':state='block';i+=2;continue
  if c=="'":state='single';i+=1;continue
  if c=='"':state='double';i+=1;continue
  if c=='$':
   m=re.match(r'\$[A-Za-z0-9_]*\$',txt[i:])
   if m:dtag=m.group(0);state='dollar';i+=len(dtag);continue
  if c=='(':paren+=1
  elif c==')':paren-=1
  if paren<0:raise RuntimeError('SQL parenthesis underflow')
  i+=1
 if state not in ('normal','line'):raise RuntimeError(f'Unclosed SQL lexical state {state}')
 if paren!=0:raise RuntimeError(f'Unbalanced SQL parentheses {paren}')
 return True

def static_transform_preflight():
 controls=[];placeholder='0123456789abcdef0123456789abcdef'
 for stage in STAGES:
  m=META[stage];srcs={r['source_class']:r for r in SRC_MAN if r['stage']==m['stage']}
  for cls in ['SCHEMA','GEN']:
   p=HERE/srcs[cls]['package_path'];txt=p.read_text(encoding='utf-8');out=transform(stage,cls,txt,placeholder);lexical_sql_check(out)
   if m['old_hash'] in out:raise RuntimeError(f"{m['stage']} {cls} retained predecessor hash")
   if placeholder not in out:raise RuntimeError(f"{m['stage']} {cls} did not bind successor predecessor hash")
   tags=re.findall(r'DO\s+\$([A-Za-z0-9_]*)\$',out,re.I)
   if cls=='GEN' and sorted(tags)!=sorted(m.get('retained_do_tags',[])):raise RuntimeError(f"{m['stage']} retained DO tags {tags} != {m.get('retained_do_tags',[])}")
   for tag in m.get('remove_tags',[]):
    if re.search(r'DO\s+\$'+re.escape(tag)+r'\$',out,re.I):raise RuntimeError(f'{m["stage"]} retained removed guard {tag}')
   if stage=='10' and cls=='GEN':
    for literal in ['=323.79','=461.69','=194.25','=27.75']:
     if literal in out:raise RuntimeError(f'M2.10 retained fixture mapping literal {literal}')
    if 'successor_posture_code' not in out:raise RuntimeError('M2.10 generalized mapping absent')
   controls.append({'stage':m['stage'],'source_class':cls,'status':'PASS','transformed_bytes':len(out.encode()),'retained_do_tags':'|'.join(tags)})
 return controls

def object_present(psql,conn,db,env,log,name,kind,parent_object=None):
    kind=kind.upper()
    if kind in ('TABLE','VIEW'):
        sch,obj=name.split('.',1)
        relkinds="('r','p')" if kind=='TABLE' else "('v','m')"
        return scalar(psql,conn,db,env,log,f"SELECT EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='{sch}' AND c.relname='{obj}' AND c.relkind IN {relkinds});")=='t'
    if kind=='FUNCTION':
        sch,obj=name.split('.',1)
        return scalar(psql,conn,db,env,log,f"SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='{sch}' AND p.proname='{obj}');")=='t'
    if kind=='TRIGGER':
        if not parent_object: return False
        sch,tab=parent_object.split('.',1)
        return scalar(psql,conn,db,env,log,f"SELECT EXISTS(SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='{sch}' AND c.relname='{tab}' AND t.tgname='{name}' AND NOT t.tgisinternal);")=='t'
    if kind=='INDEX':
        if not parent_object: return False
        sch,tab=parent_object.split('.',1)
        return scalar(psql,conn,db,env,log,f"SELECT EXISTS(SELECT 1 FROM pg_class i JOIN pg_index ix ON ix.indexrelid=i.oid JOIN pg_class t ON t.oid=ix.indrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='{sch}' AND t.relname='{tab}' AND i.relname='{name}');")=='t'
    if kind=='SEQUENCE':
        sch,obj=name.split('.',1)
        return scalar(psql,conn,db,env,log,f"SELECT EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='{sch}' AND c.relname='{obj}' AND c.relkind='S');")=='t'
    return True

def normalize_pg_type(value):
    x=re.sub(r'\s+',' ',value.strip().lower())
    aliases={'timestamptz':'timestamp with time zone','timestampz':'timestamp with time zone','varchar':'character varying','int8':'bigint','int4':'integer','int2':'smallint','bool':'boolean'}
    for a,b in aliases.items():
        if x==a: x=b
        elif x.startswith(a+'('): x=b+x[len(a):]
    return x

def physical_semantics_validate(psql,conn,db,env,log,stage):
    cols=list(csv.DictReader((HERE/'manifests/06_PHYSICAL_COLUMN_SEMANTICS_M2_5_M2_10.csv').open(encoding='utf-8')))
    cols=[r for r in cols if r['stage']==stage]
    bad=[]
    for r in cols:
        sql=f"""SELECT format_type(a.atttypid,a.atttypmod),a.attnotnull,(ad.adbin IS NOT NULL),a.attidentity,a.attgenerated
        FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace LEFT JOIN pg_attrdef ad ON ad.adrelid=a.attrelid AND ad.adnum=a.attnum
        WHERE n.nspname='{r['schema_name']}' AND c.relname='{r['object_name_only']}' AND a.attname='{r['column_name']}' AND a.attnum>0 AND NOT a.attisdropped;"""
        cp=run([psql,*conn,'-d',db,'-X','-At','-F','|','-v','ON_ERROR_STOP=1','-c',sql],env,log)
        lines=[x for x in cp.stdout.splitlines() if x]
        if len(lines)!=1:
            bad.append({**r,'issue':'MISSING_OR_DUPLICATE_COLUMN'});continue
        typ,nn,defp,ident,gen=lines[0].split('|')
        type_ok=normalize_pg_type(r['data_type_sql'])==normalize_pg_type(typ)
        semantics_ok=(r['not_null_required']=='1')==(nn=='t') and (r['default_present']=='1')==(defp=='t') and (r['identity_or_generated_required']=='1')==bool(ident or gen)
        if not type_ok or not semantics_ok:
            bad.append({**r,'issue':'SEMANTICS_MISMATCH','actual_type':typ,'actual_not_null':nn,'actual_default':defp,'actual_identity':ident,'actual_generated':gen})
    return bad

def support_semantics_validate(psql,conn,db,env,log,stage):
    rows=list(csv.DictReader((HERE/'manifests/05_SUPPORT_OBJECT_REQUIREMENTS_M2_5_M2_10.csv').open(encoding='utf-8')))
    rows=[r for r in rows if r['stage']==stage]
    out=[]
    for r in rows:
        parent=r.get('parent_object') or None
        ok=object_present(psql,conn,db,env,log,r['object_name'],r['object_type'],parent)
        out.append({**r,'status':'PASS' if ok else 'FAIL'})
    return out

def key_semantics_validate(psql,conn,db,env,log,stage):
    rows=list(csv.DictReader((HERE/'manifests/07_KEY_REQUIREMENTS_M2_5_M2_10.csv').open(encoding='utf-8')))
    rows=[r for r in rows if r['stage']==stage]
    out=[]
    for r in rows:
        cols=json.loads(r['columns_json']); arr='ARRAY['+','.join("'"+c.replace("'","''")+"'" for c in cols)+']::text[]'
        typ='p' if r['key_type']=='PRIMARY_KEY' else 'u'
        sql=f"""SELECT EXISTS(SELECT 1 FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='{r['schema_name']}' AND c.relname='{r['object_name_only']}' AND con.contype='{typ}'
        AND (SELECT array_agg(a.attname::text ORDER BY u.ord) FROM unnest(con.conkey) WITH ORDINALITY u(attnum,ord) JOIN pg_attribute a ON a.attrelid=con.conrelid AND a.attnum=u.attnum)={arr});"""
        ok=scalar(psql,conn,db,env,log,sql)=='t';out.append({**r,'status':'PASS' if ok else 'FAIL'})
    return out

def foreign_key_semantics_validate(psql,conn,db,env,log,stage):
    rows=list(csv.DictReader((HERE/'manifests/08_FOREIGN_KEY_REQUIREMENTS_M2_5_M2_10.csv').open(encoding='utf-8')))
    rows=[r for r in rows if r['stage']==stage]
    out=[]
    for r in rows:
        cols=json.loads(r['columns_json']);refs=json.loads(r['ref_columns_json'])
        a1='ARRAY['+','.join("'"+c.replace("'","''")+"'" for c in cols)+']::text[]';a2='ARRAY['+','.join("'"+c.replace("'","''")+"'" for c in refs)+']::text[]'
        sql=f"""SELECT EXISTS(SELECT 1 FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_class rc ON rc.oid=con.confrelid JOIN pg_namespace rn ON rn.oid=rc.relnamespace
        WHERE n.nspname='{r['schema_name']}' AND c.relname='{r['object_name_only']}' AND con.contype='f' AND rn.nspname='{r['ref_schema_name']}' AND rc.relname='{r['ref_object_name']}'
        AND (SELECT array_agg(a.attname::text ORDER BY u.ord) FROM unnest(con.conkey) WITH ORDINALITY u(attnum,ord) JOIN pg_attribute a ON a.attrelid=con.conrelid AND a.attnum=u.attnum)={a1}
        AND (SELECT array_agg(a.attname::text ORDER BY u.ord) FROM unnest(con.confkey) WITH ORDINALITY u(attnum,ord) JOIN pg_attribute a ON a.attrelid=con.confrelid AND a.attnum=u.attnum)={a2});"""
        ok=scalar(psql,conn,db,env,log,sql)=='t';out.append({**r,'status':'PASS' if ok else 'FAIL'})
    return out

def named_constraint_validate(psql,conn,db,env,log,stage):
    rows=list(csv.DictReader((HERE/'manifests/09_NAMED_CONSTRAINTS_M2_5_M2_10.csv').open(encoding='utf-8')))
    rows=[r for r in rows if r['stage']==stage]
    out=[]
    typemap={'CHECK':'c','FOREIGN_KEY':'f','PRIMARY_KEY':'p','UNIQUE_CONSTRAINT':'u'}
    for r in rows:
        typ=typemap.get(r['constraint_type'])
        clause=f" AND con.contype='{typ}'" if typ else ''
        sql=f"SELECT count(*) FROM pg_constraint con JOIN pg_namespace n ON n.oid=con.connamespace WHERE n.nspname IN ('msbf_ctl','msbf_m2') AND con.conname='{r['constraint_name']}'{clause};"
        count=int(scalar(psql,conn,db,env,log,sql));out.append({**r,'catalog_count':count,'status':'PASS' if count==1 else 'FAIL'})
    return out

def table_count(psql,conn,db,env,log,t):return int(scalar(psql,conn,db,env,log,f'SELECT count(*) FROM {t};'))

def table_set_summary(psql,conn,db,env,log,tables):
 items=[];keys=','.join("'"+k+"'" for k in TIME_KEYS)
 for t in sorted(tables):
  if scalar(psql,conn,db,env,log,f"SELECT to_regclass('{t}') IS NOT NULL;")!='t':raise RuntimeError(f'Missing stage table {t}')
  n=table_count(psql,conn,db,env,log,t)
  h=scalar(psql,conn,db,env,log,f"SELECT coalesce(md5(string_agg(h,'|' ORDER BY h)),md5('')) FROM (SELECT md5((to_jsonb(x)-ARRAY[{keys}]::text[])::text) h FROM {t} x) s;")
  items.append({'table':t,'rows':n,'normalized_md5':h})
 payload=canon(items)
 return {'tables':items,'md5':hash_text(payload,'md5'),'sha256':hash_text(payload,'sha256')}

def validate_hash_columns(psql,conn,db,env,log,tables):
 details=[]
 for t in tables:
  sch,tab=t.split('.',1)
  rows=run([psql,*conn,'-d',db,'-X','-At','-F','|','-c',
    f"SELECT column_name,is_nullable FROM information_schema.columns "
    f"WHERE table_schema='{sch}' AND table_name='{tab}' "
    f"AND (column_name='row_hash' OR column_name LIKE '%_row_hash' "
    f"OR column_name IN ('contract_row_hash','archive_row_hash')) ORDER BY ordinal_position;"],
    env,log).stdout.splitlines()
  for row in rows:
   c,nullable=row.split('|',1)
   null_rows=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {t} WHERE {qident(c)} IS NULL;"))
   malformed_rows=int(scalar(psql,conn,db,env,log,
     f"SELECT count(*) FROM {t} WHERE {qident(c)} IS NOT NULL "
     f"AND (length({qident(c)}::text)<>32 OR {qident(c)}::text !~ '^[0-9a-f]{{32}}$');"))
   invalid_rows=malformed_rows+(null_rows if nullable=='NO' else 0)
   details.append({'table':t,'column':c,'nullable':nullable=='YES',
     'null_rows':null_rows,'malformed_rows':malformed_rows,'invalid_rows':invalid_rows})
 return details

def validate_boundary_flags(psql,conn,db,env,log,tables):
 details=[];where="(column_name ~ '(executed|generated|transmitted|called|moved|posted|present)_flag$' OR column_name IN ('real_funds_moved_flag','external_system_update_flag','production_account_state_flag','production_adverse_action_flag','merchant_contact_executed_flag','external_notice_generated_flag','ach_or_network_transmitted_flag','bank_account_data_present_flag','write_off_or_collection_flag')) AND left(column_name,3)<>'no_'"
 for t in tables:
  sch,tab=t.split('.',1);cols=run([psql,*conn,'-d',db,'-X','-At','-c',f"SELECT column_name FROM information_schema.columns WHERE table_schema='{sch}' AND table_name='{tab}' AND data_type='boolean' AND {where} ORDER BY ordinal_position;"],env,log).stdout.splitlines()
  for c in cols:
   n=int(scalar(psql,conn,db,env,log,f'SELECT count(*) FROM {t} WHERE {qident(c)} IS TRUE;'));details.append({'table':t,'column':c,'true_rows':n})
 return details

def comparison_detail(psql,conn,db,env,log,view):
 sch,tab=view.split('.',1);cols=run([psql,*conn,'-d',db,'-X','-At','-c',f"SELECT column_name FROM information_schema.columns WHERE table_schema='{sch}' AND table_name='{tab}' AND column_name LIKE '%improvement_flag' ORDER BY ordinal_position;"],env,log).stdout.splitlines();rows=table_count(psql,conn,db,env,log,view);d=[]
 for c in cols:d.append({'column':c,'true_rows':int(scalar(psql,conn,db,env,log,f'SELECT count(*) FROM {view} WHERE {qident(c)} IS TRUE;'))})
 return rows,d

def lineage_values(psql,conn,db,env,log,m,prior_hash):
 checks=[]
 for obj,col,label in [(m['policy_profile'],m['policy_source_hash_column'],'POLICY'),(m['source_table'],m['source_hash_column'],'SOURCE'),(m['legacy_registry'],m['registry_source_hash_column'],'LEGACY_REGISTRY')]:
  vals=scalar(psql,conn,db,env,log,f"SELECT coalesce(string_agg(DISTINCT {qident(col)}::text,'|' ORDER BY {qident(col)}::text),'') FROM {obj};")
  checks.append({'location':label,'object':obj,'column':col,'values':vals,'status':'PASS' if vals==prior_hash else 'FAIL'})
 return checks

def stage_population_payload(psql,conn,db,env,log,stage,m):
    payload={'table_counts':{t:table_count(psql,conn,db,env,log,t) for t in m['tables']}}
    payload['baseline_source_rows']=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {m['source_table']} WHERE scenario_code='BASELINE';"))
    payload['stress_source_rows']=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {m['source_table']} WHERE scenario_code='RECESSION_ENERGY';"))
    payload['canonical_entities']=table_count(psql,conn,db,env,log,m['canonical_view'])
    if stage=='5':
        q="SELECT jsonb_build_object('paid_off_rows',count(*) FILTER(WHERE paid_off_flag),'open_monitoring_rows',count(*) FILTER(WHERE NOT paid_off_flag),'total_remittance_amount',coalesce(round(sum(cumulative_remittance_amount),2),0),'ending_receivable_exposure_amount',coalesce(round(sum(remaining_receivable_amount),2),0))::text FROM msbf_m2.advance_portfolio_monitoring_latest;"
    elif stage=='6':
        q="""SELECT jsonb_build_object('outcome_distribution',(SELECT jsonb_object_agg(strategy_outcome_code,n) FROM (SELECT strategy_outcome_code,count(*) n FROM msbf_m2.advance_intervention_strategy_latest GROUP BY 1) d),'recommended_action_rows',count(*) FILTER(WHERE recommended_action_flag),'review_required_rows',count(*) FILTER(WHERE review_required_flag),'recommended_action_exposure_amount',coalesce(round(sum(recommended_action_exposure_amount) FILTER(WHERE recommended_action_flag),2),0))::text FROM msbf_m2.advance_intervention_strategy_latest;"""
    elif stage=='7':
        q="""SELECT jsonb_build_object('outcome_distribution',(SELECT jsonb_object_agg(operational_setup_outcome_code,n) FROM (SELECT operational_setup_outcome_code,count(*) n FROM msbf_m2.application_operational_activation_latest GROUP BY 1) d),'setup_authorized_rows',count(*) FILTER(WHERE setup_authorized_flag),'review_required_rows',count(*) FILTER(WHERE setup_review_required_flag),'no_setup_rows',count(*) FILTER(WHERE no_setup_required_flag))::text FROM msbf_m2.application_operational_activation_latest;"""
    elif stage=='8':
        q="SELECT jsonb_build_object('payment_event_rows',(SELECT count(*) FROM msbf_m2.synthetic_payment_processing_event),'transition_rows',(SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot),'initial_transition_rows',(SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_sequence=0),'payment_transition_rows',(SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_type_code IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')),'checkpoint_transition_rows',(SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_type_code='REASSESSMENT_CHECKPOINT'))::text;"
    elif stage=='9':
        q="SELECT jsonb_build_object('payment_source_rows',(SELECT count(*) FROM msbf_m2.payment_reconciliation_source_event),'transition_source_rows',(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition),'payment_reconciliation_rows',(SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot),'exception_case_rows',(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot),'reconciliation_variance_amount',(SELECT coalesce(round(sum(abs(reconciliation_variance_amount)),2),0) FROM msbf_m2.account_payment_reconciliation_snapshot),'exposure_variance_amount',(SELECT coalesce(round(sum(abs(exposure_variance_amount)),2),0) FROM msbf_m2.account_payment_reconciliation_snapshot))::text;"
    else:
        q="""SELECT jsonb_build_object('performance_distribution',(SELECT jsonb_object_agg(performance_tier_code,n) FROM (SELECT performance_tier_code,count(*) n FROM msbf_m2.application_portfolio_performance_latest GROUP BY 1) d),'queue_distribution',(SELECT jsonb_object_agg(servicing_queue_code,n) FROM (SELECT servicing_queue_code,count(*) n FROM msbf_m2.application_portfolio_performance_latest GROUP BY 1) d),'source_mapping_errors',count(*) FILTER(WHERE primary_portfolio_reason_code='M2_10_REASON_SOURCE_MAPPING_ERROR'))::text FROM msbf_m2.application_portfolio_performance_latest;"""
    payload.update(json.loads(scalar(psql,conn,db,env,log,q)))
    return payload

def validate_stage(psql,conn,db,env,log,stage,m,prior_hash):
    checks=[]
    def add(cid,ok,obs): checks.append({'stage':m['stage'],'control_id':cid,'status':'PASS' if ok else 'FAIL','observed':str(obs)})
    status=scalar(psql,conn,db,env,log,"SELECT run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;")
    add('RUN_STATUS',status==m['this_generated'],status)
    for t in [m['source_table'],m['latest'],m['archive']]:
        n=table_count(psql,conn,db,env,log,t);add('COUNT_'+t,n==130,n)
    for t,exp in m.get('special',{}).items():
        n=table_count(psql,conn,db,env,log,t);add('COUNT_'+t,n==exp,n)
    base=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {m['source_table']} WHERE scenario_code='BASELINE';"));stress=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {m['source_table']} WHERE scenario_code='RECESSION_ENERGY';"))
    add('SOURCE_SCENARIOS',base==103 and stress==27,f'baseline={base};stress={stress}')
    hd=validate_hash_columns(psql,conn,db,env,log,m['tables']);add('HASH_INTEGRITY',sum(x['invalid_rows'] for x in hd)==0,sum(x['invalid_rows'] for x in hd))
    bd=validate_boundary_flags(psql,conn,db,env,log,m['tables']);add('NO_REAL_WORLD_ACTIONS',sum(x['true_rows'] for x in bd)==0,sum(x['true_rows'] for x in bd))
    cr,cd=comparison_detail(psql,conn,db,env,log,m['comparison']);add('SCENARIO_NONIMPROVEMENT',cr==27 and sum(x['true_rows'] for x in cd)==0,f'rows={cr};improvements={sum(x["true_rows"] for x in cd)}')
    ld=lineage_values(psql,conn,db,env,log,m,prior_hash);add('SOURCE_HASH_LINEAGE',all(x['status']=='PASS' for x in ld),canon(ld))
    if stage=='5':
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.advance_monitoring_source_snapshot WHERE row_hash IS NULL OR funded_amount<=0 OR total_repayment_amount<funded_amount OR initial_exposure_amount IS DISTINCT FROM funded_amount OR remittance_rate NOT BETWEEN 0.05 AND 0.20 OR collection_horizon_days NOT BETWEEN 1 AND 120 OR implied_daily_collection_amount<=0;"));add('SOURCE_BUSINESS_INVARIANTS',invalid==0,invalid)
        per=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM (SELECT module1_run_id,scenario_id,merchant_application_id,count(*) n,min(monitoring_day_index) mn,max(monitoring_day_index) mx FROM msbf_m2.advance_daily_remittance_monitoring GROUP BY 1,2,3 HAVING count(*)<>120 OR min(monitoring_day_index)<>1 OR max(monitoring_day_index)<>120) x;"));add('DAILY_120_PER_SOURCE',per==0,per)
        daily=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.advance_daily_remittance_monitoring WHERE actual_remittance_amount>raw_remittance_amount+0.01 OR actual_remittance_amount>receivable_balance_before+0.01 OR receivable_balance_after<0 OR monitoring_status_rank NOT BETWEEN 0 AND 5 OR (scenario_code='RECESSION_ENERGY' AND monitoring_status_rank<raw_monitoring_status_rank);"));add('DAILY_BUSINESS_INVARIANTS',daily==0,daily)
        portfolio=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.portfolio_daily_monitoring_summary WHERE opening_advance_count<=0 OR active_advance_count<0 OR paid_off_count<0 OR daily_remittance_amount<0 OR total_receivable_exposure_amount<0;"));add('PORTFOLIO_BUSINESS_INVARIANTS',portfolio==0,portfolio)
    elif stage=='6':
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.advance_intervention_strategy_latest WHERE recommended_action_exposure_amount<0 OR (NOT recommended_action_flag AND recommended_action_exposure_amount<>0) OR (recommended_action_flag AND recommended_action_exposure_amount<=0) OR (temporary_adjustment_review_flag AND NOT review_required_flag) OR (workout_review_flag AND NOT review_required_flag) OR (recovery_review_flag AND NOT review_required_flag);"));add('INTERVENTION_ACTION_INVARIANTS',invalid==0,invalid)
    elif stage=='7':
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.application_operational_activation_latest WHERE setup_authorized_flag::int+setup_review_required_flag::int+no_setup_required_flag::int<>1 OR (setup_authorized_flag AND NOT blueprint_created_flag) OR (setup_authorized_flag AND (synthetic_account_setup_id IS NULL OR synthetic_servicing_plan_id IS NULL)) OR (no_setup_required_flag AND blueprint_created_flag);"));add('SETUP_STATE_INVARIANTS',invalid==0,invalid)
    elif stage=='8':
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.application_servicing_execution_latest WHERE processing_authorized_flag::int+processing_review_required_flag::int+no_processing_required_flag::int<>1 OR payment_event_count<>settled_event_count+returned_event_count+retry_event_count OR scheduled_payment_amount<0 OR processed_payment_amount<0 OR returned_payment_amount<0 OR retry_payment_amount<0 OR ending_simulated_exposure_amount<0;"));add('SERVICING_EXECUTION_INVARIANTS',invalid==0,invalid)
        pay=table_count(psql,conn,db,env,log,'msbf_m2.synthetic_payment_processing_event');latest_pay=int(scalar(psql,conn,db,env,log,'SELECT coalesce(sum(payment_event_count),0) FROM msbf_m2.application_servicing_execution_latest;'));add('PAYMENT_EVENT_RECONCILIATION',pay==latest_pay,f'events={pay};latest_sum={latest_pay}')
        initial=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_sequence=0;"));pt=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_type_code IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT');"));cp=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE transition_type_code='REASSESSMENT_CHECKPOINT';"));total=table_count(psql,conn,db,env,log,'msbf_m2.account_lifecycle_transition_snapshot');auth=int(scalar(psql,conn,db,env,log,'SELECT count(*) FROM msbf_m2.application_servicing_execution_latest WHERE processing_authorized_flag;'))
        add('TRANSITION_RECONCILIATION',initial==130 and pt==pay and cp==auth and total==initial+pt+cp,f'initial={initial};pay={pay};payment_transitions={pt};checkpoint={cp};authorized={auth};total={total}')
        hash_link_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot t
          WHERE (
            t.transition_type_code IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')
            AND (
              t.related_payment_event_sequence IS NULL
              OR t.related_payment_instruction_id IS NULL
              OR t.related_payment_event_row_hash IS NULL
              OR NOT EXISTS (
                SELECT 1 FROM msbf_m2.synthetic_payment_processing_event p
                WHERE p.module1_run_id=t.module1_run_id
                  AND p.scenario_id=t.scenario_id
                  AND p.merchant_application_id=t.merchant_application_id
                  AND p.event_sequence=t.related_payment_event_sequence
                  AND p.synthetic_payment_instruction_id=t.related_payment_instruction_id
                  AND p.row_hash=t.related_payment_event_row_hash
              )
            )
          ) OR (
            t.transition_type_code NOT IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')
            AND (
              t.related_payment_event_sequence IS NOT NULL
              OR t.related_payment_instruction_id IS NOT NULL
              OR t.related_payment_event_row_hash IS NOT NULL
            )
          );"""))
        add('OPTIONAL_PAYMENT_EVENT_HASH_LINKAGE',hash_link_mismatch==0,hash_link_mismatch)
        related_hash_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE related_payment_event_row_hash IS NOT NULL;"))
        related_hash_null_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_lifecycle_transition_snapshot WHERE related_payment_event_row_hash IS NULL;"))
        add('OPTIONAL_PAYMENT_EVENT_HASH_CARDINALITY',related_hash_rows==pay and related_hash_null_rows==total-pay,
            f'non_null={related_hash_rows};null={related_hash_null_rows};payment_events={pay};transitions={total}')
    elif stage=='9':
        p8=table_count(psql,conn,db,env,log,'msbf_m2.synthetic_payment_processing_event');p9=table_count(psql,conn,db,env,log,'msbf_m2.payment_event_reconciliation_snapshot');ps=table_count(psql,conn,db,env,log,'msbf_m2.payment_reconciliation_source_event');t8=table_count(psql,conn,db,env,log,'msbf_m2.account_lifecycle_transition_snapshot');ts=table_count(psql,conn,db,env,log,'msbf_m2.lifecycle_certification_source_transition')
        add('SOURCE_EVENT_COVERAGE',p8==p9==ps and t8==ts,f'm2.8_events={p8};source_events={ps};reconciled={p9};m2.8_transitions={t8};source_transitions={ts}')
        var=float(scalar(psql,conn,db,env,log,"SELECT coalesce(sum(abs(reconciliation_variance_amount))+sum(abs(exposure_variance_amount)),0)::text FROM msbf_m2.account_payment_reconciliation_snapshot;"));add('ZERO_RECONCILIATION_VARIANCE',var==0.0,var)
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE active_state_flag::int+closed_state_flag::int+review_hold_state_flag::int<>1 OR NOT state_certified_flag OR certified_exposure_amount<0 OR reconciliation_variance_amount<>0 OR exposure_variance_amount<>0 OR unresolved_exception_count<0;"));add('CERTIFICATION_STATE_INVARIANTS',invalid==0,invalid)
        returns=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.payment_event_reconciliation_snapshot WHERE event_reconciliation_status_code='RECONCILED_RETURN';"));exc=table_count(psql,conn,db,env,log,'msbf_m2.payment_exception_case_snapshot');add('EXCEPTION_EVENT_RECONCILIATION',returns==exc,f'returned_events={returns};exception_cases={exc}')
        transition_hash_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition t
          WHERE (
            t.transition_type_code IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')
            AND (
              t.related_payment_event_sequence IS NULL
              OR t.related_payment_event_row_hash IS NULL
              OR NOT EXISTS (
                SELECT 1 FROM msbf_m2.payment_reconciliation_source_event p
                WHERE p.module1_run_id=t.module1_run_id
                  AND p.scenario_id=t.scenario_id
                  AND p.merchant_application_id=t.merchant_application_id
                  AND p.event_sequence=t.related_payment_event_sequence
                  AND p.source_event_row_hash=t.related_payment_event_row_hash
              )
            )
          ) OR (
            t.transition_type_code NOT IN ('PAYMENT_PROCESSING_EVENT','PAYMENT_RETURN_EVENT','PAYMENT_RETRY_EVENT')
            AND (
              t.related_payment_event_sequence IS NOT NULL
              OR t.related_payment_instruction_id IS NOT NULL
              OR t.related_payment_event_row_hash IS NOT NULL
            )
          );"""))
        add('OPTIONAL_TRANSITION_PAYMENT_HASH_LINKAGE',transition_hash_mismatch==0,transition_hash_mismatch)
        resolved_hash_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot e
          WHERE e.exception_status_code='RESOLVED_BY_RETRY'
            AND (
              e.unresolved_exception_flag
              OR e.resolving_event_sequence IS NULL
              OR e.resolving_event_date IS NULL
              OR e.resolving_event_row_hash IS NULL
              OR NOT EXISTS (
                SELECT 1 FROM msbf_m2.payment_event_reconciliation_snapshot p
                WHERE p.module1_run_id=e.module1_run_id
                  AND p.scenario_id=e.scenario_id
                  AND p.merchant_application_id=e.merchant_application_id
                  AND p.event_sequence=e.resolving_event_sequence
                  AND p.row_hash=e.resolving_event_row_hash
              )
            );"""))
        add('OPTIONAL_EXCEPTION_RESOLUTION_HASH_LINKAGE',resolved_hash_mismatch==0,resolved_hash_mismatch)
    else:
        err=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE primary_portfolio_reason_code='M2_10_REASON_SOURCE_MAPPING_ERROR';"));add('NO_SOURCE_MAPPING_ERRORS',err==0,err)
        invalid=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest WHERE NOT ((performance_tier_code='CLOSED_STABLE' AND servicing_queue_code='NO_SERVICING_REQUIRED') OR (performance_tier_code='ACTIVE_RECONCILED' AND servicing_queue_code='ACTIVE_REASSESSMENT') OR (performance_tier_code='CONTROLLED_REVIEW' AND servicing_queue_code='GOVERNANCE_REVIEW_HOLD'));"));add('TIER_QUEUE_MAPPING',invalid==0,invalid)
        sc=table_count(psql,conn,db,env,log,'msbf_m2.portfolio_performance_scope_summary');kp=table_count(psql,conn,db,env,log,'msbf_m2.portfolio_kpi_snapshot');qu=table_count(psql,conn,db,env,log,'msbf_m2.servicing_queue_analytics_snapshot');qa=int(scalar(psql,conn,db,env,log,'SELECT coalesce(sum(account_count),0) FROM msbf_m2.servicing_queue_analytics_snapshot;'));all_scope=int(scalar(psql,conn,db,env,log,"SELECT account_count FROM msbf_m2.portfolio_performance_scope_summary WHERE scope_code='PORTFOLIO_ALL';"))
        add('ANALYTICS_SHAPE',sc==3 and kp==72 and qu==3 and qa==130 and all_scope==130,f'scopes={sc};kpi={kp};queues={qu};queue_accounts={qa};portfolio_accounts={all_scope}')
    return all(x['status']=='PASS' for x in checks),checks,{'hash_columns':hd,'boundary_flags':bd,'comparison':cd,'lineage':ld}

def legacy_registry_observation(psql,conn,db,env,log,m):
 raw=scalar(psql,conn,db,env,log,f"SELECT to_jsonb(r)::text FROM {m['legacy_registry']} r WHERE module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1);")
 return json.loads(raw) if raw else None

def policy_method_configuration(psql,conn,db,env,log,m):
    raw=scalar(psql,conn,db,env,log,f"SELECT to_jsonb(p)::text FROM {m['policy_profile']} p WHERE module1_run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1);")
    if not raw: raise RuntimeError(f"Missing policy profile row {m['policy_profile']}")
    obj=json.loads(raw)
    payload={}
    excluded={'configuration_hash','row_hash','created_at','updated_at',m['policy_source_hash_column']}
    for k,v in obj.items():
        if k in excluded or k.startswith('expected_') or k=='configuration_payload': continue
        payload[k]=v
    cfg=obj.get('configuration_payload')
    if isinstance(cfg,dict):
        cfg={k:v for k,v in cfg.items() if k not in ('expected','source_hash','source_combined_set_hash')}
        payload['configuration_payload_method']=cfg
    encoded=canon(payload)
    return {'payload':payload,'sha256':hash_text(encoded,'sha256'),'md5':hash_text(encoded,'md5'),'legacy_configuration_hash':obj.get('configuration_hash')}

def export_query_preflight(psql,conn,db,env,log,queries):
 out=[]
 for name,q in queries.items():
  cp=run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',f'SELECT count(*) FROM ({q}) z;'],env,log);out.append({'name':name,'rows':int(cp.stdout.strip()),'status':'PASS'})
 return out

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--source-db',default='msbf_r1_m2_4_r6_20260830_030634');ap.add_argument('--pg-bin',default=r'C:\Program Files\PostgreSQL\17\bin');ap.add_argument('--host',default='localhost');ap.add_argument('--port',default='5432');ap.add_argument('--user',default='postgres');args=ap.parse_args()
 pg=Path(args.pg_bin);psql=str(pg/'psql.exe');createdb=str(pg/'createdb.exe')
 for x in [psql,createdb]:
  if not Path(x).exists():raise SystemExit(f'Missing {x}')
 password=getpass.getpass('PostgreSQL password for local user postgres (not stored): ');env=os.environ.copy();env['PGPASSWORD']=password;env_ro=env.copy();env_ro['PGOPTIONS']='-c default_transaction_read_only=on';conn=['-h',args.host,'-p',str(args.port),'-U',args.user]
 stamp=datetime.now().strftime('%Y%m%d_%H%M%S');db=f'msbf_r1_wave_a_r3_{stamp}';out=HERE/'results'/db
 for d in ['logs','evidence','transformed_sources']:(out/d).mkdir(parents=True,exist_ok=True)
 log=out/'logs/WAVE_A_R3.log';receipt={'phase':'WAVE_A_R3','status':'RUNNING','source_db':args.source_db,'clone_db':db,'started_at_utc':datetime.now(timezone.utc).isoformat(),'accepted_authority_changed':False,'source_modified':False,'clone_created':False,'last_stage':'PREFLIGHT'};source_fp=None;exit_code=1
 try:
  for r in SRC_MAN:
   p=HERE/r['package_path']
   if sha256_file(p)!=r['sha256']:raise RuntimeError(f"Accepted source hash mismatch {r['package_path']}")
  static=static_transform_preflight();(out/'evidence/00_STATIC_TRANSFORM_AUDIT.json').write_text(json.dumps(static,indent=2),encoding='utf-8')
  cols=catalog_column_preflight(psql,conn,args.source_db,env_ro,log);with_open=out/'evidence/01_SOURCE_CONTROL_COLUMN_PREFLIGHT.csv'
  with with_open.open('w',newline='',encoding='utf-8') as f:w=csv.DictWriter(f,fieldnames=cols[0].keys());w.writeheader();w.writerows(cols)
  before=source_control(psql,conn,args.source_db,env_ro,log);validate_source_control(before);source_fp=control_fingerprint(before);receipt['source_control_before']=before;receipt['source_fingerprint_before']=source_fp
  reqs=list(csv.DictReader((HERE/'manifests/04_WAVE_A_SOURCE_PREFLIGHT_REQUIREMENTS.csv').open(encoding='utf-8')));rr=[]
  for r in reqs:
   ok=object_present(psql,conn,args.source_db,env_ro,log,r['object_name'],r['object_type']);rr.append({**r,'status':'PASS' if ok else 'FAIL'})
  with (out/'evidence/02_SOURCE_OBJECT_PREFLIGHT.csv').open('w',newline='',encoding='utf-8') as f:w=csv.DictWriter(f,fieldnames=rr[0].keys());w.writeheader();w.writerows(rr)
  if any(x['status']=='FAIL' for x in rr):raise RuntimeError('Wave A R3 source object preflight failed')
  data_dir=scalar(psql,conn,'postgres',env,log,'SHOW data_directory;');size=int(scalar(psql,conn,'postgres',env,log,f"SELECT pg_database_size('{args.source_db}');"));free=shutil.disk_usage(Path(data_dir)).free;need=int(size*1.35+3*1024**3);receipt['disk']={'data_directory':data_dir,'source_size_bytes':size,'free_bytes':free,'required_bytes':need}
  if free<need:raise RuntimeError(f'Insufficient disk: free={free} required={need}')
  receipt['last_stage']='CLONE';run([createdb,*conn,'-T',args.source_db,db],env,log);receipt['clone_created']=database_exists(psql,conn,env,log,db)
  if not receipt['clone_created']:raise RuntimeError('createdb returned success but clone absent')
  ctl_sql="""
  CREATE SCHEMA IF NOT EXISTS msbf_m12r1e;
  CREATE TABLE IF NOT EXISTS msbf_m12r1e.wave_a_stage_registry(
    stage_code text primary key,predecessor_stage_code text not null,predecessor_contract_hash text not null,
    output_contract_hash text not null,output_contract_sha256 text not null,output_evidence_hash text not null,output_evidence_sha256 text not null,
    accepted_schema_source_sha256 text not null,accepted_generation_source_sha256 text not null,transformed_schema_sha256 text not null,transformed_generation_sha256 text not null,
    policy_method_hash text not null,policy_method_payload jsonb not null,legacy_policy_configuration_hash text,contract_table_set_sha256 text not null,source_rows bigint not null,baseline_rows bigint not null,stress_rows bigint not null,
    actual_population_payload jsonb not null,legacy_registry_payload jsonb,legacy_registry_combined_hash text,legacy_registry_status text,
    contract_authority text not null,validation_status text not null,validated_at timestamptz not null default clock_timestamp());
  CREATE TABLE IF NOT EXISTS msbf_m12r1e.wave_a_validation_result(stage_code text not null,control_id text not null,status text not null,observed text,evaluated_at timestamptz not null default clock_timestamp(),primary key(stage_code,control_id));
  CREATE TABLE IF NOT EXISTS msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code text not null,evidence_payload jsonb not null,archived_at timestamptz not null default clock_timestamp());
  """;run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1'],env,log,input_text=ctl_sql)
  all_tables=[]
  for s in reversed(STAGES):all_tables+=META[s]['tables']
  drop='\n'.join(f'DROP TABLE IF EXISTS {t} CASCADE;' for t in all_tables)
  cleanup=drop+"\nINSERT INTO msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code,evidence_payload) SELECT split_part(evidence_code,'_',1)||'.'||split_part(evidence_code,'_',2),to_jsonb(e) FROM msbf_ctl.run_evidence e WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND evidence_code ~ '^M2_(5|6|7|8|9|10)_';\nDELETE FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND evidence_code ~ '^M2_(5|6|7|8|9|10)_';\nDELETE FROM msbf_ctl.acceptance_gate_result WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND gate_id ~ '^M2_(5|6|7|8|9|10)_';\nUPDATE msbf_ctl.run_registry SET run_status='M2_4_ACCEPTED' WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;"
  run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1'],env,log,input_text=cleanup)
  prior=before['m2_4_combined_set_hash'];all_checks=[];stage_receipts=[]
  for stage in STAGES:
   m=META[stage];srcs={r['source_class']:r for r in SRC_MAN if r['stage']==m['stage']};trans={}
   for cls in ['SCHEMA','GEN']:
    txt=(HERE/srcs[cls]['package_path']).read_text(encoding='utf-8');ot=transform(stage,cls,txt,prior);lexical_sql_check(ot);tp=out/'transformed_sources'/f"{m['stage'].replace('.','_')}_{cls}.sql";tp.write_text(ot,encoding='utf-8',newline='\n');trans[cls]=tp
   receipt['last_stage']=m['stage']+'_SCHEMA';run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-f',str(trans['SCHEMA'])],env,log)
   phys=physical_semantics_validate(psql,conn,db,env,log,m['stage'])
   support=support_semantics_validate(psql,conn,db,env,log,m['stage'])
   keys=key_semantics_validate(psql,conn,db,env,log,m['stage'])
   fks=foreign_key_semantics_validate(psql,conn,db,env,log,m['stage'])
   named=named_constraint_validate(psql,conn,db,env,log,m['stage'])
   schema_detail={'column_semantics_failures':phys,'support_objects':support,'keys':keys,'foreign_keys':fks,'named_constraints':named}
   (out/'evidence'/f"{m['stage'].replace('.','_')}_PHYSICAL_SCHEMA_VALIDATION.json").write_text(json.dumps(schema_detail,indent=2),encoding='utf-8')
   schema_fail=len(phys)+sum(x['status']!='PASS' for x in support+keys+fks+named)
   if schema_fail:raise RuntimeError(f"{m['stage']} physical schema validation failed for {schema_fail} controls")
   receipt['last_stage']=m['stage']+'_GENERATION';run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-f',str(trans['GEN'])],env,log)
   receipt['last_stage']=m['stage']+'_VALIDATION';ok,checks,detail=validate_stage(psql,conn,db,env,log,stage,m,prior);all_checks.extend(checks);(out/'evidence'/f"{m['stage'].replace('.','_')}_VALIDATION_DETAIL.json").write_text(json.dumps(detail,indent=2),encoding='utf-8')
   if not ok:raise RuntimeError(f"{m['stage']} successor checkpoint validation failed")
   all_table_summary=table_set_summary(psql,conn,db,env,log,m['tables'])
   contract_tables=[t for t in m['tables'] if t not in (m['policy_profile'],m['legacy_registry'])]
   contract_table_summary=table_set_summary(psql,conn,db,env,log,contract_tables)
   pop=stage_population_payload(psql,conn,db,env,log,stage,m);legacy=legacy_registry_observation(psql,conn,db,env,log,m);policy=policy_method_configuration(psql,conn,db,env,log,m);vhash=hash_text(canon(sorted(checks,key=lambda x:x['control_id'])),'sha256')
   payload={'stage':m['stage'],'predecessor_stage':m['prev'],'predecessor_contract_hash':prior,'accepted_schema_source_sha256':srcs['SCHEMA']['sha256'],'accepted_generation_source_sha256':srcs['GEN']['sha256'],'transformed_schema_sha256':sha256_file(trans['SCHEMA']),'transformed_generation_sha256':sha256_file(trans['GEN']),'policy_method_sha256':policy['sha256'],'contract_table_set_sha256':contract_table_summary['sha256'],'validation_sha256':vhash,'actual_population_payload':pop}
   cp=canon(payload);contract_sha=hash_text(cp,'sha256');contract_md5=hash_text(cp,'md5');evidence_md5=all_table_summary['md5'];legacy_hash=(legacy or {}).get('combined_set_hash');legacy_status=(legacy or {}).get('contract_status')
   vals={'stage_code':m['stage'],'predecessor_stage_code':m['prev'],'predecessor_contract_hash':prior,'output_contract_hash':contract_md5,'output_contract_sha256':contract_sha,'output_evidence_hash':evidence_md5,'output_evidence_sha256':all_table_summary['sha256'],'accepted_schema_source_sha256':srcs['SCHEMA']['sha256'],'accepted_generation_source_sha256':srcs['GEN']['sha256'],'transformed_schema_sha256':sha256_file(trans['SCHEMA']),'transformed_generation_sha256':sha256_file(trans['GEN']),'policy_method_hash':policy['sha256'],'policy_method_payload':canon(policy['payload']),'legacy_policy_configuration_hash':policy.get('legacy_configuration_hash'),'contract_table_set_sha256':contract_table_summary['sha256'],'source_rows':pop['table_counts'][m['source_table']],'baseline_rows':pop['baseline_source_rows'],'stress_rows':pop['stress_source_rows'],'actual_population_payload':canon(pop),'legacy_registry_payload':canon(legacy) if legacy else None,'legacy_registry_combined_hash':legacy_hash,'legacy_registry_status':legacy_status,'contract_authority':'SUCCESSOR_WAVE_A_R3','validation_status':'VALIDATED_CANDIDATE'}
   cols=list(vals);lits=[]
   for c in cols:
    v=vals[c]
    if v is None:lits.append('NULL')
    elif c in ('source_rows','baseline_rows','stress_rows'):lits.append(str(v))
    elif c in ('actual_population_payload','legacy_registry_payload','policy_method_payload'):lits.append("'"+v.replace("'","''")+"'::jsonb")
    else:lits.append("'"+str(v).replace("'","''")+"'")
   run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',f"INSERT INTO msbf_m12r1e.wave_a_stage_registry({','.join(cols)}) VALUES ({','.join(lits)});"],env,log)
   for c in checks:
    run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',"INSERT INTO msbf_m12r1e.wave_a_validation_result(stage_code,control_id,status,observed) VALUES ('"+c['stage']+"','"+c['control_id'].replace("'","''")+"','"+c['status']+"','"+c['observed'].replace("'","''")+"');"],env,log)
   run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',f"UPDATE msbf_m12r1e.downstream_rebase_status SET rebase_status='VALIDATED_CANDIDATE',successor_source_code='WAVE_A_R3_{m['stage'].replace('.','_')}_{contract_md5}',updated_at=clock_timestamp() WHERE stage_code='{m['stage'].replace('.', '_')}';"],env,log)
   prefix=m['stage'].replace('.','_');run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',f"INSERT INTO msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code,evidence_payload) SELECT '{m['stage']}',to_jsonb(e) FROM msbf_ctl.run_evidence e WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND evidence_code ~ '^{prefix}_'; DELETE FROM msbf_ctl.run_evidence WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1) AND evidence_code ~ '^{prefix}_';"],env,log)
   stage_receipts.append({**payload,'output_contract_hash':contract_md5,'output_contract_sha256':contract_sha,'legacy_registry_combined_hash':legacy_hash,'legacy_registry_status':legacy_status,'all_table_set':all_table_summary,'contract_table_set':contract_table_summary});prior=contract_md5
  receipt['last_stage']='FINAL_VALIDATION'
  if any(c['status']!='PASS' for c in all_checks):raise RuntimeError('One or more Wave A R3 controls failed')
  if table_count(psql,conn,db,env,log,'msbf_m12r1e.wave_a_stage_registry')!=6:raise RuntimeError('Wave A stage registry count mismatch')
  if scalar(psql,conn,db,env,log,"SELECT run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;")!='M2_10_GENERATED':raise RuntimeError('Final run status not M2_10_GENERATED')
  statuses=scalar(psql,conn,db,env,log,"SELECT count(*)||'|'||count(*) FILTER(WHERE rebase_status='VALIDATED_CANDIDATE')||'|'||count(*) FILTER(WHERE rebase_status='PENDING_REBASE') FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12');");
  if statuses!='8|6|2':raise RuntimeError('Downstream rebase status shape mismatch '+statuses)
  export_specs={'wave_a_stage_registry':'SELECT * FROM msbf_m12r1e.wave_a_stage_registry ORDER BY stage_code','wave_a_validation_result':'SELECT * FROM msbf_m12r1e.wave_a_validation_result ORDER BY stage_code,control_id','m2_5_power_bi':'SELECT * FROM msbf_m2.v_m2_5_power_bi_daily_monitoring ORDER BY scenario_id,merchant_application_id,monitoring_day_index','m2_6_power_bi':'SELECT * FROM msbf_m2.v_m2_6_power_bi_intervention_strategy ORDER BY scenario_id,merchant_application_id','m2_7_power_bi':'SELECT * FROM msbf_m2.v_m2_7_power_bi_operational_setup ORDER BY scenario_id,merchant_application_id','m2_8_power_bi':'SELECT * FROM msbf_m2.v_m2_8_power_bi_servicing_execution ORDER BY scenario_id,merchant_application_id','m2_9_power_bi':'SELECT * FROM msbf_m2.v_m2_9_power_bi_account_certification ORDER BY scenario_id,merchant_application_id','m2_10_power_bi':'SELECT * FROM msbf_m2.v_m2_10_power_bi_portfolio_analytics ORDER BY scenario_id,merchant_application_id','downstream_rebase_status':"SELECT * FROM msbf_m12r1e.downstream_rebase_status ORDER BY stage_code"}
  ep=export_query_preflight(psql,conn,db,env,log,export_specs);(out/'evidence/90_EXPORT_QUERY_PREFLIGHT.json').write_text(json.dumps(ep,indent=2),encoding='utf-8')
  for name,q in export_specs.items():
   target=(out/'evidence'/f'{name}.csv').as_posix().replace("'","''");run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',f"\\copy ({q}) TO '{target}' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8');"],env,log)
  with (out/'evidence/WAVE_A_R3_VALIDATION_RESULTS.csv').open('w',newline='',encoding='utf-8') as f:w=csv.DictWriter(f,fieldnames=['stage','control_id','status','observed']);w.writeheader();w.writerows(all_checks)
  (out/'evidence/WAVE_A_R3_STAGE_RECEIPTS.json').write_text(json.dumps(stage_receipts,indent=2),encoding='utf-8')
  after=source_control(psql,conn,args.source_db,env_ro,log);receipt['source_control_after']=after;receipt['source_fingerprint_after']=control_fingerprint(after);receipt['source_modified']=receipt['source_fingerprint_after']!=source_fp
  if receipt['source_modified']:raise RuntimeError('R6 source fingerprint changed')
  receipt.update({'status':'PASS','last_stage':'COMPLETE','wave_a_stage_count':6,'final_run_status':'M2_10_GENERATED','final_wave_a_contract_hash':prior,'finished_at_utc':datetime.now(timezone.utc).isoformat()});exit_code=0
 except Exception as e:
  receipt.update({'status':'FAIL','error':repr(e),'finished_at_utc':datetime.now(timezone.utc).isoformat()})
  try:
   if source_fp is not None:
    after=source_control(psql,conn,args.source_db,env_ro,log);receipt['source_control_after']=after;receipt['source_fingerprint_after']=control_fingerprint(after);receipt['source_modified']=receipt['source_fingerprint_after']!=source_fp
  except Exception as ee:receipt['source_recheck_error']=repr(ee)
 finally:
  receipt['clone_exists_at_exit']=database_exists(psql,conn,env,log,db) if receipt.get('clone_created') else False
  (out/'WAVE_A_R3_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
  zpath=HERE/'results'/f'{db}_WAVE_A_R3_RESULTS.zip';zpath.parent.mkdir(exist_ok=True)
  with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED) as z:
   for p in out.rglob('*'):
    if p.is_file():z.write(p,p.relative_to(out))
  h=sha256_file(zpath);Path(str(zpath)+'.sha256').write_text(f'{h}  {zpath.name}\n',encoding='utf-8')
  env.pop('PGPASSWORD',None);env_ro.pop('PGPASSWORD',None);password=None
  print('\nWave A R3 M2.5-M2.10 finished:',receipt['status']);print('R6 source modified:',receipt.get('source_modified'));print('Clone created:',receipt.get('clone_created'));print('Clone retained:',db if receipt.get('clone_exists_at_exit') else 'NO');print('Last stage:',receipt.get('last_stage'));print('Results:',zpath);print('SHA-256:',h)
  if receipt['status']!='PASS':print('Failure:',receipt.get('error'))
 return exit_code

if __name__=='__main__':raise SystemExit(main())
