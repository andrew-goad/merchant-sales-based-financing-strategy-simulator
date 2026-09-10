#!/usr/bin/env python3
from __future__ import annotations
import ast,csv,hashlib,json,os,re,sys,zipfile
sys.dont_write_bytecode=True
from pathlib import Path,PurePosixPath

ROOT=Path(__file__).resolve().parents[1]
EXPECTED={
 'inputs/PHASE2C_R4_STRATEGY.zip':'1377e860629109fa9b19b479becc50e8a0d99cf55f1c760299de4203df6238d6',
 'inputs/msbf_r1_wave_a_r17_20260831_061333_WAVE_A_R17_RESULTS.zip':'eee512f19d30e189f811abc788b33ae0495ed1161be50c3061d5dc81f06b13be',
 'inputs/msbf_r1_wave_b_r19_20260831_113044_M2_11_M2_12_G3V2_RESULTS.zip':'44bff672753b6fa4d62bcb64e52270656774b27cb9c98a0017c5cc117e62f29c',
 'inputs/MSBF_M2_5_REPLAY_EXPECTED_PATH_SENSITIVITY_R1_20260901.zip':'c4a30635c45744771036372cd870f487b6099e5c287db905134f19621ad7d36b',
 'inputs/MSBF_M2_5_BUSINESS_REALISM_DISCRIMINATION_R1_20260901.zip':'5c844df42226d3c6ec0fa689fc1e5e7298fc6877a460589126b91ced430451b1',
 'inputs/msbf_r1_r26_20260902_024119_M2_5_M2_12_G3V2_RESULTS.zip':'f140d5f51d464b379dc218902f1b61844914a86207665b4ff0699aab8bbe4329',
}
REQUIRED=[
 'RUN_R26.ps1','00_START_HERE.md','PACKAGE_MANIFEST.csv',
 'src/run_r26.py','src/r26_policy.py','src/validate_package.py','src/wave_a_engine_r17.py','src/wave_b_engine_r19.py',
 'src/R19_M2_11_M2_12_G3V2_DDL.sql','config/R26_RUNTIME_CONTRACT.json','config/R26_POLICY_CONTRACT.json',
 'docs/61_R26_OPERATOR_GUIDE.md','docs/62_R26_POLICY_AND_AUTHORITY_BOUNDARY.md',
 'docs/63_R26_R1_LAUNCHER_FAILURE_AND_R2_CORRECTION.md','evidence/05_R26_R1_LAUNCHER_FAILURE_ADJUDICATION.json',
 'docs/64_R26_R2_M2_11_IDENTITY_FAILURE_AND_R3_CORRECTION.md','evidence/06_R26_R2_M2_11_IDENTITY_FAILURE_ADJUDICATION.json','evidence/07_R26_R2_CANONICALIZATION_REPERFORMANCE.json'
]
INVALID_WIN=re.compile(r'[<>:"/\\|?*]')
RESERVED={*(f'COM{i}' for i in range(1,10)),*(f'LPT{i}' for i in range(1,10)),'CON','PRN','AUX','NUL'}

def sha(path:Path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()

def safe_zip(path:Path):
 count=0; max_member=0
 with zipfile.ZipFile(path) as z:
  bad=z.testzip()
  if bad: raise RuntimeError(f'ZIP CRC failure {path.name}: {bad}')
  for i in z.infolist():
   n=i.filename.replace('\\','/')
   p=PurePosixPath(n)
   if p.is_absolute() or '..' in p.parts or re.match(r'^[A-Za-z]:',n):raise RuntimeError(f'Unsafe nested ZIP member {path.name}: {n}')
   if '\\' in i.filename:raise RuntimeError(f'Backslash ZIP member {path.name}: {i.filename}')
   max_member=max(max_member,len(n));count+=1
 return count,max_member

def main():
 errors=[];checks=[]
 def add(cid,ok,obs=None):
  checks.append({'control_id':cid,'status':'PASS' if ok else 'FAIL','observed':obs})
  if not ok:errors.append(f'{cid}: {obs}')
 for rel in REQUIRED:add('REQUIRED_'+rel.replace('/','_'),(ROOT/rel).is_file(),rel)
 # Manifest controls.
 mf=ROOT/'PACKAGE_MANIFEST.csv'
 if mf.is_file():
  rows=list(csv.DictReader(mf.open(encoding='utf-8-sig',newline='')))
  listed={r['path'] for r in rows}
  actual={p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.is_file() and p.name!='PACKAGE_MANIFEST.csv' and '__pycache__' not in p.parts and not p.relative_to(ROOT).as_posix().startswith('results/')}
  add('MANIFEST_PATH_SET_EXACT',listed==actual,{'listed':len(listed),'actual':len(actual),'missing':sorted(actual-listed)[:10],'extra':sorted(listed-actual)[:10]})
  bad=[]
  for r in rows:
   p=ROOT/r['path']
   if not p.is_file() or int(r['bytes'])!=p.stat().st_size or r['sha256']!=sha(p):bad.append(r['path'])
  add('MANIFEST_HASH_SIZE_EXACT',not bad,bad[:10])
 else: rows=[]
 # Exact evidence identities and sidecars.
 for rel,exp in EXPECTED.items():
  p=ROOT/rel;actual=sha(p) if p.is_file() else None
  add('INPUT_SHA_'+Path(rel).stem,actual==exp,actual)
  side=Path(str(p)+'.sha256')
  add('INPUT_SIDECAR_'+Path(rel).stem,side.is_file() and exp in side.read_text(encoding='utf-8-sig'),side.name)
 # Nested ZIP structure / CRC.
 zip_counts={};max_nested=0
 for p in sorted(ROOT.rglob('*.zip')):
  if p.relative_to(ROOT).as_posix().startswith('results/'):continue
  try:
   c,m=safe_zip(p);zip_counts[p.relative_to(ROOT).as_posix()]=c;max_nested=max(max_nested,m)
  except Exception as e:errors.append(str(e))
 add('NESTED_ZIP_CRC_AND_PATHS',not any('ZIP' in e for e in errors),zip_counts)
 # Package cleanliness before imports.
 add('NO_PYC_OR_PYCACHE',not any('__pycache__' in p.parts or p.suffix=='.pyc' for p in ROOT.rglob('*')),None)
 # Python syntax.
 pybad=[]
 for p in ROOT.rglob('*.py'):
  if '__pycache__' in p.parts:continue
  try:ast.parse(p.read_text(encoding='utf-8-sig'),filename=str(p))
  except Exception as e:pybad.append(f'{p.relative_to(ROOT)}:{e}')
 add('PYTHON_AST_ALL_PASS',not pybad,pybad)
 # Import static preflight without PostgreSQL execution.
 try:
  sys.path.insert(0,str(ROOT/'src'));import run_r26
  orig=run_r26.patch_wave_engine();sp=run_r26.static_preflight(orig)
  add('R26_STATIC_PREFLIGHT',sp['status']=='PASS' and all(x['status']=='PASS' for x in sp['policy_controls']),{'transforms':len(sp['transforms']),'policy_controls':len(sp['policy_controls']),'policy_sha256':run_r26.r26_policy.POLICY_SHA256})
  rr=run_r26.r2_failure_reperformance();stored=json.loads((ROOT/'evidence/07_R26_R2_CANONICALIZATION_REPERFORMANCE.json').read_text());add('R26_R2_FAILURE_CANONICALIZATION_REPERFORMANCE',rr.get('status')=='PASS' and rr==stored,rr)
 except Exception as e:add('R26_STATIC_PREFLIGHT',False,repr(e))
 # PowerShell boundary / encoding.
 ps=ROOT/'RUN_R26.ps1'
 if ps.is_file():
  b=ps.read_bytes();txt=b.decode('utf-8-sig')
  add('POWERSHELL_UTF8_BOM',b.startswith(b'\xef\xbb\xbf'),'UTF8_BOM' if b.startswith(b'\xef\xbb\xbf') else 'MISSING')
  add('POWERSHELL_CRLF',b'\r\n' in b and b.replace(b'\r\n',b'').find(b'\n')<0,'CRLF_ONLY')
  anchors=['validate_package.py','PGPASSWORD','run_r26.py','Do not rerun R17 or R19','MSBF R26 R3']
  add('POWERSHELL_REQUIRED_ANCHORS',all(a in txt for a in anchors),anchors)
  # PowerShell interprets `$name:` as a scoped-variable reference. Only explicit
  # PowerShell scope prefixes are allowed to use this syntax. This control
  # catches the exact R1 parser-failure class before an operator receives a ZIP.
  allowed_scopes={'env','global','local','private','script','using','variable','function','alias'}
  ambiguous=[]
  for lineno,line in enumerate(txt.splitlines(),1):
   for m in re.finditer(r'\$([A-Za-z_][A-Za-z0-9_]*):',line):
    if m.group(1).lower() not in allowed_scopes:
     ambiguous.append({'line':lineno,'token':m.group(0),'text':line.strip()})
  add('POWERSHELL_VARIABLE_COLON_REFERENCES_SAFE',not ambiguous,ambiguous[:10])
 # Windows native path/name checks.
 badnames=[];case={};coll=[];max_abs=0;max_path=''
 for p in ROOT.rglob('*'):
  rel=p.relative_to(ROOT).as_posix()
  if '__pycache__' in p.parts:continue
  abswin='C:\\MSBF\\R26_R3\\'+rel.replace('/','\\')
  if len(abswin)>max_abs:max_abs=len(abswin);max_path=abswin
  key=rel.lower()
  if key in case and case[key]!=rel:coll.append([case[key],rel])
  case[key]=rel
  for part in p.relative_to(ROOT).parts:
   stem=part.split('.')[0].upper()
   if INVALID_WIN.search(part) or part.endswith((' ','.')) or stem in RESERVED:badnames.append(rel);break
 add('WINDOWS_INVALID_NAMES_ZERO',not badnames,badnames[:10])
 add('WINDOWS_CASE_COLLISIONS_ZERO',not coll,coll[:10])
 add('WINDOWS_MAX_ABSOLUTE_PATH_LE_240',max_abs<=240,{'length':max_abs,'path':max_path})
 # Runtime contracts.

 try:
  pc=json.loads((ROOT/'config/R26_POLICY_CONTRACT.json').read_text())
  rc=json.loads((ROOT/'config/R26_RUNTIME_CONTRACT.json').read_text())
  import r26_policy
  add('POLICY_CONTRACT_SHA_EXACT',pc.get('policy_sha256')==r26_policy.POLICY_SHA256,pc.get('policy_sha256'))
  add('RUNTIME_SOURCE_DB_EXACT',rc.get('immutable_source_database')=='msbf_r1_m2_4_r6_20260830_030634',rc.get('immutable_source_database'))
  add('RUNTIME_OPERATOR_PACKAGE_REVISION_R3',rc.get('operator_package_revision')=='R3',rc.get('operator_package_revision'))
 except Exception as e:add('CONTRACT_PARSE',False,repr(e))
 status='PASS' if not errors and all(x['status']=='PASS' for x in checks) else 'FAIL'
 print(json.dumps({'status':status,'total':len(checks),'pass':sum(x['status']=='PASS' for x in checks),'fail':sum(x['status']=='FAIL' for x in checks),'manifest_rows':len(rows),'nested_zip_count':len(zip_counts),'max_nested_member_path':max_nested,'errors':errors,'checks':checks},indent=2))
 return 0 if status=='PASS' else 1
if __name__=='__main__':raise SystemExit(main())
