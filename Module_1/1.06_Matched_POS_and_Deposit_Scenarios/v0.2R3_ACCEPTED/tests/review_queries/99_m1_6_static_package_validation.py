from pathlib import Path
import re, csv, json, hashlib, sys
root=Path(__file__).resolve().parents[1]
sql_files=sorted(list((root/'sql').glob('*.sql'))+list((root/'tests').glob('*.sql')))
# exclude static itself if created later
sql_files=[p for p in sql_files if p.name!='99_m1_6_static_package_validation.py']

# physical catalog
cat_path=root/'catalogs'/'M1_6_PHYSICAL_DEPENDENCY_COLUMNS.csv'
cat_rows=list(csv.DictReader(cat_path.open()))
physical={}
for r in cat_rows:
    physical.setdefault((r['schema_name'],r['table_name']),set()).add(r['column_name'])

# lexical scanner

def scan_balance(text):
    par=0; i=0; state='normal'; dollar=None; errors=[]
    while i<len(text):
        if state=='normal':
            if text.startswith('--',i): state='line'; i+=2; continue
            if text.startswith('/*',i): state='block'; i+=2; continue
            c=text[i]
            if c=="'": state='single'; i+=1; continue
            if c=='"': state='double'; i+=1; continue
            if c=='$':
                m=re.match(r'\$[A-Za-z_][A-Za-z_0-9]*\$|\$\$',text[i:])
                if m:
                    dollar=m.group(0); state='dollar'; i+=len(dollar); continue
            if c=='(': par+=1
            elif c==')':
                par-=1
                if par<0: errors.append(f'negative parenthesis at {i}'); par=0
            i+=1
        elif state=='line':
            if text[i]=='\n': state='normal'
            i+=1
        elif state=='block':
            if text.startswith('*/',i): state='normal'; i+=2
            else: i+=1
        elif state=='single':
            if text[i]=="'":
                if i+1<len(text) and text[i+1]=="'": i+=2
                else: state='normal'; i+=1
            else: i+=1
        elif state=='double':
            if text[i]=='"':
                if i+1<len(text) and text[i+1]=='"': i+=2
                else: state='normal'; i+=1
            else: i+=1
        elif state=='dollar':
            j=text.find(dollar,i)
            if j<0: errors.append(f'unclosed dollar {dollar}'); i=len(text)
            else: i=j+len(dollar); state='normal'; dollar=None
    if par!=0: errors.append(f'parenthesis balance {par}')
    if state not in ('normal','line'): errors.append(f'unclosed lexical state {state}')
    return errors

def split_top(s):
    out=[]; start=0; depth=0; state='normal'; i=0; dollar=None
    while i<len(s):
        if state=='normal':
            if s.startswith('--',i): state='line'; i+=2; continue
            if s.startswith('/*',i): state='block'; i+=2; continue
            c=s[i]
            if c=="'": state='single'; i+=1; continue
            if c=='"': state='double'; i+=1; continue
            if c=='$':
                m=re.match(r'\$[A-Za-z_][A-Za-z_0-9]*\$|\$\$',s[i:])
                if m: dollar=m.group(0); state='dollar'; i+=len(dollar); continue
            if c=='(': depth+=1
            elif c==')': depth-=1
            elif c==',' and depth==0:
                out.append(s[start:i].strip()); start=i+1
            i+=1
        elif state=='line':
            if s[i]=='\n': state='normal'
            i+=1
        elif state=='block':
            if s.startswith('*/',i): state='normal'; i+=2
            else:i+=1
        elif state=='single':
            if s[i]=="'":
                if i+1<len(s) and s[i+1]=="'": i+=2
                else: state='normal'; i+=1
            else:i+=1
        elif state=='double':
            if s[i]=='"':
                if i+1<len(s) and s[i+1]=='"': i+=2
                else: state='normal'; i+=1
            else:i+=1
        elif state=='dollar':
            j=s.find(dollar,i)
            if j<0: i=len(s)
            else:i=j+len(dollar);state='normal';dollar=None
    out.append(s[start:].strip())
    return [x for x in out if x]

def extract_insert_targets(text):
    results=[]
    for m in re.finditer(r'INSERT\s+INTO\s+([A-Za-z_][\w]*)\.([A-Za-z_][\w]*)\s*\(',text,re.I):
        pos=m.end(); depth=1; i=pos; state='normal'
        while i<len(text) and depth:
            c=text[i]
            if state=='normal':
                if c=="'": state='single'
                elif c=='(': depth+=1
                elif c==')': depth-=1
            elif state=='single' and c=="'":
                if i+1<len(text) and text[i+1]=="'": i+=1
                else: state='normal'
            i+=1
        cols=[c.strip().strip('"') for c in split_top(text[pos:i-1])]
        results.append((m.group(1),m.group(2),cols))
    return results

def extract_update_targets(text):
    results=[]
    for m in re.finditer(r'UPDATE\s+([A-Za-z_][\w]*)\.([A-Za-z_][\w]*)\s+SET\s+',text,re.I):
        start=m.end();
        # Find WHERE or semicolon at top level
        i=start; depth=0; state='normal'
        while i<len(text):
            if state=='normal':
                if text.startswith('--',i): state='line'; i+=2; continue
                if text.startswith('/*',i): state='block'; i+=2; continue
                c=text[i]
                if c=="'": state='single'; i+=1; continue
                if c=='(': depth+=1
                elif c==')': depth-=1
                elif depth==0 and c==';': break
                elif depth==0 and re.match(r'WHERE\b',text[i:],re.I): break
                i+=1
            elif state=='line':
                if text[i]=='\n': state='normal'
                i+=1
            elif state=='block':
                if text.startswith('*/',i): state='normal'; i+=2
                else:i+=1
            elif state=='single':
                if text[i]=="'":
                    if i+1<len(text) and text[i+1]=="'": i+=2
                    else:state='normal';i+=1
                else:i+=1
        assigns=split_top(text[start:i])
        cols=[]
        for a in assigns:
            mm=re.match(r'\s*([A-Za-z_][\w]*)\s*=',a)
            if mm: cols.append(mm.group(1))
        results.append((m.group(1),m.group(2),cols))
    return results

errors=[]; warnings=[]; lex={}; total_lines=0
alltext='\n'.join(p.read_text() for p in sql_files)
for p in sql_files:
    t=p.read_text(); total_lines+=t.count('\n')+1
    e=scan_balance(t); lex[p.name]=e
    errors += [f'{p.name}: {x}' for x in e]

# DML validation
invalid_dml=[]
for p in sql_files:
    t=p.read_text()
    for sch,tab,cols in extract_insert_targets(t):
        if (sch,tab) in physical:
            bad=[c for c in cols if c not in physical[(sch,tab)]]
            if bad: invalid_dml.append({'file':p.name,'operation':'INSERT','table':f'{sch}.{tab}','invalid':bad})
    for sch,tab,cols in extract_update_targets(t):
        if (sch,tab) in physical:
            bad=[c for c in cols if c not in physical[(sch,tab)]]
            if bad: invalid_dml.append({'file':p.name,'operation':'UPDATE','table':f'{sch}.{tab}','invalid':bad})
if invalid_dml: errors.append(f'invalid DML targets: {invalid_dml}')

# controls
positive=sorted(set(re.findall(r'M1_6_POS_[0-9]{2}_[A-Z0-9_]+',alltext)))
negative=sorted(set(re.findall(r'M1_6_NEG_[0-9]{2}_[A-Z0-9_]+',alltext)))
if len(positive)!=62: errors.append(f'positive control count {len(positive)} != 62')
if len(negative)!=5: errors.append(f'negative control count {len(negative)} != 5')
# detail sets
text44=(root/'tests'/'44_MSBF_M1_6_Matched_Scenario_Overlay_Detail_Report_v0_2.sql').read_text()
result_sets=len(re.findall(r'/\* Result set [0-9]+',text44))
if result_sets!=16: errors.append(f'detail result sets {result_sets} != 16')
# functions
functions=sorted(set(re.findall(r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+msbf_m1\.([A-Za-z_][\w]*)',alltext,re.I)))
expected_funcs=['m1_6_actual_scenario_snapshot','m1_6_assert_generation_ready','m1_6_deposit_scenario_blueprint','m1_6_deposit_scenario_row_hash','m1_6_expected_scenario_snapshot','m1_6_industry_shock_matrix','m1_6_pos_scenario_blueprint','m1_6_pos_scenario_row_hash','m1_6_scenario_profile']
if functions!=expected_funcs: errors.append(f'function inventory mismatch: {functions}')
# required params from preflight exact unique pairs
pre=(root/'tests'/'38_msbf_m1_6_preflight_validation_v0_2.sql').read_text()
block=re.search(r'required_parameters\(parameter_name,scope_key\) AS \(\s*VALUES(.*?)\), parameter_obs',pre,re.S|re.I)
pairs=[]
if block:
    pairs=re.findall(r"\('([^']+)'\s*,\s*'([^']+)'\)",block.group(1))
if len(pairs)!=32 or len(set(pairs))!=32: errors.append(f'required parameter pairs {len(pairs)} unique {len(set(pairs))}, expected 32')
# random prohibited
random_calls=[]
for p in sql_files:
    for n,line in enumerate(p.read_text().splitlines(),1):
        if re.search(r'(?<!deterministic_)\brandom\s*\(',line,re.I): random_calls.append((p.name,n,line.strip()))
if random_calls: errors.append(f'session random calls: {random_calls}')
# destructive M1 business table operations
bad_destructive=[]
for p in sql_files:
    for n,line in enumerate(p.read_text().splitlines(),1):
        if re.search(r'\b(?:DELETE\s+FROM|TRUNCATE\s+TABLE|DROP\s+TABLE)\s+msbf_m1\.',line,re.I): bad_destructive.append((p.name,n,line.strip()))
if bad_destructive: errors.append(f'destructive M1 operations: {bad_destructive}')
# expected patterns
for pat,msg in [
    (r"WHEN t\.scenario_type='BASELINE' OR NOT t\.shock_active THEN t\.refund_amount",'pre-shock POS quality copy'),
    (r"WHEN n\.scenario_type='BASELINE' OR NOT n\.shock_active THEN n\.nsf_count",'pre-shock NSF copy'),
    (r"n\.negative_balance_flag OR n\.scenario_minimum<0",'monotonic negative balance control'),
    (r"'overlay_applied',\(s\.scenario_type='STRESS' AND s\.shock_active\)",'POS active overlay flag'),
    (r"'overlay_applied',\(n\.scenario_type='STRESS' AND n\.shock_active\)",'deposit active overlay flag')]:
    if not re.search(pat,alltext): errors.append(f'missing {msg}')
# reference tables and dependency catalog
refs=set(re.findall(r'\b(msbf_(?:ref|ctl|m1))\.([A-Za-z_][\w]*)\b',alltext))
dep_rows=[]
for sch,tab in sorted(refs):
    if (sch,tab) in physical:
        for col in sorted(physical[(sch,tab)]): dep_rows.append({'schema_name':sch,'table_name':tab,'column_name':col})
# return-shape quick counts manually extract from known signatures
shape={}
for fn in ['m1_6_pos_scenario_blueprint','m1_6_deposit_scenario_blueprint']:
    t=(root/'sql'/'39_msbf_m1_6_matched_scenario_overlay_generation_v0_2.sql').read_text()
    m=re.search(rf'CREATE OR REPLACE FUNCTION msbf_m1\.{fn}\(.*?\)\s*RETURNS TABLE\((.*?)\)\s*LANGUAGE',t,re.S)
    if not m:
        errors.append(f'missing returns for {fn}'); continue
    declared=len(split_top(m.group(1)))
    # select final based marker
    start=m.end()
    end=t.find('$fn$;',start)
    body=t[start:end]
    # find final SELECT before FROM final_rows f
    mm=list(re.finditer(r'\nSELECT\s+(.*?)\nFROM final_rows f',body,re.S))
    if not mm:
        errors.append(f'cannot find final select for {fn}'); continue
    exprs=len(split_top(mm[-1].group(1)))
    shape[fn]={'declared':declared,'selected':exprs}
    if declared!=exprs: errors.append(f'{fn} return shape {declared}!={exprs}')

result={
 'package':'MSBF M1.6 Matched POS and Deposit Scenario Overlay Generation v0.2',
 'sql_files':len(sql_files),'sql_lines':total_lines,'functions':functions,
 'positive_controls':len(positive),'negative_controls':len(negative),'detail_result_sets':result_sets,
 'required_parameter_scope_pairs':len(pairs),'physical_dependency_tables':len({(r['schema_name'],r['table_name']) for r in dep_rows}),
 'physical_dependency_columns':len(dep_rows),'lexical_issues':lex,'invalid_dml_targets':invalid_dml,
 'random_calls':random_calls,'destructive_m1_operations':bad_destructive,'function_return_shapes':shape,
 'errors':errors,'warnings':warnings,'overall_status':'PASS' if not errors else 'FAIL'
}
(root/'catalogs').mkdir(exist_ok=True)
(root/'catalogs'/'M1_6_STATIC_VALIDATION.json').write_text(json.dumps(result,indent=2))
with (root/'catalogs'/'M1_6_PHYSICAL_DEPENDENCY_COLUMNS.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['schema_name','table_name','column_name']);w.writeheader();w.writerows(dep_rows)
print(json.dumps(result,indent=2))
if errors: sys.exit(1)
