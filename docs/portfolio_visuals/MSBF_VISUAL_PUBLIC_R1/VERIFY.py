#!/usr/bin/env python3
"""Read-only exact inventory and SHA-256 verifier for a visual candidate root.
Usage: python VERIFY.py /path/to/extracted/root
No network, Git, extraction, deletion, engine or Power BI operation.
"""
from pathlib import Path, PurePosixPath
import hashlib,json,sys

def digest(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 return h.hexdigest()

def safe(s):
 if not isinstance(s,str) or not s or '\\' in s or ':' in s:raise ValueError('Unsafe manifest path')
 p=PurePosixPath(s)
 if p.is_absolute() or any(t in ('','..','.') for t in s.split('/')):raise ValueError('Unsafe manifest path: '+s)
 return s

def verify(root):
 root=Path(root).resolve();m=json.loads((root/'MANIFEST.json').read_text(encoding='utf8'))
 rows=m['files'];expected={};fold=set()
 for row in rows:
  n=safe(row['path'])
  if n.casefold() in fold:raise ValueError('Duplicate or case-colliding manifest path: '+n)
  fold.add(n.casefold());expected[n]=row
 if 'MANIFEST.json' in expected or 'SHA256SUMS.txt' in expected:raise ValueError('Invalid manifest self-inclusion')
 actual=set()
 for p in root.rglob('*'):
  if p.is_symlink():raise ValueError('Symlink not allowed: '+str(p))
  if p.is_file():actual.add(p.relative_to(root).as_posix())
 allowed=set(expected)|{'MANIFEST.json','SHA256SUMS.txt'}
 if actual!=allowed:raise ValueError('Inventory mismatch; missing='+str(sorted(allowed-actual))+'; unexpected='+str(sorted(actual-allowed)))
 for n,row in expected.items():
  p=root/n
  if p.stat().st_size!=row['bytes'] or digest(p)!=row['sha256']:raise ValueError('Size/hash mismatch: '+n)
 sums={}
 for line in (root/'SHA256SUMS.txt').read_text(encoding='utf8').splitlines():
  h,sep,n=line.partition('  ')
  if not sep or len(h)!=64:raise ValueError('Invalid checksum line')
  safe(n)
  if n in sums:raise ValueError('Duplicate checksum path')
  sums[n]=h
 if set(sums)!=set(expected)|{'MANIFEST.json'}:raise ValueError('Checksum inventory mismatch')
 for n,h in sums.items():
  if digest(root/n)!=h:raise ValueError('Checksum mismatch: '+n)
 return {'status':'PASS','payload_files':len(rows),'total_files':len(actual),'bytes':sum((root/n).stat().st_size for n in actual),'unexpected_files':0,'missing_files':0,'hash_mismatches':0,'scope':'Read-only local inventory/hash verification only; no Windows, viewer, engine or publication claim.'}

if __name__=='__main__':
 try:
  result=verify(Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).parent)
  print(json.dumps(result,indent=2))
 except Exception as exc:
  print('FAIL: '+str(exc),file=sys.stderr);sys.exit(1)
