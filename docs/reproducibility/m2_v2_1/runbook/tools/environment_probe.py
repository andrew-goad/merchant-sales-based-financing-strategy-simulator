#!/usr/bin/env python3
"""Collect tool identity without a database connection or installation changes.
The retained-final launcher is a Windows-specific approved-source path. This
probe records missing software and version deviations; it cannot qualify a run.
"""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys


def version_record(path: Path, args: list[str]) -> dict:
    if not path.is_file():return {'present':False,'path':str(path)}
    cp=subprocess.run([str(path),*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=20,check=False)
    return {'present':True,'path':str(path.resolve()),'exit_code':cp.returncode,'version':(cp.stdout+'\n'+cp.stderr).strip()}


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--pg-bin',type=Path,default=Path(r'C:\Program Files\PostgreSQL\17\bin'))
    p.add_argument('--report',type=Path,required=True)
    a=p.parse_args();out=a.report.absolute()
    if out.exists():p.error('Report exists; choose a new evidence filename.')
    for parent in [out,*out.parents]:
        if parent.is_symlink() or (hasattr(parent,'is_junction') and parent.is_junction()):p.error('No symlink/junction report destinations.')
    tools={};issues=[]
    for name in ('psql','createdb','dropdb','pg_dump','pg_restore'):
        path=a.pg_bin/(name+('.exe' if os.name=='nt' else ''))
        try:tools[name]=version_record(path,['--version'])
        except (OSError,subprocess.TimeoutExpired) as exc:tools[name]={'present':False,'error':str(exc)}
        record=tools[name]
        if not record.get('present') or record.get('exit_code')!=0:issues.append(name+': missing/unusable')
        elif not re.search(r'\b17\.',record['version']):issues.append(name+': not PostgreSQL 17.x')
    pw=shutil.which('pwsh')
    try:
        tools['PowerShell7']=version_record(Path(pw),['-NoProfile','-NonInteractive','-Command','$PSVersionTable.PSVersion.ToString()']) if pw else {'present':False}
    except (OSError,subprocess.TimeoutExpired) as exc:tools['PowerShell7']={'present':False,'error':str(exc)}
    ps_record=tools['PowerShell7']
    if not ps_record.get('present') or ps_record.get('exit_code')!=0:
        issues.append('PowerShell 7 missing/unusable')
    elif not re.match(r'^7\.',ps_record.get('version','').strip()):
        issues.append('PowerShell is not major version 7')
    if os.name!='nt':issues.append('Windows runtime path cannot be qualified on this host')
    if sys.version_info<(3,10):issues.append('Runbook toolkit needs Python 3.10 or later')
    launched=shutil.which('python')
    if not launched:issues.append('Original launcher requires python/python.exe on PATH, not py alone')
    tools['python']={'current':sys.executable,'version':platform.python_version(),'PATH_python':launched}
    report={'status':'HOLD' if issues else 'ENVIRONMENT_PRECHECK_PASS','scope':'TOOLS ONLY; NO DATABASE CONNECTION; NO RUNTIME OR PERFORMANCE CERTIFICATION',
        'checked_at_utc':datetime.now(timezone.utc).isoformat(),'os':platform.platform(),'machine_architecture':platform.machine(),'tools':tools,
        'recorded_reference_versions':{'PostgreSQL':'17.9','Python':'3.14.7','PowerShell':'7.6.5'},
        'qualification_note':'Reference versions are recorded historical evidence, not a direction to downgrade supported software. Record/approve any actual version difference and test the procedure in that environment.',
        'work_drive_free_bytes':shutil.disk_usage(Path.cwd()).free,'data_directory_free_space':'MUST CHECK ON ACTUAL POSTGRESQL DATA VOLUME','issues':issues}
    out.parent.mkdir(parents=True,exist_ok=True)
    with out.open('x',encoding='utf-8') as f:json.dump(report,f,indent=2);f.write('\n')
    print(f"{report['status']}: {out}")
    return 3 if issues else 0

if __name__=='__main__':sys.exit(main())
