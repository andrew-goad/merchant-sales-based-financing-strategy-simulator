#!/usr/bin/env python3
"""Re-execute the exact runtime's M2.11 source-identity/simulation proof offline.

Requires an intact R26_R3_RESUME source root (validated before and after).
Does NOT connect to PostgreSQL, rebuild M2.1-M2.10, persist M2.12, refresh Power BI,
or issue acceptance. External processes/network sockets are blocked in this
proof process before importing the locked source; no runtime source is patched.
"""
from __future__ import annotations
import argparse
from datetime import datetime,timezone
from pathlib import Path
import platform
import socket
import subprocess
import sys
import traceback

sys.dont_write_bytecode=True
from runbook_checks import ROOT,CheckError,check_locked_tree,load_json,write_report

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--runtime',type=Path,required=True)
    p.add_argument('--report',type=Path,required=True)
    a=p.parse_args();report=a.report.absolute();runtime=a.runtime.absolute()
    if report.exists():p.error('Report already exists; choose a new evidence filename.')
    if runtime in report.parents or ROOT in report.parents:p.error('Report must be outside runtime and runbook directories.')
    attempts=[]
    def prohibited(*args,**kwargs):
        attempts.append('External process or network request rejected')
        raise CheckError('Offline proof forbids external process/network access.')
    try:
        lock=load_json(ROOT/'registers/RESUME_RUNTIME_FILE_LOCK.json')
        before=check_locked_tree(runtime,lock)
        # Guard rails complement, rather than replace, locked source inspection.
        subprocess.run=prohibited
        subprocess.Popen=prohibited
        subprocess.call=prohibited
        subprocess.check_call=prohibited
        subprocess.check_output=prohibited
        socket.socket=prohibited
        sys.path.insert(0,str(runtime/'src'))
        import run_r26
        proof=run_r26.r2_failure_reperformance()
        expected=load_json(ROOT/'registers/GOLDEN_R26_REFERENCE.json')
        master=expected['master_required']
        comp=proof['compiler'];fin=proof['final']
        if proof['status']!='PASS' or comp!=fin:raise CheckError('Offline source-identity proof failed.')
        if comp['source_root_sha256']!=master['source_root_sha256']:raise CheckError('Source root differs.')
        sim=comp['simulation_identity']
        if sim['bundle_sha256']!=master['simulation_bundle_sha256']:raise CheckError('Simulation root differs.')
        counts={'candidate_evaluation':52152,'application_simulation':12000,'account_simulation':1040,'portfolio_summary':24,'portfolio_frontier':24,'portfolio_comparison':21,'strategy_profiles':8}
        if any(sim[k]['rows']!=v for k,v in counts.items()):raise CheckError('Simulation populations differ.')
        after=check_locked_tree(runtime,lock)
        data={'status':'PASS','scope':'EXACT-SOURCE OFFLINE M2.11 SIMULATION AND CANONICALIZATION RE-PERFORMANCE ONLY',
              'checked_at_utc':datetime.now(timezone.utc).isoformat(),'python':platform.python_version(),
              'source_tree_before':before,'source_tree_after':after,'external_process_or_network_attempts':len(attempts),
              'database_execution_performed':False,'m2_1_to_m2_10_regeneration_performed':False,'m2_12_database_certification_performed':False,
              'power_bi_open_or_refresh_performed':False,'proof':proof}
        write_report(report,data)
        print(f'PASS: {report}');return 0
    except Exception as exc:
        data={'status':'FAIL','failure':str(exc),'checked_at_utc':datetime.now(timezone.utc).isoformat(),'external_process_or_network_attempts':len(attempts)}
        if not report.exists():write_report(report,data)
        print('STOP: '+str(exc),file=sys.stderr);return 2

if __name__=='__main__':sys.exit(main())
