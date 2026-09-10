"""Version-probe tests use mocked binaries. They are not Windows qualification."""
from pathlib import Path
import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

SRC=Path(__file__).resolve().parents[1]/'tools/environment_probe.py'
spec=importlib.util.spec_from_file_location('environment_probe_under_test',SRC)
ep=importlib.util.module_from_spec(spec);spec.loader.exec_module(ep)

class ProbeTests(unittest.TestCase):
    def run_probe(self, ps='7.6.5', exit_code=0, pg='17.9', present=True):
        with tempfile.TemporaryDirectory() as td:
            out=Path(td)/'report.json'
            def version(p,args):
                return {'present':True,'exit_code':exit_code,'version':ps} if p.name=='pwsh' else {'present':True,'exit_code':0,'version':'PostgreSQL '+pg}
            def which(name):
                return ('/mock/pwsh' if present else None) if name=='pwsh' else '/mock/python'
            with patch.object(sys,'argv',['environment_probe.py','--report',str(out)]),patch.object(ep,'version_record',version),patch.object(ep.shutil,'which',which),contextlib.redirect_stdout(io.StringIO()):
                code=ep.main()
            return code,json.loads(out.read_text())
    def test_ps7_recognized(self):
        _,r=self.run_probe();self.assertFalse(any(x.startswith('PowerShell') for x in r['issues']))
    def test_wrong_ps_major(self):
        _,r=self.run_probe(ps='6.2.0');self.assertIn('PowerShell is not major version 7',r['issues'])
    def test_ps_nonzero_rejected(self):
        _,r=self.run_probe(exit_code=1);self.assertIn('PowerShell 7 missing/unusable',r['issues'])
    def test_ps_missing(self):
        _,r=self.run_probe(present=False);self.assertIn('PowerShell 7 missing/unusable',r['issues'])
    def test_pg_major_mismatch(self):
        _,r=self.run_probe(pg='16.4');self.assertEqual(sum('not PostgreSQL 17.x' in x for x in r['issues']),5)
    def test_existing_report_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            out=Path(td)/'report.json';out.write_text('retain')
            with patch.object(sys,'argv',['environment_probe.py','--report',str(out)]),contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):ep.main()
            self.assertEqual(out.read_text(),'retain')
if __name__=='__main__':unittest.main(verbosity=2)
