from pathlib import Path
import re,json,csv,sys
root=Path(__file__).resolve().parents[1]
errors=[];warnings=[]
sql='\n'.join(p.read_text(encoding='utf-8') for p in list((root/'sql').glob('*.sql'))+list((root/'tests').glob('*.sql')))
if re.search(r'\brandom\s*\(',sql,re.I): errors.append('session random() found')
if re.search(r'DELETE\s+FROM\s+msbf_m1\.',sql,re.I): errors.append('destructive M1 delete found')
if 'SELECT pg_temp.m1_11_add_check' in sql: errors.append('standalone helper SELECT found')
if sql.count('M1_11_POS_')<72: errors.append('positive control inventory below 72')
if sql.count('M1_11_NEG_')<6: errors.append('negative control inventory below 6')
for p in (root/'catalogs').glob('*.json'):
 try: json.loads(p.read_text())
 except Exception as e: errors.append(f'bad json {p.name}: {e}')
for p in (root/'catalogs').glob('*.csv'):
 try: list(csv.reader(p.open()))
 except Exception as e: errors.append(f'bad csv {p.name}: {e}')
result={'status':'PASS' if not errors else 'FAIL','errors':errors,'warnings':warnings,'sql_files':len(list((root/'sql').glob('*.sql'))+list((root/'tests').glob('*.sql'))),'positive_control_occurrences':sql.count('M1_11_POS_'),'negative_control_occurrences':sql.count('M1_11_NEG_')}
(root/'catalogs/M1_11_STATIC_VALIDATION.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2));sys.exit(1 if errors else 0)
