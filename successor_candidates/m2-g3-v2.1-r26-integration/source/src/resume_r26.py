#!/usr/bin/env python3
from __future__ import annotations
import argparse, csv, getpass, hashlib, io, json, os, shutil, sys, traceback, zipfile
from pathlib import Path
from datetime import datetime, timezone

import run_r26 as r26
import wave_a_engine_r17 as wave
from common import PgTools, PgContext, canonical_hash, sha256_bytes, sha256_file, write_json

ROOT=Path(__file__).resolve().parents[1]
R2_RESULT=ROOT/'inputs'/'msbf_r1_r26_20260902_024119_M2_5_M2_12_G3V2_RESULTS.zip'
EXPECTED_R2_SHA='f140d5f51d464b379dc218902f1b61844914a86207665b4ff0699aab8bbe4329'
EXPECTED_RETAINED_FINAL='msbf_r1_r26_g3v2_20260902_024119'
BUILD_ID='MSBF_R26_R3_RETAINED_FINAL_IDENTITY_CORRECTION_G3V2_RESUME'


def utcnow(): return datetime.now(timezone.utc).isoformat()
def stamp(): return datetime.now().strftime('%Y%m%d_%H%M%S')
def canon(x): return json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=True)
def hobj(x): return hashlib.sha256(canon(x).encode()).hexdigest()

def read_r2_json(member):
    with zipfile.ZipFile(R2_RESULT) as z:
        return json.loads(z.read(member).decode('utf-8'))

def read_r2_bytes(member):
    with zipfile.ZipFile(R2_RESULT) as z: return z.read(member)

def compare_wave_exports_to_r2(exports, outdir:Path):
    checks=[]
    for name,meta in exports.items():
        actual=(outdir/f'{name}.csv').read_bytes()
        expected=read_r2_bytes(f'evidence/final/wave_a_exports/{name}.csv')
        checks.append({'member':name,'status':'PASS' if actual==expected else 'FAIL',
                       'actual_sha256':sha256_bytes(actual),'expected_sha256':sha256_bytes(expected),
                       'actual_bytes':len(actual),'expected_bytes':len(expected)})
    status='PASS' if all(x['status']=='PASS' for x in checks) else 'FAIL'
    return {'status':status,'checks':checks}

def list_r26_databases(pg:PgContext, db:str):
    b=pg.copy_to_csv(db,"SELECT datname FROM pg_database WHERE datname LIKE 'msbf_r1_r26_%' ORDER BY datname")
    rows=list(csv.DictReader(io.StringIO(b.decode('utf-8-sig'))))
    return [r['datname'] for r in rows]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--source-db',default='msbf_r1_m2_4_r6_20260830_030634')
    ap.add_argument('--retained-final-db',default=EXPECTED_RETAINED_FINAL)
    ap.add_argument('--pg-bin',default=r'C:\Program Files\PostgreSQL\17\bin')
    ap.add_argument('--host',default='localhost');ap.add_argument('--port',type=int,default=5432);ap.add_argument('--user',default='postgres')
    args=ap.parse_args()
    if args.retained_final_db!=EXPECTED_RETAINED_FINAL:
        raise SystemExit('Retained-final DB name must remain exact: '+EXPECTED_RETAINED_FINAL)
    if sha256_file(R2_RESULT)!=EXPECTED_R2_SHA: raise SystemExit('Embedded R2 result SHA-256 mismatch')
    offline=r26.r2_failure_reperformance()
    if offline['status']!='PASS': raise SystemExit('Embedded R2 canonicalization re-performance did not PASS')
    expected_sim=offline['compiler']['simulation_identity']
    expected_source_root=offline['compiler']['source_root_sha256']
    runstamp=stamp();resume=f'msbf_r1_r26_resume_g3v2_{runstamp}'
    work=ROOT/'results'/f'msbf_r1_r26_resume_{runstamp}_WORK';work.mkdir(parents=True)
    ev=work/'evidence';ev.mkdir();(work/'logs').mkdir();scratch=work/'scratch';scratch.mkdir()
    write_json(ev/'00_R2_CANONICALIZATION_REPERFORMANCE.json',offline)
    receipt={'runtime_id':BUILD_ID,'status':'RUNNING','started_at_utc':utcnow(),'last_stage':'INITIALIZE',
             'source_db':args.source_db,'retained_r2_final_db':args.retained_final_db,'resume_db':resume,
             'retained_r2_final_modified':None,'source_modified':None,'resume_retained':False,
             'policy_sha256':r26.r26_policy.POLICY_SHA256,'r2_result_sha256':EXPECTED_R2_SHA,
             'resume_boundary':'M2.11_M2.12_G3V2_ONLY','failure':None}
    log=work/'logs'/'R26_RESUME.log';origout,origerr=sys.stdout,sys.stderr
    class Tee:
        def __init__(self,*fs): self.fs=fs
        def write(self,s):
            for f in self.fs:f.write(s);f.flush()
        def flush(self):
            for f in self.fs:f.flush()
    pg=None;before_r6=None;before_r6_schema=None;before_final_id=None
    with log.open('w',encoding='utf-8',newline='\n') as lf:
      sys.stdout=Tee(origout,lf);sys.stderr=Tee(origerr,lf)
      try:
        print(BUILD_ID+' starting',flush=True)
        tools=PgTools.from_bin(Path(args.pg_bin));env=os.environ.copy()
        if not env.get('PGPASSWORD'): env['PGPASSWORD']=getpass.getpass(f'PostgreSQL password for local user {args.user} (not stored): ')
        pg=PgContext(tools,args.host,args.port,args.user,env);conn=['-h',args.host,'-p',str(args.port),'-U',args.user];env_ro={**env,'PGOPTIONS':'-c default_transaction_read_only=on'}
        receipt['last_stage']='SOURCE_AND_RETAINED_FINAL_PREFLIGHT'
        if not pg.db_exists(args.source_db): raise RuntimeError('Immutable R6 source database not found: '+args.source_db)
        if not pg.db_exists(args.retained_final_db): raise RuntimeError('Required retained R2 final database not found: '+args.retained_final_db)
        before_r6=wave.source_control(str(tools.psql),conn,args.source_db,env_ro,log);wave.validate_source_control(before_r6)
        before_r6_schema=r26.schema_fp(pg,args.source_db,scratch)
        expected_final_id=read_r2_json('evidence/final/WAVE_A_DATABASE_IDENTITY.json')
        before_final_id=wave.stable_database_identity(str(tools.psql),conn,args.retained_final_db,env_ro,log)
        if before_final_id!=expected_final_id: raise RuntimeError('Retained R2 final Wave A database identity mismatch')
        expected_ctrl=read_r2_json('evidence/final/R26_POLICY_CONTROLS.json')
        actual_ctrl={'status':'PASS','controls':r26.r26_controls(pg,args.retained_final_db)}
        if actual_ctrl!=expected_ctrl: raise RuntimeError('Retained R2 final R26 policy controls mismatch')
        schema_count=int(pg.scalar(args.retained_final_db,"SELECT count(*) FROM information_schema.schemata WHERE schema_name='msbf_r1_g3v2_r26'",read_only=True))
        if schema_count!=0: raise RuntimeError('Retained R2 final unexpectedly contains R26 G3 schema; resume boundary is not clean')
        source_exports=r26.export_wave_a_csvs(pg,args.retained_final_db,ev/'retained_final_wave_a_exports')
        export_compare=compare_wave_exports_to_r2(source_exports,ev/'retained_final_wave_a_exports');write_json(ev/'01_RETAINED_FINAL_EXACT_PREFLIGHT.json',{
          'database_identity_exact':True,'policy_controls_exact':True,'g3_schema_absent':True,'wave_a_exports':export_compare,
          'observed_r26_databases':list_r26_databases(pg,args.source_db)})
        if export_compare['status']!='PASS': raise RuntimeError('Retained R2 final Wave A exports are not byte-exact to R2 failure evidence')
        receipt['last_stage']='RESUME_CLONE'
        clone=pg.clone_database(args.retained_final_db,resume,scratch);receipt['resume_retained']=True;write_json(ev/'02_RESUME_CLONE.json',clone)
        resume_id=wave.stable_database_identity(str(tools.psql),conn,resume,env_ro,log)
        if resume_id!=expected_final_id: raise RuntimeError('Resume clone Wave A identity differs from retained R2 final')
        resume_exports=r26.export_wave_a_csvs(pg,resume,ev/'resume_wave_a_exports')
        resume_compare=compare_wave_exports_to_r2(resume_exports,ev/'resume_wave_a_exports');write_json(ev/'03_RESUME_CLONE_WAVE_A_IDENTITY.json',{'database_identity_exact':True,'wave_a_exports':resume_compare})
        if resume_compare['status']!='PASS': raise RuntimeError('Resume clone Wave A exports differ from R2 final evidence')
        receipt['last_stage']='RESUME_M2_11_M2_12_G3V2'
        g3=r26.build_g3(pg,resume,resume_exports,ev/'resume_wave_a_exports',ev/'resume_g3',expected_sim=expected_sim)
        if g3['source_root_sha256']!=expected_source_root: raise RuntimeError('Resume M2.11 source root mismatch after canonicalization')
        if g3['simulation_identity']!=expected_sim: raise RuntimeError('Resume M2.11 simulation identity mismatch after canonicalization')
        if g3['identity']['master']['certification_status']!='PASS' or g3['identity']['master']['control_count']!=70 or g3['identity']['master']['pass_count']!=70:
            raise RuntimeError('Resume G3-v2 certification is not 70/70 PASS')
        write_json(ev/'04_RESUME_G3_IDENTITY.json',g3)
        # Source and retained-final nonmutation.
        receipt['last_stage']='NONMUTATION'
        after_r6=wave.source_control(str(tools.psql),conn,args.source_db,env_ro,log);after_r6_schema=r26.schema_fp(pg,args.source_db,scratch)
        after_final_id=wave.stable_database_identity(str(tools.psql),conn,args.retained_final_db,env_ro,log)
        retained_exports_post=r26.export_wave_a_csvs(pg,args.retained_final_db,ev/'retained_final_post_wave_a_exports')
        retained_compare_post=compare_wave_exports_to_r2(retained_exports_post,ev/'retained_final_post_wave_a_exports')
        nonmutation={'r6_source_control_exact':before_r6==after_r6,'r6_schema_exact':before_r6_schema['normalized_schema_sha256']==after_r6_schema['normalized_schema_sha256'],
                     'retained_final_wave_a_identity_exact':before_final_id==after_final_id==expected_final_id,
                     'retained_final_exports_exact':retained_compare_post['status']=='PASS'}
        nonmutation['status']='PASS' if all(nonmutation[k] for k in nonmutation if k!='status') else 'FAIL';write_json(ev/'05_NONMUTATION.json',nonmutation)
        if nonmutation['status']!='PASS': raise RuntimeError('R6 or retained R2 final changed during resume')
        receipt.update({'status':'PASS','last_stage':'COMPLETE','completed_at_utc':utcnow(),'source_modified':False,'retained_r2_final_modified':False,
                        'resume_retained':True,'resume_database':resume,'wave_a_reexecution_performed':False,'m2_11_m2_12_resume_performed':True,
                        'm2_11_source_root_sha256':g3['source_root_sha256'],'m2_11_simulation_bundle_sha256':g3['simulation_identity']['bundle_sha256'],
                        'g3v2_certification_id':g3['identity']['master']['certification_id'],'g3v2_status':'PASS','g3v2_controls':'70/70',
                        'candidate_evaluations':52152,'application_simulations':12000,'account_simulations':1040,
                        'authority_state':'CANDIDATE_ONLY_PENDING_FOCUSED_INDEPENDENT_AUDIT','publication_state':'NOT_AUTHORIZED'})
      except Exception as ex:
        receipt.update({'status':'FAIL','completed_at_utc':utcnow(),'failure':repr(ex),'traceback':traceback.format_exc()});print('FAILURE: '+repr(ex));traceback.print_exc()
        if pg:
          try: receipt['resume_retained']=pg.db_exists(resume)
          except: pass
        try:
          if pg and before_r6 is not None:
            ac=wave.source_control(str(pg.tools.psql),['-h',args.host,'-p',str(args.port),'-U',args.user],args.source_db,{**pg.env,'PGOPTIONS':'-c default_transaction_read_only=on'},log);asch=r26.schema_fp(pg,args.source_db,scratch)
            receipt['source_modified']=not(before_r6==ac and before_r6_schema['normalized_schema_sha256']==asch['normalized_schema_sha256'])
            afi=wave.stable_database_identity(str(pg.tools.psql),['-h',args.host,'-p',str(args.port),'-U',args.user],args.retained_final_db,{**pg.env,'PGOPTIONS':'-c default_transaction_read_only=on'},log)
            receipt['retained_r2_final_modified']=not(before_final_id==afi) if before_final_id is not None else None
        except Exception as px: receipt['failure_nonmutation_probe_error']=repr(px)
      finally:
        write_json(work/'R26_RESUME_RECEIPT.json',receipt);shutil.rmtree(scratch,ignore_errors=True);sys.stdout,sys.stderr=origout,origerr
    out=ROOT/'results'/f'msbf_r1_r26_resume_{runstamp}_M2_11_M2_12_G3V2_RESULTS.zip';sh=r26.deterministic_zip(work,out);Path(str(out)+'.sha256').write_text(f'{sh}  {out.name}\n',encoding='ascii')
    print(f'R26 retained-final resume finished: {receipt["status"]}')
    print(f'R6 source modified: {receipt.get("source_modified")}')
    print(f'Retained R2 final modified: {receipt.get("retained_r2_final_modified")}')
    print(f'Resume clone retained: {resume if receipt.get("resume_retained") else "NO"}')
    print(f'Last stage: {receipt.get("last_stage")}')
    print(f'Results: {out}')
    print(f'SHA-256: {sh}')
    if receipt['status']!='PASS': print(f'Failure: {receipt.get("failure")}');return 1
    return 0

if __name__=='__main__': raise SystemExit(main())
