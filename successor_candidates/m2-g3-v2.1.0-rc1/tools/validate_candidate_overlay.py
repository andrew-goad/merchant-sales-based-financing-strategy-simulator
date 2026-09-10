#!/usr/bin/env python3
from pathlib import Path
import csv,hashlib,json,re,sys
root=Path(__file__).resolve().parents[1]
errors=[]
auth={"CANDIDATE_MANIFEST.csv","CANDIDATE_MANIFEST.json","CANDIDATE_SHA256SUMS.txt"}
def files(): return [p for p in root.rglob("*") if p.is_file() and p.name not in auth and "__pycache__" not in p.parts]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
for p in files():
 try:
  if p.suffix.lower()==".json": json.loads(p.read_text(encoding="utf-8-sig"))
  elif p.suffix.lower()==".csv":
   with p.open(newline="",encoding="utf-8-sig") as f: list(csv.reader(f))
 except Exception as e: errors.append(f"parse {p.relative_to(root)}: {e}")
with (root/"CANDIDATE_MANIFEST.csv").open(newline="",encoding="utf-8") as f: rows=list(csv.DictReader(f))
mp={r["path"]:r for r in rows}; fp={p.relative_to(root).as_posix():p for p in files()}
for x in sorted(set(mp)-set(fp)): errors.append("manifest extra "+x)
for x in sorted(set(fp)-set(mp)): errors.append("manifest missing "+x)
for x,p in fp.items():
 if x in mp and (sha(p)!=mp[x]["sha256"] or p.stat().st_size!=int(mp[x]["size_bytes"])): errors.append("manifest mismatch "+x)
meta=json.loads((root/"CANDIDATE_RELEASE_METADATA.json").read_text())
if meta.get("publication_authorized") is not False: errors.append("publication authority")
if meta.get("accepted_release_remains")!="Module 2 / G3 v2.0.0": errors.append("accepted authority")
if sha(root.parents[1]/".github/workflows/publication_integrity.yml")!="9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed": errors.append("workflow")
for p in files():
 if p.suffix.lower() in {".md",".json",".csv",".txt",".sql",".yml",".yaml",".ps1",".bim"}:
  try:t=p.read_text(encoding="utf-8-sig")
  except:continue
  if "/mnt/data/" in t or "/home/oai/" in t or re.search(r"(?i)C:\\Users\\",t): errors.append("local path "+str(p.relative_to(root)))
print("Candidate overlay validation "+("FAIL" if errors else "PASS"))
if errors:
 print("\n".join("- "+e for e in errors)); sys.exit(1)
print(f"Governed candidate files: {len(rows)}")
