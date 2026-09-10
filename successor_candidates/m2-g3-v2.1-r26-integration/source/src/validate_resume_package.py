#!/usr/bin/env python3
from pathlib import Path
import ast,csv,hashlib,json,re,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]
MAN=ROOT/'PACKAGE_MANIFEST.csv'
def sha(p):
 h=hashlib.sha256();
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()
def main():
 checks=[];errs=[]
 def add(cid,ok,obs=None):checks.append({'control_id':cid,'status':'PASS' if ok else 'FAIL','observed':obs});errs.extend([] if ok else [cid])
 req=['RUN_R26_RESUME.ps1','00_START_HERE.md','PACKAGE_MANIFEST.csv','src/resume_r26.py','src/run_r26.py','src/validate_resume_package.py','docs/65_R26_RETAINED_FINAL_RESUME_AND_FUTURE_RUNTIME_ARCHITECTURE.md','inputs/PHASE2C_R4_STRATEGY.zip','inputs/msbf_r1_r26_20260902_024119_M2_5_M2_12_G3V2_RESULTS.zip']
 for x in req:add('REQUIRED_'+x.replace('/','_'),(ROOT/x).is_file(),x)
 rows=list(csv.DictReader(MAN.open(newline='',encoding='utf-8-sig')))
 actual=sorted(p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.is_file() and p.name!='PACKAGE_MANIFEST.csv')
 listed=sorted(r['path'] for r in rows)
 add('MANIFEST_PATH_SET_EXACT',actual==listed,{'actual':len(actual),'listed':len(listed),'missing':sorted(set(listed)-set(actual)),'extra':sorted(set(actual)-set(listed))})
 bad=[]
 for r in rows:
  p=ROOT/r['path'];
  if not p.is_file() or sha(p)!=r['sha256'] or p.stat().st_size!=int(r['bytes']):bad.append(r['path'])
 add('MANIFEST_HASH_SIZE_EXACT',not bad,bad)
 # Embedded exact evidence.
 add('R2_RESULT_SHA_EXACT',sha(ROOT/'inputs/msbf_r1_r26_20260902_024119_M2_5_M2_12_G3V2_RESULTS.zip')=='f140d5f51d464b379dc218902f1b61844914a86207665b4ff0699aab8bbe4329')
 add('R4_SHA_EXACT',sha(ROOT/'inputs/PHASE2C_R4_STRATEGY.zip')=='1377e860629109fa9b19b479becc50e8a0d99cf55f1c760299de4203df6238d6')
 # Python syntax.
 pybad=[]
 for p in ROOT.rglob('*.py'):
  try:ast.parse(p.read_text(encoding='utf-8'))
  except Exception as e:pybad.append([p.relative_to(ROOT).as_posix(),repr(e)])
 add('PYTHON_AST_ALL_PASS',not pybad,pybad)
 ps=(ROOT/'RUN_R26_RESUME.ps1').read_bytes();add('POWERSHELL_UTF8_BOM',ps.startswith(b'\xef\xbb\xbf'));txt=ps.decode('utf-8-sig');add('POWERSHELL_CRLF',('\r\n' in txt and '\n' not in txt.replace('\r\n','')))
 unsafe=[m for m in re.findall(r'\$[A-Za-z_][A-Za-z0-9_]*:',txt) if m.lower() not in {'$env:','$global:','$script:','$local:','$private:'}];add('POWERSHELL_VARIABLE_COLON_REFERENCES_SAFE',not unsafe,unsafe)
 # ZIP integrity/path safety.
 zbad=[];zc=0
 for p in ROOT.rglob('*.zip'):
  zc+=1
  try:
   with zipfile.ZipFile(p) as z:
    if z.testzip():zbad.append([p.name,'CRC'])
    for n in z.namelist():
     q=Path(n)
     if q.is_absolute() or '..' in q.parts:zbad.append([p.name,n])
  except Exception as e:zbad.append([p.name,repr(e)])
 add('NESTED_ZIP_CRC_AND_PATHS',not zbad,{'count':zc,'errors':zbad})
 # Windows path/name sanity.
 reserved={'CON','PRN','AUX','NUL',*(f'COM{i}' for i in range(1,10)),*(f'LPT{i}' for i in range(1,10))};inv=[];seen={};coll=[];maxp=0;maxname=''
 for p in ROOT.rglob('*'):
  rel=p.relative_to(ROOT).as_posix();full='C:\\MSBF\\R26_R3_RESUME\\'+rel.replace('/','\\');
  if len(full)>maxp:maxp=len(full);maxname=full
  key=rel.lower();
  if key in seen and seen[key]!=rel:coll.append([seen[key],rel])
  seen[key]=rel
  for part in Path(rel).parts:
   stem=part.split('.')[0].upper()
   if stem in reserved or re.search(r'[<>:"|?*]',part) or part.endswith((' ','.')):inv.append(rel);break
 add('WINDOWS_INVALID_NAMES_ZERO',not inv,inv);add('WINDOWS_CASE_COLLISIONS_ZERO',not coll,coll);add('WINDOWS_MAX_ABSOLUTE_PATH_LE_240',maxp<=240,{'length':maxp,'path':maxname})
 status='PASS' if not errs else 'FAIL';print(json.dumps({'status':status,'total':len(checks),'pass':sum(c['status']=='PASS' for c in checks),'fail':sum(c['status']=='FAIL' for c in checks),'manifest_rows':len(rows),'nested_zip_count':zc,'errors':errs,'checks':checks},indent=2));return 0 if status=='PASS' else 1
if __name__=='__main__':raise SystemExit(main())
