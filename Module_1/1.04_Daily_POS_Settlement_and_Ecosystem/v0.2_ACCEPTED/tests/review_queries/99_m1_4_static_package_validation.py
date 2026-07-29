#!/usr/bin/env python3
"""Static package validation for MSBF M1.4 v0.2.

This script does not replace live PostgreSQL execution. It validates source-package
structure, controlled object references, DML targets, deterministic controls,
validation-code inventories, function signatures, documentation links, and catalogs.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
PHYSICAL_CATALOG = ROOT / 'catalogs' / 'M1_4_PHYSICAL_DEPENDENCY_COLUMNS.csv'

REQUIRED_FILES = [
    'README.md',
    'sql/25_msbf_m1_4_enterprise_merchant_ecosystem_generation_v0_2.sql',
    'sql/26_msbf_m1_4_enterprise_merchant_ecosystem_validation_v0_2.sql',
    'sql/27_msbf_m1_4_negative_control_tests_v0_2.sql',
    'sql/28_msbf_m1_4_acceptance_finalize_v0_2.sql',
    'tests/24_msbf_m1_4_preflight_validation_v0_2.sql',
    'tests/29_MSBF_M1_4_Enterprise_Merchant_Ecosystem_Master_Report_v0_2.sql',
    'tests/30_MSBF_M1_4_Enterprise_Merchant_Ecosystem_Detail_Report_v0_2.sql',
    'docs/M1_4_DESIGN_AND_GENERATION_SPECIFICATION.md',
    'docs/M1_4_EXECUTION_AND_VALIDATION_GUIDE.md',
    'docs/M1_4_VALIDATION_MATRIX.md',
    'catalogs/M1_4_EXECUTION_ORDER.csv',
    'catalogs/M1_4_PARAMETER_USAGE.csv',
    'catalogs/M1_4_FIELD_DICTIONARY.csv',
    'catalogs/M1_4_EXPECTED_RESULTS.json',
    'catalogs/M1_4_PHYSICAL_DEPENDENCY_COLUMNS.csv',
    'evidence/README.md',
    'evidence/templates/MSBF_M1_4_Enterprise_Merchant_Ecosystem_Build_Acceptance_Milestone_v0_2_template.txt',
    'NEXT_STEP_M1_5_DAILY_DEPOSIT_LIQUIDITY_HISTORY.md',
]

EXPECTED_FUNCTIONS = {
    'm1_4_pos_row_hash',
    'm1_4_assert_generation_ready',
    'm1_4_merchant_operating_profile',
    'm1_4_daily_pos_blueprint',
    'm1_4_expected_pos_snapshot',
    'm1_4_actual_pos_snapshot',
}

EXPECTED_HASHES = {
    'bd09e598c82db96e47459d77fd11e7c8',
    '462cbd2ed92f68e5bdecf6b17537a973',
    '93c3d1368fb2450ab4a08e2b721f92d3',
    '9b706c926260a3ef1ae8ac95eed5d0bf',
    '01485256b9b5748fb412743d35ced602',
}


def load_text(path: Path) -> str:
    return path.read_text(encoding='utf-8')


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    single = False
    double = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'" and not double:
            if single and i + 1 < len(text) and text[i + 1] == "'":
                buf.extend([ch, ch]); i += 2; continue
            single = not single
        elif ch == '"' and not single:
            double = not double
        elif not single and not double:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == ',' and depth == 0:
                parts.append(''.join(buf).strip())
                buf = []
                i += 1
                continue
        buf.append(ch)
        i += 1
    if ''.join(buf).strip():
        parts.append(''.join(buf).strip())
    return parts


def lexical_issues(sql: str, filename: str) -> list[str]:
    issues: list[str] = []
    # Remove comments for rough parentheses/quote checks.
    no_block = re.sub(r'/\*.*?\*/', '', sql, flags=re.S)
    no_line = re.sub(r'--[^\n]*', '', no_block)
    tags = re.findall(r'\$[A-Za-z0-9_]*\$', no_line)
    for tag in sorted(set(tags)):
        if tags.count(tag) % 2:
            issues.append(f'{filename}: unbalanced dollar quote {tag}')
    # Remove dollar bodies and quoted strings before counting parentheses.
    stripped = no_line
    for tag in sorted(set(tags), key=len, reverse=True):
        stripped = re.sub(re.escape(tag) + r'.*?' + re.escape(tag), '', stripped, flags=re.S)
    stripped = re.sub(r"'(?:''|[^'])*'", "''", stripped)
    if stripped.count('(') != stripped.count(')'):
        issues.append(f'{filename}: parentheses count {stripped.count("(")} != {stripped.count(")")}')
    if len(re.findall(r"(?<!')'(?!')", stripped)) % 2:
        issues.append(f'{filename}: unbalanced single quote')
    return issues


def markdown_links(text: str) -> Iterable[str]:
    for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', text):
        if not re.match(r'^(?:https?://|mailto:|#)', target):
            yield target.split('#', 1)[0]


def find_final_select(sql: str, start_marker: str, end_marker: str) -> list[str]:
    start = sql.index(start_marker) + len(start_marker)
    end = sql.index(end_marker, start)
    return split_top_level(sql[start:end])


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    metrics: dict[str, object] = {}

    for rel in REQUIRED_FILES:
        if not (ROOT / rel).exists():
            errors.append(f'missing required file: {rel}')

    sql_files = sorted((ROOT / 'sql').glob('*.sql')) + sorted((ROOT / 'tests').glob('*.sql'))
    sql_files = [p for p in sql_files if p.suffix == '.sql']
    sql_map = {p.name: load_text(p) for p in sql_files}
    all_sql = '\n'.join(sql_map.values())
    metrics['sql_file_count'] = len(sql_files)

    for name, text in sql_map.items():
        errors.extend(lexical_issues(text, name))

    # Determinism and safety controls.
    random_calls = [m.group(0) for m in re.finditer(r'(?<!deterministic_)\brandom\s*\(', all_sql, flags=re.I)]
    if random_calls:
        errors.append(f'prohibited session random() calls: {len(random_calls)}')
    if "#>> '{}'" in all_sql:
        errors.append("invalid structured JSON scalar extraction #>> '{}' found")
    destructive = re.findall(r'\b(?:TRUNCATE|DROP\s+TABLE|DELETE\s+FROM\s+msbf_m1\.merchant_pos_daily_base)\b', all_sql, flags=re.I)
    if destructive:
        errors.append(f'destructive M1.4 data operations found: {destructive}')
    if "DELETE FROM msbf_ctl.run_evidence\n WHERE run_id=v_run_id AND evidence_code ~ '^M1_4_POS_[0-9]{2}_';" not in sql_map.get('26_msbf_m1_4_enterprise_merchant_ecosystem_validation_v0_2.sql',''):
        errors.append('positive-validation evidence delete is not restricted to numbered validation codes')
    if "evidence_code ~ '^M1_4_POS_[0-9]{2}_'" not in sql_map.get('28_msbf_m1_4_acceptance_finalize_v0_2.sql',''):
        errors.append('acceptance finalizer does not isolate numbered positive checks from M1_4_POS_SET_HASH')

    # Function inventory and return/select cardinality.
    gen = sql_map.get('25_msbf_m1_4_enterprise_merchant_ecosystem_generation_v0_2.sql', '')
    functions = set(re.findall(r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+msbf_m1\.([A-Za-z0-9_]+)', gen, flags=re.I))
    metrics['helper_function_count'] = len(functions)
    metrics['helper_functions'] = sorted(functions)
    if functions != EXPECTED_FUNCTIONS:
        errors.append(f'function inventory mismatch: {sorted(functions)}')
    try:
        m = re.search(r'CREATE OR REPLACE FUNCTION msbf_m1\.m1_4_merchant_operating_profile\([^)]*\)\s*RETURNS TABLE\((.*?)\)\s*LANGUAGE', gen, re.S)
        profile_returns = split_top_level(m.group(1)) if m else []
        profile_select = find_final_select(gen, '\nSELECT\n c.run_id', '\nFROM calc c;')
        metrics['profile_return_columns'] = len(profile_returns)
        metrics['profile_select_columns'] = len(profile_select)
        if len(profile_returns) != 43 or len(profile_select) != 43:
            errors.append(f'operating-profile return/select count mismatch: {len(profile_returns)}/{len(profile_select)}')
        m = re.search(r'CREATE OR REPLACE FUNCTION msbf_m1\.m1_4_daily_pos_blueprint\([^)]*\)\s*RETURNS TABLE\((.*?)\)\s*LANGUAGE', gen, re.S)
        blueprint_returns = split_top_level(m.group(1)) if m else []
        blueprint_select = find_final_select(gen, '\nSELECT\n f.population_id', '\nFROM final_rows f;')
        metrics['blueprint_return_columns'] = len(blueprint_returns)
        metrics['blueprint_select_columns'] = len(blueprint_select)
        if len(blueprint_returns) != 36 or len(blueprint_select) != 36:
            errors.append(f'blueprint return/select count mismatch: {len(blueprint_returns)}/{len(blueprint_select)}')
    except Exception as exc:
        errors.append(f'function cardinality parser failed: {exc}')

    # Validation inventories.
    val = sql_map.get('26_msbf_m1_4_enterprise_merchant_ecosystem_validation_v0_2.sql', '')
    pos_codes = sorted(set(re.findall(r"'((?:M1_4_POS_)[0-9]{2}_[A-Z0-9_]+)'", val)))
    neg = sql_map.get('27_msbf_m1_4_negative_control_tests_v0_2.sql', '')
    neg_codes = sorted(set(re.findall(r"'(M1_4_NEG_[0-9]{2}_[A-Z0-9_]+)'", neg)))
    detail = sql_map.get('30_MSBF_M1_4_Enterprise_Merchant_Ecosystem_Detail_Report_v0_2.sql', '')
    detail_sets = re.findall(r'/\* Result set\s+([0-9]+)\s+—', detail)
    metrics['positive_evidence_codes'] = len(pos_codes)
    metrics['negative_evidence_codes'] = len(neg_codes)
    metrics['detail_result_sets'] = len(detail_sets)
    if len(pos_codes) != 52:
        errors.append(f'expected 52 positive evidence codes; observed {len(pos_codes)}')
    if len(neg_codes) != 4:
        errors.append(f'expected 4 negative controls; observed {len(neg_codes)}')
    if detail_sets != [str(i) for i in range(1, 15)]:
        errors.append(f'detail result-set sequence mismatch: {detail_sets}')

    # Required accepted identities and method controls.
    for expected_hash in EXPECTED_HASHES:
        if expected_hash not in all_sql:
            errors.append(f'accepted upstream hash missing from SQL package: {expected_hash}')
    required_tokens = [
        '135000', 'history_days=180', "DATE '2026-02-14'", "DATE '2026-05-25'", "DATE '2026-07-04'",
        'NOT_YET_ACTIVE', 'DEGRADED', 'OUTAGE', 'CONNECTED', 'DELAYED', 'DISCONNECTED',
        '750 merchants', 'M1_4_DAILY_POS_HISTORY', 'M1_4_ACCEPTED',
        'to_char(p_gross_pos_sales::numeric(18,2)', 'm1_4_pos_row_hash',
    ]
    for token in required_tokens:
        if token not in all_sql and token not in '\n'.join(load_text(p) for p in ROOT.rglob('*.md')):
            errors.append(f'required control token missing: {token}')

    # Physical DML target columns.
    if not PHYSICAL_CATALOG.exists():
        warnings.append(f'physical catalog unavailable: {PHYSICAL_CATALOG}')
    else:
        physical_rows = list(csv.DictReader(PHYSICAL_CATALOG.open(encoding='utf-8')))
        table_columns: dict[str, set[str]] = {}
        for row in physical_rows:
            table_columns.setdefault(f"{row['schema_name']}.{row['table_name']}", set()).add(row['column_name'])
        bad_dml: list[str] = []
        for name, text in sql_map.items():
            for match in re.finditer(r'INSERT\s+INTO\s+(msbf_(?:ctl|ref|m1)\.[A-Za-z0-9_]+)\s*\((.*?)\)\s*(?:VALUES|SELECT)', text, flags=re.I|re.S):
                table = match.group(1)
                cols = [c.strip().strip('"') for c in split_top_level(match.group(2))]
                if table in table_columns:
                    unknown = [c for c in cols if c not in table_columns[table]]
                    if unknown:
                        bad_dml.append(f'{name}: INSERT {table} unknown columns {unknown}')
            for match in re.finditer(r'UPDATE\s+(msbf_(?:ctl|ref|m1)\.[A-Za-z0-9_]+)\s+SET\s+(.*?)(?:\s+WHERE\s|;)', text, flags=re.I|re.S):
                table = match.group(1)
                assigns = split_top_level(match.group(2))
                cols = [a.split('=',1)[0].strip().strip('"') for a in assigns if '=' in a]
                if table in table_columns:
                    unknown = [c for c in cols if c not in table_columns[table]]
                    if unknown:
                        bad_dml.append(f'{name}: UPDATE {table} unknown columns {unknown}')
        metrics['invalid_dml_target_columns'] = len(bad_dml)
        errors.extend(bad_dml)

    # Parse catalogs.
    parse_errors: list[str] = []
    for path in sorted((ROOT/'catalogs').glob('*.json')):
        try: json.loads(path.read_text(encoding='utf-8'))
        except Exception as exc: parse_errors.append(f'{path.name}: {exc}')
    for path in sorted((ROOT/'catalogs').glob('*.csv')):
        try:
            with path.open(encoding='utf-8', newline='') as fh: list(csv.reader(fh))
        except Exception as exc: parse_errors.append(f'{path.name}: {exc}')
    metrics['catalog_parse_errors'] = len(parse_errors)
    errors.extend(parse_errors)

    # Documentation links and unfinished markers.
    broken_links: list[str] = []
    unfinished: list[str] = []
    for path in ROOT.rglob('*'):
        if not path.is_file() or path.name in {'M1_4_STATIC_VALIDATION.json','MANIFEST.csv','SHA256SUMS.txt','PACKAGE_VALIDATION_REPORT.md','99_m1_4_static_package_validation.py'}:
            continue
        if path.suffix.lower() in {'.md','.txt','.sql','.py','.csv','.json'}:
            text = path.read_text(encoding='utf-8', errors='replace')
            if re.search(r'\b(?:TODO|FIXME|TBD)\b', text, flags=re.I):
                unfinished.append(str(path.relative_to(ROOT)))
            if path.suffix.lower() == '.md':
                for target in markdown_links(text):
                    if target and not (path.parent / target).resolve().exists():
                        broken_links.append(f'{path.relative_to(ROOT)} -> {target}')
    metrics['broken_internal_links'] = len(broken_links)
    metrics['unfinished_marker_files'] = len(unfinished)
    errors.extend(f'broken link: {x}' for x in broken_links)
    errors.extend(f'unfinished marker: {x}' for x in unfinished)

    metrics['prohibited_random_calls'] = len(random_calls)
    metrics['destructive_operations'] = len(destructive)
    metrics['lexical_issue_count'] = sum(1 for e in errors if 'unbalanced' in e or 'parentheses count' in e)
    metrics['package_root'] = str(ROOT)
    metrics['overall_static_status'] = 'PASS' if not errors else 'FAIL'

    result = {'status': metrics['overall_static_status'], 'metrics': metrics, 'errors': errors, 'warnings': warnings}
    out = ROOT / 'catalogs' / 'M1_4_STATIC_VALIDATION.json'
    out.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))
    return 0 if not errors else 1


if __name__ == '__main__':
    sys.exit(main())
