from pathlib import Path
import re, json, csv, hashlib, sys
MOD=Path(__file__).resolve().parents[1]
SQL=sorted(list((MOD/'sql').glob('*.sql'))+list((MOD/'tests').glob('*.sql')))
errors=[]; warnings=[]; details={}

# PostgreSQL-aware lexical balance: quotes, comments, dollar bodies, parentheses/brackets.
def lexical_check(text,path):
    i=0; n=len(text); par=0; br=0; block=0; line=False; sq=False; dq=False; dollar=None
    minpar=0; minbr=0
    while i<n:
        if line:
            if text[i]=='\n': line=False
            i+=1; continue
        if block:
            if text.startswith('/*',i): block+=1; i+=2; continue
            if text.startswith('*/',i): block-=1; i+=2; continue
            i+=1; continue
        if dollar is not None:
            if text.startswith(dollar,i): i+=len(dollar); dollar=None
            else: i+=1
            continue
        if sq:
            if text[i]=="'":
                if i+1<n and text[i+1]=="'": i+=2; continue
                sq=False
            i+=1; continue
        if dq:
            if text[i]=='"':
                if i+1<n and text[i+1]=='"': i+=2; continue
                dq=False
            i+=1; continue
        if text.startswith('--',i): line=True; i+=2; continue
        if text.startswith('/*',i): block=1; i+=2; continue
        if text[i]=="'": sq=True; i+=1; continue
        if text[i]=='"': dq=True; i+=1; continue
        if text[i]=='$':
            m=re.match(r'\$[A-Za-z_][A-Za-z_0-9]*\$|\$\$',text[i:])
            if m: dollar=m.group(0); i+=len(dollar); continue
        if text[i]=='(': par+=1
        elif text[i]==')': par-=1; minpar=min(minpar,par)
        elif text[i]=='[': br+=1
        elif text[i]==']': br-=1; minbr=min(minbr,br)
        i+=1
    issues=[]
    if par or minpar<0: issues.append(f'parentheses balance {par}, min {minpar}')
    if br or minbr<0: issues.append(f'bracket balance {br}, min {minbr}')
    if block: issues.append(f'unclosed block comment depth {block}')
    if sq: issues.append('unclosed single quote')
    if dq: issues.append('unclosed double quote')
    if dollar: issues.append(f'unclosed dollar quote {dollar}')
    return issues

for p in SQL:
    text=p.read_text()
    issues=lexical_check(text,p)
    if issues: errors.append(f'{p.name}: '+', '.join(issues))
    if not text.lstrip().startswith('/* ===='):
        warnings.append(f'{p.name}: missing professional file header')
    details[p.name]={'lines':len(text.splitlines()),'bytes':len(text.encode())}

# Inventory and code counts.
val=(MOD/'sql/87_msbf_m1_12_integrated_risk_proxy_validation_v0_2.sql').read_text()
neg=(MOD/'sql/88_msbf_m1_12_negative_control_tests_v0_2.sql').read_text()
det=(MOD/'tests/91_MSBF_M1_12_Merchant_Risk_Proxy_Detail_Report_v0_2.sql').read_text()
valcodes=re.findall(r"'((?:M1_12_POS_)\d{2}_[A-Z0-9_]+)'",val)
negcodes=re.findall(r"'((?:M1_12_NEG_)\d{2}_[A-Z0-9_]+)'",neg)
val_unique=sorted(set(valcodes)); neg_unique=sorted(set(negcodes))
if len(val_unique)!=80: errors.append(f'positive control codes unique={len(val_unique)} expected=80')
if len(neg_unique)!=7: errors.append(f'negative control codes unique={len(neg_unique)} expected=7')
if re.search(r'SELECT\s+pg_temp\.m1_12_(?:add_check|record_negative)',val+neg,re.I): errors.append('standalone helper SELECT creates extraneous result sets')
if 'ON COMMIT PRESERVE ROWS' not in val: errors.append('validation output not session preserved')
if 'ON COMMIT PRESERVE ROWS' not in neg: errors.append('negative output not session preserved')
if det.count('/* 0') + len(re.findall(r'/\*\s+(?:1[0-9]|20)\s+—',det)) < 20: warnings.append('detail report label heuristic below 20')
labels=re.findall(r'/\*\s+(\d{2})\s+—',det)
if len(labels)!=20 or labels!=[f'{i:02d}' for i in range(1,21)]: errors.append(f'detail labels={labels}')

# Critical safeguards.
gen=(MOD/'sql/86_msbf_m1_12_integrated_risk_proxy_generation_v0_2.sql').read_text()
pre=(MOD/'tests/85_msbf_m1_12_preflight_validation_v0_2.sql').read_text()
acc=(MOD/'sql/89_msbf_m1_12_acceptance_finalize_v0_2.sql').read_text()
recon=(MOD/'tests/86A_msbf_m1_12_generation_reconciliation_reconstructed_v0_2.sql').read_text()
alltext='\n'.join(p.read_text() for p in SQL)
critical={
'full_source_hash': '93c3d1368fb2450ab4a08e2b721f92d3' in pre and '93c3d1368fb2450ab4a08e2b721f92d3' in val,
'scenario_scope': "M1_V0_2_BASELINE_AND_STRESS" in pre and "M1_V0_2_BASELINE_AND_STRESS" in gen,
'no_random': not bool(re.search(r'\brandom\s*\(',alltext,re.I)),
'no_blueprint_regeneration': not bool(re.search(r'm1_[456789]_.*blueprint\s*\(',gen,re.I)),
'bounded_hash_updates': all(x in gen for x in ["WHERE c.calculation_hash = 'PENDING'","WHERE s.row_hash = 'PENDING'"]),
'component_count': '10500' in gen and '10500' in acc and '10500' in recon,
'canonical_count': '12000' in gen and '12000' in acc and '12000' in recon,
'filterable_validation': 'ON COMMIT PRESERVE ROWS' in val,
'filterable_negative': 'ON COMMIT PRESERVE ROWS' in neg,
'filterable_detail': 'ON COMMIT PRESERVE ROWS' in det,
'no_scalar_filter_defect': True,  # verified separately by matching each md5() closing parenthesis
'no_global_scenario_code_count': "scenario_set_code = 'M1_V0_2_BASELINE_AND_STRESS'" in pre,
'effective_evidence_gate': 'effective_evidence_status' in gen,
'generation_scenario_guard': 'v_baseline_scenarios' in gen and 'v_stress_scenarios' in gen,
}
# Detect FILTER incorrectly attached to scalar md5() rather than to an aggregate.
def scalar_md5_filter_defects(text):
    defects=[]
    for m in re.finditer(r'\bmd5\s*\(', text, re.I):
        op=text.find('(',m.start()); dep=0; sq=False; i=op
        while i<len(text):
            ch=text[i]
            if sq:
                if ch=="'":
                    if i+1<len(text) and text[i+1]=="'": i+=2; continue
                    sq=False
            else:
                if ch=="'": sq=True
                elif ch=='(': dep+=1
                elif ch==')':
                    dep-=1
                    if dep==0:
                        tail=text[i+1:i+80]
                        if re.match(r'\s*FILTER\s*\(',tail,re.I): defects.append(m.start())
                        break
            i+=1
    return defects
md5_def=[]
for pth in SQL:
    d=scalar_md5_filter_defects(pth.read_text())
    if d: md5_def.append((pth.name,d))
critical['no_scalar_filter_defect']=not md5_def
if md5_def: errors.append(f'invalid scalar md5 FILTER patterns: {md5_def}')
for k,v in critical.items():
    if not v: errors.append(f'critical safeguard failed: {k}')

# Check INSERT target/source projection counts for the four core inserts.
def split_top(s):
    out=[]; start=0; dep=0; sq=False; dq=False; i=0
    while i<len(s):
        ch=s[i]
        if sq:
            if ch=="'":
                if i+1<len(s) and s[i+1]=="'": i+=2; continue
                sq=False
        elif dq:
            if ch=='"': dq=False
        else:
            if ch=="'": sq=True
            elif ch=='"': dq=True
            elif ch=='(': dep+=1
            elif ch==')': dep-=1
            elif ch==',' and dep==0:
                out.append(s[start:i].strip()); start=i+1
        i+=1
    out.append(s[start:].strip())
    return [x for x in out if x]

def find_insert_select(text,table,occ=1):
    starts=[m.start() for m in re.finditer(r'INSERT\s+INTO\s+'+re.escape(table)+r'\s*\(',text,re.I)]
    if len(starts)<occ: return None
    st=starts[occ-1]
    op=text.find('(',st); dep=0; sq=False; end=None
    i=op
    while i<len(text):
        ch=text[i]
        if sq:
            if ch=="'":
                if i+1<len(text) and text[i+1]=="'": i+=2; continue
                sq=False
        else:
            if ch=="'": sq=True
            elif ch=='(': dep+=1
            elif ch==')':
                dep-=1
                if dep==0: end=i; break
        i+=1
    cols=split_top(text[op+1:end])
    m=re.search(r'\bSELECT\b',text[end+1:],re.I)
    if not m:return (cols,None)
    selstart=end+1+m.end()
    # find top-level FROM
    dep=0; sq=False; i=selstart; frm=None
    while i<len(text):
        ch=text[i]
        if sq:
            if ch=="'":
                if i+1<len(text) and text[i+1]=="'": i+=2; continue
                sq=False
        else:
            if ch=="'": sq=True
            elif ch=='(': dep+=1
            elif ch==')': dep-=1
            elif dep==0 and text[i:i+4].upper()=='FROM' and (i==0 or not text[i-1].isalnum()) and (i+4==len(text) or not text[i+4].isalnum()): frm=i; break
        i+=1
    sels=split_top(text[selstart:frm]) if frm else None
    return cols,sels

insert_checks=[]
for table,occ,label in [
('_m1_12_component_expected',1,'component expected'),
('_m1_12_snapshot_expected',1,'snapshot expected'),
('msbf_m1.application_integrated_risk_proxy_snapshot',1,'snapshot physical'),
('msbf_m1.integrated_risk_component_value',1,'component physical')]:
    r=find_insert_select(gen,table,occ)
    if not r: errors.append(f'missing insert {label}'); continue
    cols,sels=r; insert_checks.append({'label':label,'columns':len(cols),'selects':None if sels is None else len(sels)})
    if sels is None or len(cols)!=len(sels): errors.append(f'{label} insert/select {len(cols)}/{None if sels is None else len(sels)}')

# Schema table column counts from catalogs.
with (MOD/'catalogs/M1_12_SCHEMA_EXTENSION_TABLES.csv').open() as f:
    rows=list(csv.DictReader(f))
if len(rows)!=2: errors.append('schema extension table catalog must contain 2 rows')
colrows=list(csv.DictReader((MOD/'catalogs/M1_12_SCHEMA_EXTENSION_COLUMNS.csv').open()))
if len(colrows)!=65: errors.append(f'schema extension columns={len(colrows)} expected=65')

# JSON/CSV parse and internal links.
for p in MOD.rglob('*.json'):
    try: json.loads(p.read_text())
    except Exception as e: errors.append(f'JSON parse {p.relative_to(MOD)}: {e}')
for p in MOD.rglob('*.csv'):
    try:
        with p.open(newline='',encoding='utf-8') as f:list(csv.reader(f))
    except Exception as e: errors.append(f'CSV parse {p.relative_to(MOD)}: {e}')

# Required scripts.
required=[
'sql/84_msbf_m1_12_schema_policy_extension_v0_2.sql','tests/85_msbf_m1_12_preflight_validation_v0_2.sql','sql/86_msbf_m1_12_integrated_risk_proxy_generation_v0_2.sql','sql/87_msbf_m1_12_integrated_risk_proxy_validation_v0_2.sql','sql/88_msbf_m1_12_negative_control_tests_v0_2.sql','sql/89_msbf_m1_12_acceptance_finalize_v0_2.sql','tests/90_MSBF_M1_12_Merchant_Risk_Proxy_Master_Report_v0_2.sql','tests/91_MSBF_M1_12_Merchant_Risk_Proxy_Detail_Report_v0_2.sql','tests/84A_msbf_m1_12_failed_generation_recovery_check_v0_2.sql','tests/86A_msbf_m1_12_generation_reconciliation_reconstructed_v0_2.sql']
for rel in required:
    if not (MOD/rel).exists(): errors.append('missing '+rel)

result={'status':'PASS' if not errors else 'FAIL','sql_files':len(SQL),'sql_lines':sum(v['lines'] for v in details.values()),'positive_controls':len(val_unique),'negative_controls':len(neg_unique),'detail_result_sets':len(labels),'insert_select_checks':insert_checks,'critical_safeguards':critical,'errors':errors,'warnings':warnings,'files_checked':[p.name for p in SQL]}
(MOD/'catalogs/M1_12_STATIC_VALIDATION.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
if errors: sys.exit(1)
