"""Offline tests of the new control-party toolkit. No database is contacted."""
from pathlib import Path
import contextlib
import csv
import hashlib
import io
import json
import os
import stat
import sys
import tempfile
import unittest
import warnings
import zipfile
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import runbook_checks as rc

class Fixture(unittest.TestCase):
    def setUp(self):self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
    def tearDown(self):self.temp.cleanup()
    def archive(self, members=None, filename='source.zip'):
        p=self.root/filename
        with zipfile.ZipFile(p,'w',zipfile.ZIP_DEFLATED) as z:
            for n,b in (members or [('a/file.txt',b'example')]):z.writestr(n,b)
        return p
    def expect_reject(self,members):
        with self.assertRaises((rc.CheckError,zipfile.BadZipFile)):rc.inspect_zip(self.archive(members))

class ArchiveSafety(Fixture):
    def test_valid_zip(self):self.assertEqual(rc.inspect_zip(self.archive())['regular_files'],1)
    def test_traversal(self):self.expect_reject([('../outside',b'x')])
    def test_absolute(self):self.expect_reject([('/outside',b'x')])
    def test_drive(self):self.expect_reject([('C:/outside',b'x')])
    def test_backslash(self):self.expect_reject([('..\\outside',b'x')])
    def test_reserved(self):self.expect_reject([('folder/NUL.txt',b'x')])
    def test_trailing_dot(self):self.expect_reject([('folder./x',b'x')])
    def test_trailing_space(self):self.expect_reject([('folder /x',b'x')])
    def test_case_collision(self):self.expect_reject([('folder/a',b'x'),('folder/A',b'y')])
    def test_parent_case_collision(self):self.expect_reject([('Folder/a',b'x'),('folder/b',b'y')])
    def test_duplicates(self):
        with warnings.catch_warnings():
            warnings.simplefilter('ignore');self.expect_reject([('a',b'x'),('a',b'y')])
    def test_file_directory_collision(self):self.expect_reject([('a',b'x'),('a/b',b'y')])
    def test_symlink_member(self):
        info=zipfile.ZipInfo('link');info.create_system=3;info.external_attr=(stat.S_IFLNK|0o777)<<16
        self.expect_reject([(info,b'../outside')])
    def test_path_length(self):
        with self.assertRaises(rc.CheckError):rc.inspect_zip(self.archive([('x'*235,b'a')]))
    def test_nonzip(self):
        p=self.root/'bad.zip';p.write_bytes(b'not a zip')
        with self.assertRaises(zipfile.BadZipFile):rc.inspect_zip(p)
    def test_clean_extract_and_compare(self):
        p=self.archive();dest=self.root/'unpacked';rc.safe_extract(p,dest)
        self.assertEqual(rc.compare_folder(p,dest)['files_verified'],1)
    def test_existing_destination_not_reused(self):
        p=self.archive();dest=self.root/'unpacked';dest.mkdir()
        with self.assertRaises(rc.CheckError):rc.safe_extract(p,dest)
    def test_extraction_extra_file(self):
        p=self.archive();dest=self.root/'unpacked';rc.safe_extract(p,dest);(dest/'extra').write_text('x')
        with self.assertRaises(rc.CheckError):rc.compare_folder(p,dest)
    def test_extraction_modified_file(self):
        p=self.archive();dest=self.root/'unpacked';rc.safe_extract(p,dest);(dest/'a/file.txt').write_text('changed')
        with self.assertRaises(rc.CheckError):rc.compare_folder(p,dest)
    def test_source_archive_unchanged(self):
        p=self.archive();before=p.read_bytes();rc.safe_extract(p,self.root/'unpacked');self.assertEqual(p.read_bytes(),before)

class RuntimeTree(Fixture):
    def fixture(self):
        r=self.root/'runtime';r.mkdir();(r/'code.py').write_bytes(b'print(1)\n')
        return r,{'files':{'code.py':{'bytes':9,'sha256':rc.hash_bytes(b'print(1)\n')}}}
    def test_tree_pass(self):
        r,l=self.fixture();self.assertEqual(rc.check_locked_tree(r,l)['files_verified'],1)
    def test_tree_tamper(self):
        r,l=self.fixture();(r/'code.py').write_bytes(b'print(2)\n')
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(r,l)
    def test_missing_source(self):
        r,l=self.fixture();(r/'code.py').unlink()
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(r,l)
    def test_extra_bytecode_blocks_prerun(self):
        r,l=self.fixture();(r/'__pycache__').mkdir();(r/'__pycache__/x.pyc').write_bytes(b'anything')
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(r,l)
    def test_previous_result_blocks_prerun(self):
        r,l=self.fixture();(r/'results').mkdir();(r/'results/run.zip').write_bytes(b'x')
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(r,l)
    def test_postrun_allows_only_results(self):
        r,l=self.fixture();(r/'results').mkdir();(r/'results/run.zip').write_bytes(b'x')
        self.assertEqual(rc.check_locked_tree(r,l,post_run=True)['ignored_runtime_output_files'],1)
        (r/'other').write_bytes(b'x')
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(r,l,post_run=True)
    def test_link_block(self):
        r,l=self.fixture();(self.root/'link').symlink_to(r,target_is_directory=True)
        with self.assertRaises(rc.CheckError):rc.check_locked_tree(self.root/'link',l)

class InputAndEvidence(Fixture):
    def test_csv_ragged(self):
        with self.assertRaises(rc.CheckError):rc.csv_records(b'a,b\n1\n')
    def test_csv_duplicate_columns(self):
        with self.assertRaises(rc.CheckError):rc.csv_records(b'a,a\n1,2\n')
    def test_empty_evidence_rejected(self):
        with self.assertRaises(rc.CheckError):rc.seal_evidence(self.root)
    def test_evidence_hashes(self):
        (self.root/'test').write_bytes(b'x');r=rc.seal_evidence(self.root)
        self.assertEqual(r['file_count'],1);self.assertEqual(r['files'][0]['sha256'],rc.hash_bytes(b'x'))
    def test_report_overwrite_rejected(self):
        p=self.root/'report.json';rc.write_report(p,{'status':'PASS'})
        with self.assertRaises(FileExistsError):rc.write_report(p,{'status':'FAIL'})
        self.assertEqual(json.loads(p.read_text())['status'],'PASS')
    def test_cli_unknown_component(self):
        p=self.archive();out=self.root/'report.json'
        with contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()):
            ret=rc.main(['verify','--component','UNAPPROVED','--file',str(p),'--report',str(out)])
        self.assertEqual(ret,2);self.assertEqual(json.loads(out.read_text())['status'],'FAIL')
    def test_cli_report_inside_checked_tree_rejected(self):
        folder=self.root/'evidence';folder.mkdir();(folder/'a').write_bytes(b'x')
        with contextlib.redirect_stderr(io.StringIO()):r=rc.main(['seal','--folder',str(folder),'--report',str(folder/'receipt.json')])
        self.assertEqual(r,2);self.assertFalse((folder/'receipt.json').exists())

class ActualEvidence(Fixture):
    @classmethod
    def setUpClass(cls):
        gold=os.environ.get('MSBF_GOLDEN_RESULT')
        cls.gold=Path(gold) if gold else None
        cls.pbix=Path(os.environ['MSBF_PBIX']) if os.environ.get('MSBF_PBIX') else None
        cls.ref=rc.load_json(rc.ROOT/'registers/GOLDEN_R26_REFERENCE.json')
    def required(self):
        if self.gold is None or not self.gold.is_file():self.skipTest('Actual golden source not supplied; tests may not be relabeled complete.')
    def mutate(self,name,fn):
        self.required();p=self.root/'mutated.zip'
        with zipfile.ZipFile(self.gold) as inz,zipfile.ZipFile(p,'w',zipfile.ZIP_DEFLATED) as out:
            for n in inz.namelist():
                b=inz.read(n)
                if n==name:b=fn(b)
                if b is not None:out.writestr(n,b)
        return p
    def test_actual_golden_reconciliation(self):
        self.required();self.assertEqual(rc.reconcile_result(self.gold,self.ref)['status'],'PASS')
    def test_failed_receipt_blocked(self):
        def f(b):o=json.loads(b);o['status']='FAIL';return json.dumps(o).encode()
        p=self.mutate('R26_RESUME_RECEIPT.json',f);self.assertEqual(rc.reconcile_result(p,self.ref)['status'],'FAIL')
    def test_wrong_source_database_blocked(self):
        def f(b):o=json.loads(b);o['source_db']='other';return json.dumps(o).encode()
        p=self.mutate('R26_RESUME_RECEIPT.json',f);self.assertEqual(rc.reconcile_result(p,self.ref)['status'],'FAIL')
    def test_new_run_metadata_permitted(self):
        def f(b):
            o=json.loads(b);o['resume_database']=o['resume_db']='msbf_r1_r26_resume_g3v2_20260905_123456'
            o['started_at_utc']='2026-09-05T12:34:56+00:00';o['completed_at_utc']='2026-09-05T12:45:00+00:00';return json.dumps(o).encode()
        p=self.mutate('R26_RESUME_RECEIPT.json',f);r=rc.reconcile_result(p,self.ref)
        self.assertEqual(r['status'],'PASS');self.assertFalse(r['golden_outer_identity_equal'])
    def test_missing_monitoring_rejected(self):
        p=self.mutate('evidence/resume_wave_a_exports/m2_5_r26.csv',lambda b:None)
        with self.assertRaises(KeyError):rc.reconcile_result(p,self.ref)
    def test_nonmutation_assertion_false_blocked(self):
        def f(b):o=json.loads(b);o['r6_schema_exact']=False;return json.dumps(o).encode()
        p=self.mutate('evidence/05_NONMUTATION.json',f);self.assertEqual(rc.reconcile_result(p,self.ref)['status'],'FAIL')
    def test_control_failure_blocked(self):
        p=self.mutate('evidence/resume_g3/v_p06_g3v2_certification.csv',lambda b:b.replace(b',PASS,',b',FAIL,',1))
        self.assertEqual(rc.reconcile_result(p,self.ref)['status'],'FAIL')
    def test_actual_pbix_identity(self):
        if self.pbix is None:self.skipTest('Actual PBIX not supplied')
        self.assertEqual(rc.verify_pbix(self.pbix,rc.load_json(rc.ROOT/'registers/POWER_BI_LOCK.json'))['status'],'PASS')
    def test_changed_pbix_blocked(self):
        p=self.root/'wrong.pbix';p.write_bytes(b'wrong')
        with self.assertRaises(rc.CheckError):rc.verify_pbix(p,rc.load_json(rc.ROOT/'registers/POWER_BI_LOCK.json'))

if __name__=='__main__':unittest.main(verbosity=2)
