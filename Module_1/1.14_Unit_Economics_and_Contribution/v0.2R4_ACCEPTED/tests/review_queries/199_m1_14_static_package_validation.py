#!/usr/bin/env python3
"""Static package validation for MSBF M1.14 v0.2.

This validator does not replace live PostgreSQL execution. It checks source
inventory, SQL lexical balance, control counts, physical-column counts, known
prior-defect patterns, DML target shapes, documentation/catalog parseability,
and package boundaries.
"""
from pathlib import Path
import csv, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
SQL_FILES = sorted((ROOT/'sql').glob('*.sql')) + sorted((ROOT/'tests').glob('*.sql'))

def strip_sql(text):
    out=[]; i=0; n=len(text); single=False; double=False; line=False; block=0; dollar=None
    while i<n:
        if line:
            if text[i]=='\n': line=False; out.append('\n')
            i+=1; continue
        if block:
            if text.startswith('/*',i): block+=1; i+=2; continue
            if text.startswith('*/',i): block-=1; i+=2; continue
            i+=1; continue
        if dollar:
            if text.startswith(dollar,i): out.append(dollar); i+=len(dollar); dollar=None
            else: out.append(text[i]); i+=1
            continue
        if not single and not double and text.startswith('--',i): line=True; i+=2; continue
        if not single and not double and text.startswith('/*',i): block=1; i+=2; continue
        if not single and not double and text[i]=='$':
            m=re.match(r'\$[A-Za-z_0-9]*\$',text[i:])
            if m: dollar=m.group(0); out.append(dollar); i+=len(dollar); continue
        ch=text[i]
        if ch=="'" and not double:
            if single and i+1<n and text[i+1]=="'": out.extend([ch,text[i+1]]); i+=2; continue
            single=not single
        elif ch=='"' and not single: double=not double
        out.append(ch); i+=1
    return ''.join(out), {'single':single,'double':double,'line':line,'block':block,'dollar':dollar}

def balanced(text):
    clean,state=strip_sql(text)
    if state['single'] or state['double'] or state['block'] or state['dollar']:
        return False,'unclosed quote/comment/dollar block'
    depth=0
    for ch in clean:
        if ch=='(': depth+=1
        elif ch==')':
            depth-=1
            if depth<0: return False,'negative parenthesis depth'
    return depth==0,f'final parenthesis depth={depth}'

def table_columns(schema,table):
    marker=f'CREATE TABLE IF NOT EXISTS msbf_m1.{table} ('
    start=schema.index(marker)+len(marker); i=start; depth=1; single=double=False
    while i<len(schema):
        ch=schema[i]
        if ch=="'" and not double:
            if single and i+1<len(schema) and schema[i+1]=="'": i+=2; continue
            single=not single
        elif ch=='"' and not single: double=not double
        elif not single and not double:
            if ch=='(': depth+=1
            elif ch==')':
                depth-=1
                if depth==0: body=schema[start:i]; break
        i+=1
    items=[]; cur=[]; dep=0; single=double=False; i=0
    while i<len(body):
        ch=body[i]
        if ch=="'" and not double:
            if single and i+1<len(body) and body[i+1]=="'": cur.extend([ch,body[i+1]]); i+=2; continue
            single=not single
        elif ch=='"' and not single: double=not double
        elif not single and not double:
            if ch=='(': dep+=1
            elif ch==')': dep-=1
            elif ch==',' and dep==0:
                items.append(''.join(cur).strip()); cur=[]; i+=1; continue
        cur.append(ch); i+=1
    if ''.join(cur).strip(): items.append(''.join(cur).strip())
    return [x for x in items if x and not x.upper().startswith('CONSTRAINT ')]

errors=[]; warnings=[]; metrics={}
metrics['sql_files']=len(SQL_FILES)
metrics['sql_source_lines']=sum(len(p.read_text(encoding='utf-8').splitlines()) for p in SQL_FILES)
for p in SQL_FILES:
    ok,msg=balanced(p.read_text(encoding='utf-8'))
    if not ok: errors.append(f'{p.relative_to(ROOT)}: {msg}')

all_sql='\n'.join(p.read_text(encoding='utf-8') for p in SQL_FILES)
metrics['positive_controls']=len(set(re.findall(r'M1_14_POS_\d{2}_[A-Z0-9_]+',all_sql)))
metrics['negative_controls']=len(set(re.findall(r'M1_14_NEG_\d{2}',all_sql)))
metrics['detail_result_sets']=len(re.findall(r'/\*\s*\d{2}\s+—', (ROOT/'tests/107_MSBF_M1_14_Unit_Economics_Detail_Report_v0_2.sql').read_text(encoding='utf-8')))
if metrics['positive_controls']!=82: errors.append(f"positive controls={metrics['positive_controls']} expected 82")
if metrics['negative_controls']!=7: errors.append(f"negative controls={metrics['negative_controls']} expected 7")
if metrics['detail_result_sets']!=20: errors.append(f"detail result sets={metrics['detail_result_sets']} expected 20")

schema=(ROOT/'sql/100_msbf_m1_14_schema_policy_extension_v0_2.sql').read_text(encoding='utf-8')
metrics['snapshot_columns']=len(table_columns(schema,'application_unit_economics_snapshot'))
metrics['component_columns']=len(table_columns(schema,'unit_economics_component_value'))
if metrics['snapshot_columns']!=74: errors.append(f"snapshot columns={metrics['snapshot_columns']} expected 74")
if metrics['component_columns']!=14: errors.append(f"component columns={metrics['component_columns']} expected 14")

patterns={
 'session_random':r'(?<![A-Za-z_])random\s*\(',
 'max_boolean':r'\bmax\s*\(\s*\([^)]*\)::boolean\s*\)',
 'scalar_md5_filter':r'md5\s*\(\s*string_agg\s*\([^;]*?\)\s*\)\s*FILTER\s*\(',
 'destructive_business_delete':r'DELETE\s+FROM\s+msbf_m1\.(application_unit_economics_snapshot|unit_economics_component_value)',
 'unbounded_expected_update':r'UPDATE\s+_m1_14_(snapshot|component)_expected\s+[A-Za-z_]*\s*SET[^;]+;(?!\s*--)',
 'standalone_helper_select':r'SELECT\s+pg_temp\.m1_14_add_check\s*\(',
 'unsafe_whole_row_hash':r'to_jsonb\s*\(\s*(?![A-Za-z_][A-Za-z0-9_]*\s*\))',
}
for name,pat in patterns.items():
    count=len(re.findall(pat,all_sql,re.I|re.S))
    metrics[name]=count
# The unbounded-update regex is intentionally conservative; verify actual bounded forms directly.
if metrics['session_random']: errors.append('session-level random() call detected')
if metrics['max_boolean']: errors.append('unsupported max(boolean) pattern detected')
if metrics['scalar_md5_filter']: errors.append('scalar md5 FILTER syntax pattern detected')
if metrics['destructive_business_delete']: errors.append('destructive M1.14 business DELETE detected')
if metrics['standalone_helper_select']: errors.append('standalone validation helper SELECT detected')

for result_file in [ROOT/'sql/103_msbf_m1_14_unit_economics_validation_v0_2.sql', ROOT/'sql/104_msbf_m1_14_negative_control_tests_v0_2.sql', ROOT/'tests/107_MSBF_M1_14_Unit_Economics_Detail_Report_v0_2.sql']:
    txt=result_file.read_text(encoding='utf-8')
    if 'ON COMMIT PRESERVE ROWS' not in txt:
        errors.append(f'{result_file.name}: session-preserved output missing')

# Ensure hash updates are bounded and expected created_at is initialized.
gen=(ROOT/'sql/102_msbf_m1_14_unit_economics_generation_v0_2.sql').read_text(encoding='utf-8')
for needle in [
    'WHERE e.row_hash IS NULL;',
    'WHERE c.calculation_hash IS NULL;',
    'SET created_at=clock_timestamp()\nWHERE created_at IS NULL;',
    'ANALYZE msbf_m1.application_unit_economics_snapshot;',
    'ANALYZE msbf_m1.unit_economics_component_value;']:
    if needle not in gen: errors.append(f'generation safeguard missing: {needle}')

# Parseability of catalogs.
for p in sorted((ROOT/'catalogs').glob('*.json')):
    try: json.loads(p.read_text(encoding='utf-8'))
    except Exception as e: errors.append(f'{p.name}: invalid JSON: {e}')
for p in sorted((ROOT/'catalogs').glob('*.csv')):
    try:
        with p.open(encoding='utf-8',newline='') as f: list(csv.reader(f))
    except Exception as e: errors.append(f'{p.name}: invalid CSV: {e}')

required=[
 'README.md','RELEASE_NOTES.md','PROJECT_STATUS.md','PACKAGE_METADATA.json',
 'docs/M1_14_ARCHITECTURE.md','docs/M1_14_DESIGN_AND_GENERATION_SPECIFICATION.md',
 'docs/M1_14_PARAMETER_DICTIONARY.md','docs/M1_14_VALIDATION_MATRIX.md',
 'docs/M1_14_EXECUTION_AND_VALIDATION_GUIDE.md','diagrams/M1_14_ARCHITECTURE.png',
 'diagrams/M1_14_ARCHITECTURE.svg','evidence/README.md']
for rel in required:
    if not (ROOT/rel).exists(): errors.append(f'missing required file: {rel}')

result={'status':'PASS' if not errors else 'FAIL','metrics':metrics,'errors':errors,'warnings':warnings}
(ROOT/'catalogs/M1_14_STATIC_VALIDATION.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
sys.exit(0 if not errors else 1)
