#!/usr/bin/env python3
"""Static validation for the MSBF M1.3 v0.2 source package.

This is not a PostgreSQL parser or a substitute for live execution. It checks package
integrity, physical-column references in DML targets, deterministic controls, expected
evidence counts, documentation links, catalog parseability, and known prior defect classes.
"""
from __future__ import annotations
from pathlib import Path
import csv, json, re, hashlib, sys

ROOT=Path(__file__).resolve().parents[1]
SQL_FILES=sorted((ROOT/'sql').glob('*.sql'))+sorted((ROOT/'tests').glob('*.sql'))
SQL_FILES=[p for p in SQL_FILES if p.name!='99_m1_3_static_package_validation.py']
EXPECTED_SQL={
 '16_msbf_m1_3_failed_validation_recovery_check_v0_2R1.sql',
 '17_msbf_m1_3_preflight_validation_v0_2.sql',
 '18_msbf_m1_3_application_request_generation_v0_2.sql',
 '19_msbf_m1_3_application_validation_v0_2.sql',
 '20_msbf_m1_3_negative_control_tests_v0_2.sql',
 '21_msbf_m1_3_acceptance_finalize_v0_2.sql',
 '22_MSBF_M1_3_Application_Request_Master_Report_v0_2.sql',
 '23_MSBF_M1_3_Application_Request_Detail_Report_v0_2.sql',
}
EXPECTED_FUNCTIONS={
 'msbf_m1.m1_3_assert_generation_ready',
 'msbf_m1.m1_3_weighted_assignment',
 'msbf_m1.m1_3_weighted_assignment_json',
 'msbf_m1.m1_3_application_blueprint',
 'msbf_m1.m1_3_expected_application_snapshot',
 'msbf_m1.m1_3_actual_application_snapshot',
}

def strip_sql(text:str)->str:
    # Remove block and line comments, single-quoted strings, and dollar bodies for lexical checks.
    text=re.sub(r'/\*.*?\*/',' ',text,flags=re.S)
    text=re.sub(r'--[^\n]*',' ',text)
    text=re.sub(r"'(?:''|[^'])*'", "''", text)
    text=re.sub(r'\$[A-Za-z0-9_]*\$.*?\$[A-Za-z0-9_]*\$','$$',text,flags=re.S)
    return text

def balanced(text:str)->dict:
    cleaned=strip_sql(text)
    return {
      'parentheses': cleaned.count('(')==cleaned.count(')'),
      'begin_commit': len(re.findall(r'\bBEGIN\s*;',cleaned,re.I))==len(re.findall(r'\bCOMMIT\s*;',cleaned,re.I)),
    }

def physical_columns():
    p=ROOT/'catalogs'/'M1_3_PHYSICAL_DEPENDENCY_COLUMNS.csv'
    rows=list(csv.DictReader(p.open(encoding='utf-8')))
    m={}
    for r in rows:
        m.setdefault(f"{r['schema_name']}.{r['table_name']}",set()).add(r['column_name'])
    return rows,m

def dml_target_issues(sql:str, cols:dict)->list[dict]:
    issues=[]
    # INSERT INTO schema.table (columns)
    for m in re.finditer(r'INSERT\s+INTO\s+(msbf_(?:ctl|m1|ref)\.[A-Za-z0-9_]+)\s*\((.*?)\)\s*(?:VALUES|SELECT|WITH)',sql,re.I|re.S):
        table=m.group(1).lower(); raw=m.group(2)
        names=[x.strip().strip('"').lower() for x in raw.split(',') if x.strip()]
        if table in cols:
            bad=[n for n in names if n not in cols[table]]
            if bad: issues.append({'kind':'INSERT','table':table,'columns':bad})
    # UPDATE schema.table [alias] SET col=...
    for m in re.finditer(r'UPDATE\s+(msbf_(?:ctl|m1|ref)\.[A-Za-z0-9_]+)(?:\s+[A-Za-z_][A-Za-z0-9_]*)?\s+SET\s+(.*?)(?:\s+WHERE\s+|;)',sql,re.I|re.S):
        table=m.group(1).lower(); block=m.group(2)
        names=[]
        # split on commas only at shallow level
        depth=0; cur=''; parts=[]
        for ch in block:
            if ch=='(': depth+=1
            elif ch==')': depth=max(0,depth-1)
            if ch==',' and depth==0: parts.append(cur); cur=''
            else: cur+=ch
        parts.append(cur)
        for part in parts:
            mm=re.match(r'\s*(?:[A-Za-z_][A-Za-z0-9_]*\.)?([A-Za-z_][A-Za-z0-9_]*)\s*=',part)
            if mm: names.append(mm.group(1).lower())
        if table in cols:
            bad=[n for n in names if n not in cols[table]]
            if bad: issues.append({'kind':'UPDATE','table':table,'columns':bad})
    return issues

result={'package':'MSBF_M1_3_v0_2R1','checks':{},'issues':[]}

actual_names={p.name for p in SQL_FILES}
result['checks']['sql_file_set']={'status':'PASS' if actual_names==EXPECTED_SQL else 'FAIL','actual':sorted(actual_names),'expected':sorted(EXPECTED_SQL)}

all_sql='\n'.join(p.read_text(encoding='utf-8') for p in SQL_FILES)
created=set(re.findall(r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+(msbf_m1\.m1_3_[A-Za-z0-9_]+)',all_sql,re.I))
created={x.lower() for x in created}
result['checks']['function_set']={'status':'PASS' if created==EXPECTED_FUNCTIONS else 'FAIL','actual':sorted(created),'expected':sorted(EXPECTED_FUNCTIONS)}

lex=[]
for p in SQL_FILES:
    b=balanced(p.read_text(encoding='utf-8'))
    if not all(b.values()): lex.append({'file':p.name,**b})
result['checks']['sql_lexical_balance']={'status':'PASS' if not lex else 'FAIL','issues':lex}

# Known defect controls.
prohibited_random=[p.name for p in SQL_FILES if re.search(r'(?<!deterministic_)\brandom\s*\(',p.read_text(encoding='utf-8'),re.I)]
result['checks']['no_session_random']={'status':'PASS' if not prohibited_random else 'FAIL','files':prohibited_random}
root_extract=[p.name for p in SQL_FILES if "resolved_value #>> '{}'" in p.read_text(encoding='utf-8')]
result['checks']['structured_snapshot_accessors']={'status':'PASS' if not root_extract and "resolved_value->>'value_numeric'" in all_sql else 'FAIL','root_extraction_files':root_extract}

accepted_tables=['merchant_master','merchant_owner_guarantor','merchant_industry_assignment','processor_account','merchant_relationship_snapshot','merchant_application']
destruct=[]
for p in SQL_FILES:
    t=p.read_text(encoding='utf-8')
    for tab in accepted_tables:
        if re.search(rf'\b(?:TRUNCATE|DROP\s+TABLE|DELETE\s+FROM)\s+(?:msbf_m1\.)?{tab}\b',t,re.I):
            destruct.append({'file':p.name,'table':tab})
result['checks']['no_destructive_stage_operations']={'status':'PASS' if not destruct else 'FAIL','issues':destruct}

# Numeric-scale / canonical controls.
required_fragments=[
 "requested_funding_amount',f.funding_amount::numeric(18,2)",
 "requested_remittance_rate',f.remittance_rate::numeric(9,6)",
 "requested_total_repayment_amount',f.total_repayment_amount::numeric(18,2)",
 "requested_finance_charge_amount',f.finance_charge_amount::numeric(18,2)",
 "requested_funding_amount',a.requested_funding_amount::numeric(18,2)",
 "requested_remittance_rate',a.requested_remittance_rate::numeric(9,6)",
]
missing=[x for x in required_fragments if x not in all_sql]
result['checks']['canonical_numeric_scale']={'status':'PASS' if not missing else 'FAIL','missing_fragments':missing}

# Stage-specific design controls.
required_stage_terms=['MINIMUM_PRODUCT_AMOUNT_FLOOR','SALES_LINKED_REQUEST_REFERENCE','repayment_path_ratio','request_path_utilization_factor','minimum_amount_floor_override_flag']
missing=[x for x in required_stage_terms if x not in all_sql]
result['checks']['request_path_design_controls']={'status':'PASS' if not missing else 'FAIL','missing':missing}


# v0.2R1 relationship-stage validation-specification control.
validation_sql=(ROOT/'sql'/'19_msbf_m1_3_application_validation_v0_2.sql').read_text(encoding='utf-8')
relationship_block=validation_sql.split('/* 36 — relationship-stage request discipline',1)[1].split('/* 37 — horizon differentiation',1)[0]
relationship_ok=(
    'AVG(request_path_utilization_factor)' in relationship_block
    and 'raw_funding_to_sales' in relationship_block
    and 'returning_good_utilization>low_and_grow_utilization' in relationship_block
    and "AVG(funding_to_annualized_sales_rate) AS avg_rate" not in relationship_block
)
result['checks']['relationship_stage_validation_spec']={
    'status':'PASS' if relationship_ok else 'FAIL',
    'required':'direct utilization-factor control with raw funding-to-sales retained as diagnostic'
}

positive=sorted(set(re.findall(r"'(M1_3_POS_\d+_[A-Z0-9_]+)'",all_sql)))
negative=sorted(set(re.findall(r"'(M1_3_NEG_\d+_[A-Z0-9_]+)'",all_sql)))
result_sets=len(re.findall(r'/\*\s*Result set\s+\d+', (ROOT/'tests'/'23_MSBF_M1_3_Application_Request_Detail_Report_v0_2.sql').read_text(),re.I))
result['checks']['positive_evidence_count']={'status':'PASS' if len(positive)==42 else 'FAIL','count':len(positive),'codes':positive}
result['checks']['negative_control_count']={'status':'PASS' if len(negative)==3 else 'FAIL','count':len(negative),'codes':negative}
result['checks']['detail_result_set_count']={'status':'PASS' if result_sets==12 else 'FAIL','count':result_sets}

rows,cols=physical_columns()
dml=[]
for p in SQL_FILES:
    for issue in dml_target_issues(p.read_text(encoding='utf-8'),cols):
        issue['file']=p.name; dml.append(issue)
result['checks']['physical_dependency_catalog']={'status':'PASS' if len(rows)>0 else 'FAIL','rows':len(rows),'tables':len(cols)}
result['checks']['dml_target_columns']={'status':'PASS' if not dml else 'FAIL','issues':dml}

# Catalog parsing and exact weights.
parse_issues=[]
for p in sorted((ROOT/'catalogs').glob('*.json')):
    try: json.loads(p.read_text(encoding='utf-8'))
    except Exception as e: parse_issues.append({'file':p.name,'error':str(e)})
for p in sorted((ROOT/'catalogs').glob('*.csv')):
    try: list(csv.reader(p.open(encoding='utf-8')))
    except Exception as e: parse_issues.append({'file':p.name,'error':str(e)})
result['checks']['catalog_parseability']={'status':'PASS' if not parse_issues else 'FAIL','issues':parse_issues}

mix=list(csv.DictReader((ROOT/'catalogs'/'M1_3_GOVERNED_REQUEST_MIX_TARGETS.csv').open(encoding='utf-8')))
mix_summary={}
for fam in {r['mix_family'] for r in mix}:
    rr=[r for r in mix if r['mix_family']==fam]
    mix_summary[fam]={'weight_sum':sum(float(r['frozen_weight']) for r in rr),'count_sum':sum(int(r['exact_target_count']) for r in rr)}
mix_ok=all(abs(x['weight_sum']-1)<1e-12 and x['count_sum']==750 for x in mix_summary.values())
result['checks']['governed_mix_reconciliation']={'status':'PASS' if mix_ok else 'FAIL','summary':mix_summary}

# Documentation links.
link_issues=[]
mds=list(ROOT.glob('*.md'))+list((ROOT/'docs').glob('*.md'))+list((ROOT/'evidence').glob('*.md'))
for p in mds:
    text=p.read_text(encoding='utf-8')
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)',text):
        if target.startswith(('http://','https://','#','mailto:')): continue
        q=(p.parent/target).resolve()
        if not q.exists(): link_issues.append({'file':str(p.relative_to(ROOT)),'target':target})
result['checks']['internal_links']={'status':'PASS' if not link_issues else 'FAIL','issues':link_issues}

place=[]
for p in list(ROOT.rglob('*.md'))+list(ROOT.rglob('*.sql')):
    t=p.read_text(encoding='utf-8')
    if re.search(r'\b(?:TODO|FIXME|TBD)\b',t): place.append(str(p.relative_to(ROOT)))
result['checks']['no_unfinished_placeholders']={'status':'PASS' if not place else 'FAIL','files':place}

# Known generated-report duplicate-field control.
dup=[]
for p in SQL_FILES:
    lines=[x.strip() for x in p.read_text(encoding='utf-8').splitlines() if x.strip()]
    for a,b in zip(lines,lines[1:]):
        if a==b and re.search(r'\bAS\s+[A-Za-z_][A-Za-z0-9_]*',a,re.I):
            dup.append({'file':p.name,'line':a})
known_fragment="round(AVG(repayment_path_ratio),6) AS avg_repayment_path_ratio,\n       COUNT(*) FILTER (WHERE minimum_amount_floor_override_flag) AS minimum_floor_rows,\n       round(AVG(repayment_path_ratio),6) AS avg_repayment_path_ratio"
for p in SQL_FILES:
    if known_fragment in p.read_text(encoding='utf-8'):
        dup.append({'file':p.name,'line':'known duplicate repayment-path fields'})
result['checks']['no_known_duplicate_report_fields']={'status':'PASS' if not dup else 'FAIL','issues':dup}

failed=[k for k,v in result['checks'].items() if v['status']!='PASS']
result['overall_static_status']='PASS' if not failed else 'FAIL'
result['failed_checks']=failed

out=ROOT/'catalogs'/'M1_3_STATIC_VALIDATION.json'
out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'overall_static_status':result['overall_static_status'],'failed_checks':failed,'sql_files':len(SQL_FILES),'positive_codes':len(positive),'negative_codes':len(negative),'detail_result_sets':result_sets,'dependency_columns':len(rows)},indent=2))
sys.exit(0 if not failed else 1)
