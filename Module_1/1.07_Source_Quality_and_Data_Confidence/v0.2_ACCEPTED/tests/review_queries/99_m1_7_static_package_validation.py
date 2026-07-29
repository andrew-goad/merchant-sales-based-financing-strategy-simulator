#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import csv, json, re, hashlib, sys
from collections import defaultdict

ROOT=Path(__file__).resolve().parents[1]
SQL_FILES=sorted((ROOT/'sql').glob('*.sql'))+sorted((ROOT/'tests').glob('*.sql'))
SQL_FILES=[p for p in SQL_FILES if p.name!='99_m1_7_static_package_validation.py']
CATALOG=ROOT/'catalogs'/'M1_7_PHYSICAL_DEPENDENCY_COLUMNS.csv'
errors=[]; warnings=[]; metrics={}

def lexical_scan(text:str):
    state='normal'; tag=None; paren=0; line=1; i=0; found=[]
    while i<len(text):
        ch=text[i]; nxt=text[i+1] if i+1<len(text) else ''
        if ch=='\n': line+=1
        if state=='normal':
            if ch=="'": state='single'
            elif ch=='"': state='double'
            elif ch=='-' and nxt=='-': state='line'; i+=1
            elif ch=='/' and nxt=='*': state='block'; i+=1
            elif ch=='$':
                m=re.match(r'\$[A-Za-z_][A-Za-z0-9_]*\$|\$\$',text[i:])
                if m: tag=m.group(0); state='dollar'; i+=len(tag)-1
            elif ch=='(': paren+=1
            elif ch==')':
                paren-=1
                if paren<0: found.append(f'line {line}: extra closing parenthesis'); paren=0
        elif state=='single':
            if ch=="'":
                if nxt=="'": i+=1
                else: state='normal'
        elif state=='double':
            if ch=='"':
                if nxt=='"': i+=1
                else: state='normal'
        elif state=='line':
            if ch=='\n': state='normal'
        elif state=='block':
            if ch=='*' and nxt=='/': state='normal'; i+=1
        elif state=='dollar':
            if text.startswith(tag,i): i+=len(tag)-1; state='normal'; tag=None
        i+=1
    if state not in ('normal','line'): found.append(f'unclosed lexical state: {state} {tag or ""}'.strip())
    if paren: found.append(f'parenthesis balance: {paren}')
    return found

# Physical catalog
with CATALOG.open(newline='',encoding='utf-8') as f:
    dep_rows=list(csv.DictReader(f))
cols=defaultdict(set)
for r in dep_rows: cols[(r['schema_name'],r['table_name'])].add(r['column_name'])

all_text='\n'.join(p.read_text(encoding='utf-8') for p in SQL_FILES)
metrics['sql_files']=len(SQL_FILES)
metrics['sql_source_lines']=sum(len(p.read_text(encoding='utf-8').splitlines()) for p in SQL_FILES)
metrics['positive_codes']=len(set(re.findall(r'M1_7_POS_\d{2}_[A-Z0-9_]+',all_text)))
metrics['negative_codes']=len(set(re.findall(r'M1_7_NEG_\d{2}_[A-Z0-9_]+',all_text)))
metrics['helper_functions']=len(set(re.findall(r'CREATE OR REPLACE FUNCTION\s+(msbf_m1\.m1_7_[A-Za-z0-9_]+)',all_text,re.I)))
metrics['dependency_tables']=len(cols)
metrics['dependency_columns']=len(dep_rows)

if metrics['sql_files']!=8: errors.append(f'Expected 8 SQL files including contingency; found {metrics["sql_files"]}.')
if metrics['positive_codes']!=55: errors.append(f'Expected 55 positive codes; found {metrics["positive_codes"]}.')
if metrics['negative_codes']!=5: errors.append(f'Expected 5 negative codes; found {metrics["negative_codes"]}.')
if metrics['helper_functions']!=4: errors.append(f'Expected 4 M1.7 helper/guard functions; found {metrics["helper_functions"]}.')

for p in SQL_FILES:
    text=p.read_text(encoding='utf-8')
    for issue in lexical_scan(text): errors.append(f'{p.name}: {issue}')
    if re.search(r'(?<!deterministic_)\brandom\s*\(',text,re.I): errors.append(f'{p.name}: prohibited session random() call.')
    if re.search(r'\b(?:TRUNCATE|DROP\s+TABLE|DELETE\s+FROM\s+msbf_m1\.)',text,re.I): errors.append(f'{p.name}: destructive M1 business-table operation detected.')
    if re.search(r'CREATE\s+TEMP(?:ORARY)?\s+TABLE\s+\w+\s*\([^;]*\b(?:text|integer|bigint|numeric|date|boolean)\b[^;]*\)\s+ON\s+COMMIT\s+DROP\s+AS',text,re.I|re.S):
        errors.append(f'{p.name}: typed column definitions used with CREATE TABLE AS.')
    if 'CONTRACT_READY' in text and 'CONTRACT_READY_PRE_GENERATION' not in text:
        errors.append(f'{p.name}: stale source readiness status detected.')
    if 'channel_code' in text:
        errors.append(f'{p.name}: nonexistent partner_channel.channel_code reference detected.')

# DML target columns
for p in SQL_FILES:
    text=p.read_text(encoding='utf-8')
    for m in re.finditer(r'\bINSERT\s+INTO\s+(msbf_\w+)\.(\w+)\s*\((.*?)\)\s*(?:VALUES|SELECT|WITH)',text,re.I|re.S):
        key=(m.group(1),m.group(2)); raw=m.group(3)
        if key not in cols: continue
        depth=0; cur=''; names=[]
        for ch in raw:
            if ch=='(': depth+=1
            elif ch==')': depth-=1
            if ch==',' and depth==0: names.append(cur.strip().strip('"'));cur=''
            else: cur+=ch
        if cur.strip(): names.append(cur.strip().strip('"'))
        bad=[x for x in names if x not in cols[key]]
        if bad: errors.append(f'{p.name}: invalid INSERT columns for {key[0]}.{key[1]}: {bad}')

# Performance protections
wide_calls=['m1_4_daily_pos_blueprint','m1_5_daily_liquidity_blueprint','m1_6_pos_scenario_blueprint','m1_6_deposit_scenario_blueprint']
for name in ['47_msbf_m1_7_source_quality_data_confidence_validation_v0_2.sql','48_msbf_m1_7_negative_control_tests_v0_2.sql','49_msbf_m1_7_acceptance_finalize_v0_2.sql','50_MSBF_M1_7_Source_Quality_Data_Confidence_Master_Report_v0_2.sql','51_MSBF_M1_7_Source_Quality_Data_Confidence_Detail_Report_v0_2.sql']:
    p=next((x for x in SQL_FILES if x.name==name),None)
    if p:
        txt=p.read_text()
        for call in wide_calls:
            if call in txt: errors.append(f'{name}: prohibited wide blueprint regeneration call {call}.')

gen=(ROOT/'sql'/'46_msbf_m1_7_source_quality_data_confidence_generation_v0_2.sql').read_text()
for required in ["SET LOCAL jit=off","SET LOCAL statement_timeout='15min'","ANALYZE msbf_m1.source_snapshot","M1.7 Phase 1/5","M1.7 Phase 5/5","CONTRACT_READY_PRE_GENERATION"]:
    if required not in gen: errors.append(f'Generation missing required control: {required}')

val=(ROOT/'sql'/'47_msbf_m1_7_source_quality_data_confidence_validation_v0_2.sql').read_text()
if not val.strip().endswith('ORDER BY evidence_code;'): errors.append('Validation does not end with persisted evidence query.')
detail=(ROOT/'tests'/'51_MSBF_M1_7_Source_Quality_Data_Confidence_Detail_Report_v0_2.sql').read_text().strip()
if not detail.startswith('/*') or '\nBEGIN;' not in detail or not detail.endswith('COMMIT;'): errors.append('Detail report transaction boundary is incomplete.')
if len(re.findall(r'^--\s+\d+\.',detail,re.M))!=15: errors.append('Detail report does not expose exactly 15 numbered result sets.')

# JSON/CSV/catalog checks
for p in (ROOT/'catalogs').glob('*.json'):
    try: json.loads(p.read_text())
    except Exception as e: errors.append(f'{p.name}: JSON parse error: {e}')
for p in (ROOT/'catalogs').glob('*.csv'):
    try:
        with p.open(newline='',encoding='utf-8') as f: list(csv.reader(f))
    except Exception as e: errors.append(f'{p.name}: CSV parse error: {e}')

# Markdown relative links
for p in ROOT.rglob('*.md'):
    text=p.read_text(encoding='utf-8')
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)',text):
        if '://' in target or target.startswith('#'): continue
        t=(p.parent/target).resolve()
        if not t.exists(): errors.append(f'{p.relative_to(ROOT)}: broken link {target}')

# Unfinished markers outside acceptance template
for p in ROOT.rglob('*'):
    if not p.is_file() or 'templates' in p.parts or p.suffix.lower() not in {'.md','.sql','.json','.csv','.txt'}: continue
    txt=p.read_text(encoding='utf-8',errors='ignore')
    if re.search(r'\b(?:TODO|FIXME|TBD)\b',txt): warnings.append(f'{p.relative_to(ROOT)}: unfinished marker.')

result={'version':'v0.2','status':'PASS' if not errors else 'FAIL','metrics':metrics,'errors':errors,'warnings':warnings}
(ROOT/'catalogs'/'M1_7_STATIC_VALIDATION.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
sys.exit(1 if errors else 0)
