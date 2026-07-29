from __future__ import annotations
import json,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
errors=[]; warnings=[]

def balanced(text):
    # Lightweight lexical balance: comments/strings/dollar bodies are removed
    # before parentheses are counted.
    t=re.sub(r'/\*.*?\*/','',text,flags=re.S)
    t=re.sub(r'--[^\n]*','',t)
    t=re.sub(r'\$([A-Za-z0-9_]*)\$.*?\$\1\$','',t,flags=re.S)
    t=re.sub(r"'(?:''|[^'])*'",'',t)
    return t.count('(')==t.count(')')

sqls=sorted(list((ROOT/'sql').glob('*.sql')) + list((ROOT/'tests').glob('*.sql')))
for p in sqls:
    txt=p.read_text(encoding='utf-8')
    if not balanced(txt): errors.append(f'unbalanced SQL delimiters: {p.relative_to(ROOT)}')
    if re.search(r'\brandom\s*\(',txt,re.I): errors.append(f'session random() call: {p.relative_to(ROOT)}')
    if re.search(r'\b(TRUNCATE|DELETE\s+FROM)\s+msbf_m1\.',txt,re.I): errors.append(f'destructive accepted-table operation: {p.relative_to(ROOT)}')
    if any(re.search(r'md5\s*\(.*\)\s*FILTER\s*\(', line, re.I) for line in txt.splitlines()): errors.append(f'scalar md5 FILTER defect: {p.relative_to(ROOT)}')
    if re.search(r'to_jsonb\(msbf_m1\.',txt,re.I): errors.append(f'unsafe schema-qualified whole-row hash reference: {p.relative_to(ROOT)}')
    if re.search(r'\bSELECT\s+msbf_m1\.m1_13_assert_generation_ready\s*\(',txt,re.I): errors.append(f'generation guard emits an unnecessary result set: {p.relative_to(ROOT)}')

v=(ROOT/'sql/95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql').read_text()
if len(set(re.findall(r"'M1_13_POS_\d{2}_[A-Z0-9_]+'",v)))!=82: errors.append('positive control inventory is not 82')
n=(ROOT/'sql/96_msbf_m1_13_negative_control_tests_v0_2R1.sql').read_text()
if len(set(re.findall(r"'M1_13_NEG_\d{2}_[A-Z0-9_]+'",n)))!=7: errors.append('negative control inventory is not 7')
d=(ROOT/'tests/99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql').read_text()
if len(re.findall(r'/\*\s*\d{2}\s+—',d))!=20: errors.append('detail report inventory is not 20')
if 'ON COMMIT PRESERVE ROWS' not in v or 'ON COMMIT PRESERVE ROWS' not in n or 'ON COMMIT PRESERVE ROWS' not in d: errors.append('filterable result-table design missing')
if re.search(r'SELECT\s+pg_temp\.m1_13_add_check',v,re.I): errors.append('validation helper called with standalone SELECT')
if 'resolution_error_id' not in d or re.search(r'ORDER BY\s+error_id\b',d,re.I): errors.append('blocking-error report primary key defect')
if re.search(r'\ba\.relationship_stage\b',d,re.I): errors.append('detail report reads relationship_stage from merchant_application')
if 'application_integrated_risk_proxy_snapshot r' not in d: errors.append('detail report is missing accepted risk-snapshot relationship/size lineage')
if (ROOT/'sql/94_msbf_m1_13_exposure_recovery_expected_loss_generation_v0_2.sql').exists(): errors.append('stale duplicate generation file present')
if re.search(r"coalesce\(\((?:PASS|APPROVED|M1_13_GENERATED|[0-9a-f]{32})\)::text",v): errors.append('unquoted validation display literal')
dep=(ROOT/'catalogs/M1_13_PHYSICAL_DEPENDENCY_COLUMNS.csv').read_text()
if re.search(r'^msbf_m1\.source_snapshot,scenario_id,',dep,re.M): errors.append('invalid source_snapshot scenario_id dependency')
g=(ROOT/'sql/94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql').read_text()
if 'WHEN b.path_day >= b.requested_expected_payoff_days THEN 0.0::numeric' not in g: errors.append('terminal exposure hard-zero safeguard missing')
if g.count("round(\n                w.schedule_loss_amount / w.requested_total_repayment_amount,\n                8\n            )::numeric(12,8)") < 3: errors.append('persisted loss-rate routing basis missing')
design=(ROOT/'docs/M1_13_DESIGN_AND_GENERATION_SPECIFICATION.md').read_text()
field_dict=(ROOT/'catalogs/M1_13_FIELD_DICTIONARY.csv').read_text()
if 'ending exposure multiplied by daily default-timing weight' not in design.lower(): errors.append('design specification does not match ending-exposure EAD implementation')
if 'Ending exposure multiplied by daily timing weight.' not in field_dict: errors.append('field dictionary does not match ending-exposure EAD implementation')

result={'status':'PASS' if not errors else 'FAIL','sql_files_checked':len(sqls),'errors':errors,'warnings':warnings}
print(json.dumps(result,indent=2))
sys.exit(0 if not errors else 1)
