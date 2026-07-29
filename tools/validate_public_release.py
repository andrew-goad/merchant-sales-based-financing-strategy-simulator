#!/usr/bin/env python3
from pathlib import Path
import hashlib, csv, json, re, sys
root=Path(__file__).resolve().parents[1]
errors=[]
# unresolved placeholders
for p in root.rglob('*'):
    if p.is_file() and p.suffix.lower() in {'.md','.json','.txt','.sql','.csv','.yml','.yaml'}:
        try: t=p.read_text(encoding='utf-8')
        except Exception: continue
        if re.search(r'\{\{[^}]+\}\}',t): errors.append(f'Unresolved placeholder: {p.relative_to(root)}')
        if '/tmp/' in t or 'C:\\Users\\' in t: errors.append(f'Local path leakage: {p.relative_to(root)}')
# markdown links
link_re=re.compile(r'\[[^\]]*\]\(([^)]+)\)')
for p in root.rglob('*.md'):
    text=p.read_text(encoding='utf-8')
    for target in link_re.findall(text):
        if target.startswith(('http://','https://','#','mailto:')): continue
        target=target.split('#',1)[0]
        if not target: continue
        q=(p.parent/target).resolve()
        try: q.relative_to(root.resolve())
        except Exception: errors.append(f'Link escapes repository: {p.relative_to(root)} -> {target}'); continue
        if not q.exists(): errors.append(f'Broken link: {p.relative_to(root)} -> {target}')
# manifest verification, if present
m=root/'MANIFEST.csv'
if m.exists():
    with m.open(newline='',encoding='utf-8') as f:
        for r in csv.DictReader(f):
            p=root/r['path']
            if not p.is_file(): errors.append(f'Manifest missing file: {r["path"]}'); continue
            h=hashlib.sha256(p.read_bytes()).hexdigest()
            if h!=r['sha256']: errors.append(f'Manifest hash mismatch: {r["path"]}')
if errors:
    print('\n'.join(errors)); sys.exit(1)
print('Public release validation PASS')
