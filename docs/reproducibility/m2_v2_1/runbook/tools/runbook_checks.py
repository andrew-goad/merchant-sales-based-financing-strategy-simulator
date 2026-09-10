#!/usr/bin/env python3
"""PUB-RUN-001: read-only source/evidence checks, never a SQL execution engine.

Python standard library only. Input files are never modified. Reports are created
exclusively (no overwrites). Extraction is opt-in into a new, empty directory.
A PASS is limited to the checks listed; it is not an audit or execution approval.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
import csv
from datetime import datetime, timezone
from decimal import Decimal
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import shutil
import stat
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MAX_EXPANDED = 8 * 1024**3
RESERVED = {'CON', 'PRN', 'AUX', 'NUL', *(f'COM{i}' for i in range(1, 10)), *(f'LPT{i}' for i in range(1, 10))}

class CheckError(Exception):
    """A controlled failure; input evidence remains untouched."""

def hash_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def hash_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def load_json(path: Path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def ensure_plain_path(path: Path) -> None:
    """Refuse existing symlinks/junctions in destination or its ancestors."""
    for part in [path, *path.parents]:
        if part.is_symlink() or (hasattr(part, 'is_junction') and part.is_junction()):
            raise CheckError(f'Link/junction path is not permitted: {part}')

def canonical_member(name: str) -> str:
    if not name or '\\' in name or '\x00' in name or name.startswith('/'):
        raise CheckError(f'Unsafe archive path: {name!r}')
    bare = name.rstrip('/')
    parts = bare.split('/')
    if any(not x or x in {'.', '..'} for x in parts):
        raise CheckError(f'Unsafe archive path components: {name!r}')
    for x in parts:
        if x.endswith(('.', ' ')) or any(c in x for c in '<>:"|?*') or any(ord(c) < 32 for c in x):
            raise CheckError(f'Windows-unsafe archive path: {name!r}')
        if x.split('.')[0].upper() in RESERVED:
            raise CheckError(f'Windows reserved name: {name!r}')
    return '/'.join(parts)

def inspect_zip(path: Path, windows_root: str = 'C:\\MSBF\\x') -> dict:
    if not path.is_file():
        raise CheckError(f'Input archive missing: {path}')
    seen, kinds, spellings = set(), {}, {}
    sizes, maxlen = 0, 0
    with zipfile.ZipFile(path) as z:
        for info in z.infolist():
            name = canonical_member(info.filename)
            key = name.casefold()
            if key in seen:
                raise CheckError(f'Duplicate/case-colliding archive path: {name}')
            seen.add(key)
            mode = info.external_attr >> 16
            if stat.S_ISLNK(mode) or info.flag_bits & 1:
                raise CheckError(f'Symlink or encrypted member: {name}')
            if info.compress_type not in {zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED}:
                raise CheckError(f'Unsupported Windows-portable compression: {name}')
            kinds[key] = info.is_dir()
            parts = name.split('/')
            for i in range(1, len(parts) + 1):
                sub = '/'.join(parts[:i]); low = sub.casefold()
                if low in spellings and spellings[low] != sub:
                    raise CheckError(f'Case-colliding directory spelling: {sub}')
                spellings[low] = sub
            sizes += info.file_size
            maxlen = max(maxlen, len(windows_root.rstrip('\\/')) + 1 + len(name))
        for k in kinds:
            for p in PurePosixPath(k).parents:
                s = str(p)
                if s in kinds and not kinds[s]:
                    raise CheckError(f'File/directory collision: {k}')
        if sizes > MAX_EXPANDED:
            raise CheckError('Expanded archive exceeds the 8-GiB safety bound; request a bounded review.')
        if maxlen > 240:
            raise CheckError(f'Simulated Windows path {maxlen} exceeds 240; shorten the extraction root.')
        bad = z.testzip()
        if bad is not None:
            raise CheckError(f'Archive CRC failure: {bad}')
        return {'members':len(z.infolist()), 'regular_files':sum(not x.is_dir() for x in z.infolist()),
                'expanded_bytes':sizes,'crc':'PASS','windows_root_simulated':windows_root,
                'maximum_simulated_windows_path':maxlen,'windows_native_extraction_performed':False}

def safe_extract(path: Path, dest: Path) -> dict:
    ensure_plain_path(dest)
    if dest.exists():
        raise CheckError(f'Extraction destination already exists; choose a new directory: {dest}')
    inspect_zip(path, str(dest) if os.name == 'nt' else 'C:\\MSBF\\x')
    dest.mkdir(parents=True, exist_ok=False)
    count = 0
    # On interruption, keep the partial destination for diagnosis. Never silently reuse it.
    with zipfile.ZipFile(path) as z:
        for info in z.infolist():
            target = dest.joinpath(*canonical_member(info.filename).split('/'))
            ensure_plain_path(target)
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with z.open(info) as source, target.open('xb') as output:
                    shutil.copyfileobj(source, output, 1024 * 1024)
                if hash_file(target) != hash_bytes(z.read(info)):
                    raise CheckError(f'Extracted byte mismatch: {info.filename}')
                count += 1
    return {'files_verified':count, 'directory':str(dest), 'extraction_method':'Python zipfile; not Windows-native evidence'}

def compare_folder(archive: Path, folder: Path) -> dict:
    inspect_zip(archive)
    ensure_plain_path(folder)
    if not folder.is_dir(): raise CheckError('Extracted directory is missing.')
    with zipfile.ZipFile(archive) as z:
        expected={canonical_member(x.filename):x for x in z.infolist() if not x.is_dir()}
        actual={}
        for p in folder.rglob('*'):
            ensure_plain_path(p)
            if p.is_file():actual[p.relative_to(folder).as_posix()]=p
        if set(expected) != set(actual):
            raise CheckError(f'Extracted member set differs: missing={sorted(set(expected)-set(actual))[:8]}, extra={sorted(set(actual)-set(expected))[:8]}')
        for name,info in expected.items():
            if hash_file(actual[name]) != hash_bytes(z.read(info)):raise CheckError(f'Extraction mismatch: {name}')
    return {'files_verified':len(expected), 'equality':'BYTE_FOR_BYTE',
            'note':'Record the actual extraction program and Windows version separately; byte comparison does not prove the extraction method.'}

def check_locked_tree(folder: Path, lock: dict, post_run: bool = False) -> dict:
    ensure_plain_path(folder)
    actual={}
    for p in folder.rglob('*'):
        ensure_plain_path(p)
        if p.is_file():actual[p.relative_to(folder).as_posix()]=p
    expected=lock['files']
    output_names = {n for n in actual if n.startswith('results/')} if post_run else set()
    actual = {n:p for n,p in actual.items() if n not in output_names}
    if set(actual)!=set(expected):
        raise CheckError(f'Frozen runtime file set differs. Missing={sorted(set(expected)-set(actual))[:6]}; extra={sorted(set(actual)-set(expected))[:6]}. No rerun or normalization.')
    for rel,expect in expected.items():
        p=actual[rel]
        if p.stat().st_size!=expect['bytes'] or hash_file(p)!=expect['sha256']:
            raise CheckError(f'Frozen runtime mismatch: {rel}')
    return {'files_verified':len(actual),'ignored_runtime_output_files':len(output_names),'scope':'SOURCE BYTES ONLY; NOT A DATABASE PREFLIGHT OR OUTPUT ACCEPTANCE'}

def check_manifest(folder: Path) -> dict:
    rows=list(csv.DictReader((folder/'MANIFEST.csv').open(encoding='utf-8-sig',newline='')))
    seen=set()
    for r in rows:
        rel=canonical_member(r['path'])
        if rel in seen:raise CheckError(f'Duplicate manifest row {rel}')
        seen.add(rel);p=folder/rel;ensure_plain_path(p)
        if not p.is_file() or p.stat().st_size!=int(r['bytes']) or hash_file(p)!=r['sha256']:
            raise CheckError(f'Manifest mismatch: {rel}')
    actual={p.relative_to(folder).as_posix() for p in folder.rglob('*') if p.is_file()}
    if actual != seen|{'MANIFEST.csv','SHA256SUMS.txt'}:raise CheckError('Runbook manifest set differs from physical file set.')
    sums={}
    for line in (folder/'SHA256SUMS.txt').read_text(encoding='utf-8').splitlines():
        h,rel=line.split('  ',1);rel=canonical_member(rel)
        if rel in sums or not re.fullmatch('[0-9a-f]{64}',h):raise CheckError('Invalid or duplicate checksum record.')
        sums[rel]=h
    if set(sums)!=seen|{'MANIFEST.csv'}:raise CheckError('Checksum coverage differs.')
    for rel,h in sums.items():
        if hash_file(folder/rel)!=h:raise CheckError(f'Checksum mismatch: {rel}')
    return {'payload_files':len(rows),'checksums':len(sums),'scope':'INTERNAL CONSISTENCY; compare outer ZIP hash to the separately supplied sidecar.'}

def csv_records(data: bytes) -> tuple[list[str], list[dict]]:
    reader=csv.DictReader(io.StringIO(data.decode('utf-8-sig')))
    columns=reader.fieldnames or []
    if len(columns)!=len(set(columns)):raise CheckError('Duplicate CSV columns.')
    rows=list(reader)
    if any(None in r or any(v is None for v in r.values()) for r in rows):raise CheckError('Ragged CSV record.')
    return columns,rows

def reconcile_result(path: Path, ref: dict) -> dict:
    info=inspect_zip(path)
    checks=[];pop={}
    def check(code: str, ok: bool, observed=None):
        checks.append({'check_id':code,'status':'PASS' if ok else 'FAIL','observed':observed})
    with zipfile.ZipFile(path) as z:
        receipt=json.loads(z.read('R26_RESUME_RECEIPT.json'))
        for k,value in ref['receipt_required'].items():
            actual=receipt.get(k)
            check('receipt.'+k, actual==value and type(actual)==type(value),actual)
        check('receipt.no_failure', receipt.get('failure') is None)
        db=receipt.get('resume_database','')
        check('receipt.target_identity',bool(re.fullmatch(r'msbf_r1_r26_resume_g3v2_\d{8}_\d{6}',db)) and db not in {receipt.get('source_db'),receipt.get('retained_r2_final_db')},db)
        check('receipt.target_alias',receipt.get('resume_db')==db)
        for field in ['started_at_utc','completed_at_utc']:
            try:datetime.fromisoformat(receipt[field]);ok=True
            except (ValueError,KeyError,TypeError):ok=False
            check('receipt.'+field+'.parse',ok)
        master=json.loads(z.read('evidence/resume_g3/G3V2_CERTIFICATION_MASTER.json'))
        for k,v in ref['master_required'].items():check('certification.'+k,master.get(k)==v,master.get(k))
        for name,r in ref['csv_members'].items():
            data=z.read(name);cols,rows=csv_records(data);pop[name]=rows
            check('hash.'+name, hash_bytes(data)==r['sha256'],hash_bytes(data))
            check('shape.'+name,len(data)==r['bytes'] and len(rows)==r['rows'] and cols==r['columns'],{'bytes':len(data),'rows':len(rows),'columns':len(cols)})
        for name in [n for n in ref['csv_members'] if n.startswith('evidence/resume_wave_a_exports/')]:
            base=name.rsplit('/',1)[1]
            before=z.read('evidence/retained_final_wave_a_exports/'+base)
            cloned=z.read(name)
            after=z.read('evidence/retained_final_post_wave_a_exports/'+base)
            check('before_clone_after.'+base,before==cloned==after)
        nm=json.loads(z.read('evidence/05_NONMUTATION.json'))
        check('nonmutation.record',nm.get('status')=='PASS' and all(nm.get(k) is True for k in ['r6_source_control_exact','r6_schema_exact','retained_final_wave_a_identity_exact','retained_final_exports_exact']))
        pre=json.loads(z.read('evidence/01_RETAINED_FINAL_EXACT_PREFLIGHT.json'))
        check('preflight.record',all(pre.get(k) is True for k in ['database_identity_exact','policy_controls_exact','g3_schema_absent']))
        controls=pop['evidence/resume_g3/v_p06_g3v2_certification.csv']
        check('controls.unique_exact_ids',sorted(x['control_id'] for x in controls)==ref['exact_control_ids'])
        check('controls.all_pass',len(controls)==70 and all(x['status']=='PASS' for x in controls))
        mon=pop['evidence/resume_wave_a_exports/m2_5_r26.csv']
        key=lambda r:(r['module1_run_id'],r['scenario_code'],r['merchant_application_id'])
        days=defaultdict(set)
        for r in mon:days[key(r)].add(int(r['monitoring_day_index']))
        check('monitoring.exact_grain',len(mon)==15600 and len(days)==130 and all(d==set(range(1,121)) for d in days.values()))
        split=Counter(k[1] for k in days)
        check('monitoring.scenario_split',dict(split)=={'BASELINE':103,'RECESSION_ENERGY':27},dict(split))
        for stage in range(6,11):
            rows=pop[f'evidence/resume_wave_a_exports/m2_{stage}.csv']
            check(f'm2_{stage}.key_set',len(rows)==130 and {key(x) for x in rows}==set(days))
        routes=Counter(r['strategy_outcome_code'] for r in pop['evidence/resume_wave_a_exports/m2_6.csv'])
        check('intervention.distribution',dict(routes)=={'CLOSED_NO_FURTHER_ACTION':126,'TARGETED_MERCHANT_OUTREACH_REVIEW':3,'TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW':1},dict(routes))
        end=pop['evidence/resume_wave_a_exports/m2_10.csv']
        exposure=sum((Decimal(x['certified_exposure_amount']) for x in end),Decimal(0))
        paid=sum((Decimal(x['processed_payment_amount']) for x in end),Decimal(0))
        check('endpoint.exposure',exposure==Decimal('6061.03'),str(exposure))
        check('endpoint.processed',paid==Decimal('1762.25'),str(paid))
        app=pop['evidence/resume_g3/v_p05_application_strategy_simulation.csv']
        grouped=defaultdict(list)
        for r in app:grouped[key(r)].append(r)
        check('simulation.eight_per_application',len(grouped)==1500 and all(len(rs)==8 and len({x['strategy_profile_code'] for x in rs})==8 for rs in grouped.values()))
    failures=[r for r in checks if r['status']=='FAIL']
    return {'status':'FAIL' if failures else 'PASS','scope':'OFFLINE ACCEPTED-REFERENCE RECONCILIATION, NOT SQL OR DATABASE RE-EXECUTION',
            'archive':info,'result_sha256':hash_file(path),'golden_outer_identity_equal':hash_file(path)==ref['basis']['sha256'],
            'note':'New run timestamps, database name and ZIP hash may differ. Locked business exports/canonical roots must not. Database nonmutation is checked against submitted receipts and export bytes, not by querying a live database.',
            'check_count':len(checks),'pass_count':len(checks)-len(failures),'failure_count':len(failures),'checks':checks}

def verify_pbix(path: Path, lock: dict) -> dict:
    if not path.is_file() or path.stat().st_size!=lock['bytes'] or hash_file(path)!=lock['sha256']:
        raise CheckError('PBIX does not match accepted R3 byte identity. Do not save/refresh it as the frozen release.')
    info=inspect_zip(path)
    with zipfile.ZipFile(path) as z:
        if hash_bytes(z.read('DataModel'))!=lock['DataModel_sha256']:raise CheckError('Embedded DataModel mismatch.')
        vis=[n for n in z.namelist() if n.endswith('/visual.json')]
        pages=[n for n in z.namelist() if n.endswith('/page.json')]
        if len(vis)!=96 or len(pages)!=5:raise CheckError('Physical page/visual count differs.')
        for r in lock['pages']:
            n='Report/definition/pages/'+r['page_id']+'/page.json'
            data=z.read(n);j=json.loads(data)
            if hash_bytes(data)!=r['page_json_sha256'] or j['displayName']!=r['page_name']:raise CheckError('Physical page identity differs.')
        # Exact overall PBIX digest is controlling; this is an additional narrow report-reference check.
        for n in vis:
            text=z.read(n).decode('utf-8')
            for entity in lock['excluded_predecessor_entities']:
                if re.search(r'"Entity"\s*:\s*"'+re.escape(entity)+r'"',text):raise CheckError('Predecessor entity reference found.')
    return {'status':'PASS','scope':'ACCEPTED R3 IDENTITY PRESERVATION; NOT A NEW POWER BI QA CYCLE',
            'sha256':lock['sha256'],'DataModel_sha256':lock['DataModel_sha256'],'pages':5,'visuals':96,'archive':info}

def seal_evidence(folder: Path) -> dict:
    ensure_plain_path(folder)
    rows=[]
    if not folder.is_dir():raise CheckError('Evidence directory is missing.')
    for p in sorted(folder.rglob('*')):
        ensure_plain_path(p)
        if p.is_file():rows.append({'path':p.relative_to(folder).as_posix(),'bytes':p.stat().st_size,'sha256':hash_file(p)})
    if not rows:raise CheckError('Do not seal an empty evidence directory.')
    return {'files':rows,'file_count':len(rows),'scope':'BYTE INVENTORY ONLY; a hash is not a digital signature or an audit opinion.'}

def write_report(path: Path, data: dict) -> None:
    ensure_plain_path(path)
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('x',encoding='utf-8',newline='\n') as f:json.dump(data,f,indent=2,ensure_ascii=False);f.write('\n')

def main(argv=None) -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='command',required=True)
    v=sub.add_parser('verify',help='Check one pinned component, optionally extract into a NEW directory.')
    v.add_argument('--component',required=True);v.add_argument('--file',type=Path,required=True);v.add_argument('--extract',type=Path)
    v.add_argument('--windows-root',default='C:\\MSBF\\x')
    r=sub.add_parser('reconcile',help='Reconcile a retained-final resume result to the accepted reference.')
    r.add_argument('--result',type=Path,required=True)
    b=sub.add_parser('pbix',help='Check accepted PBIX byte identity without opening Power BI.');b.add_argument('--file',type=Path,required=True)
    t=sub.add_parser('runtime',help='Check exact pre-run source tree; outputs/extra files cause STOP.');t.add_argument('--root',type=Path,required=True);t.add_argument('--post-run',action='store_true',help='Allow only additional files beneath original results/; still verify all original bytes.')
    m=sub.add_parser('manifest',help='Verify this runbook package manifest.');m.add_argument('--root',type=Path,default=ROOT)
    e=sub.add_parser('compare-extraction',help='Compare externally extracted bytes; does not assert extraction method.');e.add_argument('--file',type=Path,required=True);e.add_argument('--folder',type=Path,required=True)
    s=sub.add_parser('seal',help='Inventory retained evidence to an OUTSIDE report.');s.add_argument('--folder',type=Path,required=True)
    for p in [v,r,b,t,m,e,s]:p.add_argument('--report',type=Path,required=True)
    args=parser.parse_args(argv)
    # Never overwrite a report or write diagnostic output into a frozen input/extraction tree.
    report=args.report.absolute()
    try:
        ensure_plain_path(report)
        if report.exists():raise CheckError('Report already exists. Use a new run/evidence filename.')
        if report==ROOT or ROOT in report.parents:raise CheckError('Write reports outside the frozen runbook package.')
        for field in ['root','folder','extract']:
            value=getattr(args,field,None)
            if value and (report==value.absolute() or value.absolute() in report.parents):raise CheckError('Report must be outside the checked/extracted input directory.')
        for field in ['file','result']:
            value=getattr(args,field,None)
            if value and report==value.absolute():raise CheckError('Report cannot replace an input.')
        result={}
        if args.command=='verify':
            locks=load_json(ROOT/'registers/COMPONENT_LOCK.json')['components']
            if args.component not in locks:raise CheckError('Unknown component; select an exact ID in COMPONENT_LOCK.json.')
            lock=locks[args.component]
            if not args.file.is_file() or args.file.stat().st_size!=lock['bytes'] or hash_file(args.file)!=lock['sha256']:raise CheckError('Component byte size/SHA-256 differs from the frozen reference.')
            result={'component':args.component,'identity':lock,'zip':inspect_zip(args.file,args.windows_root)}
            if args.extract:result['extraction']=safe_extract(args.file,args.extract)
        elif args.command=='reconcile':result=reconcile_result(args.result,load_json(ROOT/'registers/GOLDEN_R26_REFERENCE.json'))
        elif args.command=='pbix':result=verify_pbix(args.file,load_json(ROOT/'registers/POWER_BI_LOCK.json'))
        elif args.command=='runtime':result=check_locked_tree(args.root,load_json(ROOT/'registers/RESUME_RUNTIME_FILE_LOCK.json'),args.post_run)
        elif args.command=='manifest':result=check_manifest(args.root)
        elif args.command=='compare-extraction':result=compare_folder(args.file,args.folder)
        elif args.command=='seal':result=seal_evidence(args.folder)
        data={'status':result.pop('status','PASS'),'command':args.command,'checked_at_utc':datetime.now(timezone.utc).isoformat(),'host_platform':platform.platform(),'python':sys.version.split()[0],'details':result}
        write_report(report,data)
        print(f"{data['status']}: {report}")
        return 0 if data['status']=='PASS' else 2
    except (CheckError,OSError,ValueError,KeyError,zipfile.BadZipFile,RuntimeError) as exc:
        msg=f'{type(exc).__name__}: {exc}'
        print('STOP: '+msg,file=sys.stderr)
        # Best-effort failure receipt only to a genuinely new outside location.
        try:
            if not report.exists() and ROOT not in report.parents:
                safe=True
                for field in ['root','folder','extract']:
                    value=getattr(args,field,None)
                    if value and (report==value.absolute() or value.absolute() in report.parents):safe=False
                if safe:write_report(report,{'status':'FAIL','command':args.command,'failure':msg,'checked_at_utc':datetime.now(timezone.utc).isoformat()})
        except (OSError,CheckError):pass
        return 2

if __name__=='__main__':
    sys.exit(main())
