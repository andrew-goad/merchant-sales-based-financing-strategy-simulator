#!/usr/bin/env python3
from pathlib import Path
from urllib.parse import unquote
import csv, hashlib, json, re, sys
root=Path(__file__).resolve().parents[1]
errors=[]
exclude_roots={'.git'}
manifest_authorities={'MANIFEST.csv','manifest.json','SHA256SUMS.txt','PACKAGE_INVENTORY.csv'}

def governed_files():
    out=[]
    for p in root.rglob('*'):
        if not p.is_file(): continue
        rel=p.relative_to(root)
        if rel.parts and rel.parts[0] in exclude_roots: continue
        if rel.as_posix() in manifest_authorities: continue
        out.append(p)
    return out

# Parse structured files.
for p in governed_files():
    rel=p.relative_to(root)
    try:
        if p.suffix.lower()=='.json': json.loads(p.read_text(encoding='utf-8-sig'))
        elif p.suffix.lower()=='.jsonl':
            for i,line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(),1):
                if line.strip(): json.loads(line)
        elif p.suffix.lower()=='.csv':
            with p.open(encoding='utf-8-sig',newline='') as f: list(csv.reader(f))
    except Exception as e: errors.append(f'Parse failure: {rel}: {e}')

# Placeholders/local-path/secret residue in public text.
secret_patterns=[r'(?i)\bsk-[A-Za-z0-9_-]{12,}\b',r'(?i)\bghp_[A-Za-z0-9]{20,}\b',r'(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b']
for p in governed_files():
    if p.suffix.lower() not in {'.md','.json','.jsonl','.txt','.sql','.csv','.yml','.yaml'}: continue
    try: t=p.read_text(encoding='utf-8-sig')
    except Exception: continue
    rel=p.relative_to(root)
    if not (len(rel.parts)>=2 and rel.parts[0]=='docs' and rel.parts[1]=='project_history') and re.search(r'\{\{[^}]+\}\}',t): errors.append(f'Unresolved placeholder: {rel}')
    if '/mnt/data/' in t or '/home/oai/' in t or re.search(r'(?i)C:\\Users\\',t): errors.append(f'Local/session path leakage: {rel}')
    if '"content_type":"thoughts"' in t or '"content_type": "thoughts"' in t: errors.append(f'Internal reasoning record published: {rel}')
    for pat in secret_patterns:
        if re.search(pat,t): errors.append(f'Credential-like string: {rel}')

# Markdown relative links.
link_re=re.compile(r'(?<!!)\[[^\]]*\]\(([^)]+)\)')
for p in root.rglob('*.md'):
    if '.git' in p.relative_to(root).parts: continue
    text=p.read_text(encoding='utf-8-sig')
    for target in link_re.findall(text):
        target=target.strip().strip('<>')
        if target.startswith(('http://','https://','#','mailto:','sandbox:')): continue
        target=unquote(target.split('#',1)[0])
        if not target: continue
        q=(p.parent/target).resolve()
        try: q.relative_to(root.resolve())
        except Exception: errors.append(f'Link escapes repository: {p.relative_to(root)} -> {target}'); continue
        if not q.exists(): errors.append(f'Broken link: {p.relative_to(root)} -> {target}')

# Manifest exact set and hashes.
with (root/'MANIFEST.csv').open(newline='',encoding='utf-8') as f:
    rows=list(csv.DictReader(f))
manifest_paths={r['path'] for r in rows}
physical_paths={p.relative_to(root).as_posix() for p in governed_files()}
for path in sorted(manifest_paths-physical_paths): errors.append(f'Manifest extra path: {path}')
for path in sorted(physical_paths-manifest_paths): errors.append(f'Manifest missing path: {path}')
for r in rows:
    p=root/r['path']
    if p.is_file():
        h=hashlib.sha256(p.read_bytes()).hexdigest()
        if h!=r['sha256']: errors.append(f'Manifest hash mismatch: {r["path"]}')
        if p.stat().st_size!=int(r['size_bytes']): errors.append(f'Manifest size mismatch: {r["path"]}')

# Expected release surfaces.
required=[
 'Module_2/README.md',
 'docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png',
 'docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio_v2.pdf',
 'docs/campaign_scale/README.md',
 'docs/campaign_scale/CAMPAIGN_SCALE_GOVERNANCE_BOUNDARY.md',
 'docs/project_history/chatgpt_logs_through_2026-08-12/README.md',
 'docs/project_history/chatgpt_logs_through_2026-08-12/CONVERSATION_INDEX.csv',
]
for rel in required:
    if not (root/rel).is_file(): errors.append(f'Required publication artifact missing: {rel}')
# 12 Module 2 stage roots.
stage_roots=[p for p in (root/'Module_2').iterdir() if p.is_dir() and re.match(r'2\.\d{2}_',p.name)]
if len(stage_roots)!=12: errors.append(f'Module 2 stage folder count: expected 12, observed {len(stage_roots)}')

if errors:
    print('Public release validation FAIL')
    print('\n'.join(f'- {e}' for e in errors))
    sys.exit(1)
print('Public release validation PASS')
print(f'Governed manifest files: {len(rows)}')
print(f'Module 2 stage folders: {len(stage_roots)}')
