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
if meta.get("release")!="Module 2 / G3 v2.1.0-rc2": errors.append("release identity")
if meta.get("power_bi_pbip_asset_sha256")!="803cf8acdbb1bd598750618404a687f15a1ca087d86e76364a0bedb457f7c31f": errors.append("R22 PBIP identity")
if meta.get("power_bi_desktop_evidence_sha256")!="c50eda59928244ee6b7e4a967681d51ebff282a0ff6038a27aa96871cdf0b5af": errors.append("R22 Desktop identity")
if sha(root.parents[1]/".github/workflows/publication_integrity.yml")!="9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed": errors.append("workflow")
adj=json.loads((root/"power_bi/evidence/R22_DESKTOP_EVIDENCE_FINAL_ADJUDICATION.json").read_text())
if adj.get("status")!="PASS" or adj.get("controls_fail")!=0 or adj.get("saved_state",{}).get("strategy_profile")!="BALANCED_FRONTIER": errors.append("R22 final adjudication")
if not (root/"power_bi/project/MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22/MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22.pbip").is_file(): errors.append("R22 project")
if (root/"power_bi/project/MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R20").exists(): errors.append("stale R20 project root")
for p in files():
 if p.suffix.lower() in {".md",".json",".csv",".txt",".sql",".yml",".yaml",".ps1",".bim"}:
  try:t=p.read_text(encoding="utf-8-sig")
  except:continue
  if "/mnt/data/" in t or "/home/oai/" in t or re.search(r"(?i)C:\\Users\\",t): errors.append("local path "+str(p.relative_to(root)))
print("Candidate overlay validation "+("FAIL" if errors else "PASS"))
if errors:
 print("\n".join("- "+e for e in errors)); sys.exit(1)
print(f"Governed candidate files: {len(rows)}")
