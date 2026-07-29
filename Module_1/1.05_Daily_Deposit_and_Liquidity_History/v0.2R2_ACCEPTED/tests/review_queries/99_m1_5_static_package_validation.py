#!/usr/bin/env python3
"""Static validation for MSBF M1.5 v0.2 source package.

This validator does not replace live PostgreSQL execution. It verifies package
integrity, SQL source structure, controlled-code inventory, physical DML target
alignment, deterministic-design controls, documentation links, and machine-
readable catalogs before delivery.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
G0_CATALOG = Path('/mnt/data/_full_m1_4_extract/MSBF_M1_4/02_G0/catalogs/physical_schema_column_catalog.csv')

SQL_FILES = sorted((ROOT / 'sql').glob('*.sql')) + sorted((ROOT / 'tests').glob('*.sql'))
SQL_FILES = [p for p in SQL_FILES if p.name != Path(__file__).name]

EXPECTED_SQL_NAMES = [
    '31_msbf_m1_5_preflight_validation_v0_2.sql',
    '32_msbf_m1_5_daily_deposit_liquidity_generation_v0_2.sql',
    '33_msbf_m1_5_daily_deposit_liquidity_validation_v0_2.sql',
    '34_msbf_m1_5_negative_control_tests_v0_2.sql',
    '35_msbf_m1_5_acceptance_finalize_v0_2.sql',
    '36_MSBF_M1_5_Daily_Deposit_Liquidity_Master_Report_v0_2.sql',
    '37_MSBF_M1_5_Daily_Deposit_Liquidity_Detail_Report_v0_2.sql',
]
EXPECTED_FUNCTIONS = {
    'msbf_m1.m1_5_deposit_row_hash',
    'msbf_m1.m1_5_assert_generation_ready',
    'msbf_m1.m1_5_merchant_liquidity_profile',
    'msbf_m1.m1_5_daily_liquidity_blueprint',
    'msbf_m1.m1_5_expected_deposit_snapshot',
    'msbf_m1.m1_5_actual_deposit_snapshot',
}
EXPECTED_UPSTREAM_HASHES = {
    'bd09e598c82db96e47459d77fd11e7c8',
    '462cbd2ed92f68e5bdecf6b17537a973',
    '93c3d1368fb2450ab4a08e2b721f92d3',
    '9b706c926260a3ef1ae8ac95eed5d0bf',
    '01485256b9b5748fb412743d35ced602',
    'd1971e8d319483c187ec0c0483a31e33',
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def split_top_level(text: str, delimiter: str = ',') -> list[str]:
    out: list[str] = []
    start = 0
    depth = 0
    in_single = False
    in_double = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_single:
            if ch == "'" and i + 1 < len(text) and text[i + 1] == "'":
                i += 2
                continue
            if ch == "'":
                in_single = False
        elif in_double:
            if ch == '"' and i + 1 < len(text) and text[i + 1] == '"':
                i += 2
                continue
            if ch == '"':
                in_double = False
        else:
            if ch == "'":
                in_single = True
            elif ch == '"':
                in_double = True
            elif ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == delimiter and depth == 0:
                out.append(text[start:i].strip())
                start = i + 1
        i += 1
    out.append(text[start:].strip())
    return [x for x in out if x]


def lexical_balance(text: str) -> dict[str, object]:
    """Scan SQL for unbalanced comments, strings, dollar tags, and parentheses."""
    paren = 0
    min_paren = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    dollar_tag: str | None = None
    i = 0
    while i < len(text):
        if in_line_comment:
            if text[i] == '\n':
                in_line_comment = False
            i += 1
            continue
        if in_block_comment:
            if text.startswith('*/', i):
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue
        if dollar_tag is not None:
            if text.startswith(dollar_tag, i):
                i += len(dollar_tag)
                dollar_tag = None
            else:
                # Parentheses inside PL/pgSQL/SQL function bodies still matter.
                ch = text[i]
                if ch == "'":
                    # Keep string handling inside dollar body simple but exact.
                    j = i + 1
                    while j < len(text):
                        if text[j] == "'":
                            if j + 1 < len(text) and text[j + 1] == "'":
                                j += 2
                                continue
                            break
                        j += 1
                    i = min(j + 1, len(text))
                    continue
                if text.startswith('--', i):
                    j = text.find('\n', i + 2)
                    i = len(text) if j < 0 else j
                    continue
                if text.startswith('/*', i):
                    j = text.find('*/', i + 2)
                    i = len(text) if j < 0 else j + 2
                    continue
                if ch == '(':
                    paren += 1
                elif ch == ')':
                    paren -= 1
                    min_paren = min(min_paren, paren)
                i += 1
            continue
        if in_single:
            if text[i] == "'" and i + 1 < len(text) and text[i + 1] == "'":
                i += 2
                continue
            if text[i] == "'":
                in_single = False
            i += 1
            continue
        if in_double:
            if text[i] == '"' and i + 1 < len(text) and text[i + 1] == '"':
                i += 2
                continue
            if text[i] == '"':
                in_double = False
            i += 1
            continue
        if text.startswith('--', i):
            in_line_comment = True
            i += 2
            continue
        if text.startswith('/*', i):
            in_block_comment = True
            i += 2
            continue
        m = re.match(r'\$[A-Za-z_][A-Za-z0-9_]*\$|\$\$', text[i:])
        if m:
            dollar_tag = m.group(0)
            i += len(dollar_tag)
            continue
        ch = text[i]
        if ch == "'":
            in_single = True
        elif ch == '"':
            in_double = True
        elif ch == '(':
            paren += 1
        elif ch == ')':
            paren -= 1
            min_paren = min(min_paren, paren)
        i += 1
    return {
        'parenthesis_balance': paren,
        'minimum_parenthesis_balance': min_paren,
        'unterminated_single_quote': in_single,
        'unterminated_double_quote': in_double,
        'unterminated_block_comment': in_block_comment,
        'unterminated_dollar_tag': dollar_tag,
    }


def load_physical_catalog() -> dict[str, set[str]]:
    if not G0_CATALOG.exists():
        raise FileNotFoundError(f'Physical catalog not found: {G0_CATALOG}')
    by_table: dict[str, set[str]] = {}
    with G0_CATALOG.open(newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            key = f"{row['schema_name']}.{row['table_name']}"
            by_table.setdefault(key, set()).add(row['column_name'])
    return by_table


def markdown_links(path: Path) -> Iterable[str]:
    text = path.read_text(encoding='utf-8')
    for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
            continue
        yield target.split('#', 1)[0]


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    checks: dict[str, object] = {}

    names = [p.name for p in SQL_FILES]
    checks['sql_files'] = names
    checks['sql_file_count'] = len(SQL_FILES)
    if sorted(names) != sorted(EXPECTED_SQL_NAMES):
        errors.append(f'SQL inventory mismatch. Observed={names}')

    sql_text_by_file = {p.name: p.read_text(encoding='utf-8') for p in SQL_FILES}
    all_sql = '\n'.join(sql_text_by_file.values())
    checks['sql_source_lines'] = sum(t.count('\n') + 1 for t in sql_text_by_file.values())

    balances = {name: lexical_balance(text) for name, text in sql_text_by_file.items()}
    checks['lexical_balance'] = balances
    for name, result in balances.items():
        if result['parenthesis_balance'] != 0 or result['minimum_parenthesis_balance'] < 0:
            errors.append(f'{name}: parenthesis imbalance {result}')
        if any(result[k] for k in ('unterminated_single_quote', 'unterminated_double_quote', 'unterminated_block_comment', 'unterminated_dollar_tag')):
            errors.append(f'{name}: unterminated lexical construct {result}')

    functions = set(re.findall(r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+([\w]+\.[\w]+)', all_sql, re.I))
    checks['function_inventory'] = sorted(functions)
    if functions != EXPECTED_FUNCTIONS:
        errors.append(f'Function inventory mismatch. Observed={sorted(functions)}')

    pos_codes = re.findall(r"'((?:M1_5_POS_)\d{2}_[A-Z0-9_]+)'", sql_text_by_file['33_msbf_m1_5_daily_deposit_liquidity_validation_v0_2.sql'])
    neg_codes = re.findall(r"'((?:M1_5_NEG_)\d{2}_[A-Z0-9_]+)'", sql_text_by_file['34_msbf_m1_5_negative_control_tests_v0_2.sql'])
    pos_unique = sorted(set(pos_codes))
    neg_unique = sorted(set(neg_codes))
    checks['positive_validation_codes'] = pos_unique
    checks['negative_control_codes'] = neg_unique
    if len(pos_unique) != 56 or len(pos_codes) != 56:
        errors.append(f'Expected 56 unique positive controls, observed {len(pos_unique)} unique / {len(pos_codes)} occurrences.')
    if len(neg_unique) != 4 or len(neg_codes) != 4:
        errors.append(f'Expected 4 unique negative controls, observed {len(neg_unique)} unique / {len(neg_codes)} occurrences.')
    if pos_unique and ([int(re.search(r'_POS_(\d{2})_', c).group(1)) for c in pos_unique] != list(range(1, 57))):
        errors.append('Positive control numbering is not contiguous 01–56.')
    if neg_unique and ([int(re.search(r'_NEG_(\d{2})_', c).group(1)) for c in neg_unique] != list(range(1, 5))):
        errors.append('Negative control numbering is not contiguous 01–04.')

    detail_text = sql_text_by_file['37_MSBF_M1_5_Daily_Deposit_Liquidity_Detail_Report_v0_2.sql']
    result_sets = re.findall(r'/\*\s*Result set\s+(\d+)\s+—\s+([^*]+?)\s*\*/', detail_text)
    checks['detail_result_sets'] = [{'number': int(n), 'name': s.strip()} for n, s in result_sets]
    if [int(n) for n, _ in result_sets] != list(range(1, 15)):
        errors.append(f'Expected detail result sets 1–14, observed {result_sets}.')

    # Deterministic controls.
    session_random_calls = re.findall(r'(?<![A-Za-z_])random\s*\(', all_sql, re.I)
    checks['session_random_calls'] = len(session_random_calls)
    if session_random_calls:
        errors.append('Session-level random() call detected.')
    if "#>> '{}'" in all_sql or '#>>\'{}\'' in all_sql:
        errors.append('Invalid JSONB root scalar extraction detected.')
    for h in EXPECTED_UPSTREAM_HASHES:
        if h not in all_sql:
            errors.append(f'Required accepted upstream hash absent from SQL package: {h}')
    required_literals = ['135000', '750', '180', 'M1_4_ACCEPTED', 'M1_5_GENERATED', 'M1_5_VALIDATED', 'M1_5_ACCEPTED']
    for lit in required_literals:
        if lit not in all_sql:
            errors.append(f'Required stage literal absent from SQL package: {lit}')

    # Prohibit destructive business-table operations. Evidence re-creation is allowed.
    destructive = []
    for name, text in sql_text_by_file.items():
        for m in re.finditer(r'\b(TRUNCATE|DROP\s+TABLE|DELETE\s+FROM)\s+(msbf_m1\.[\w]+)', text, re.I):
            destructive.append({'file': name, 'operation': m.group(1), 'object': m.group(2)})
    checks['destructive_business_operations'] = destructive
    if destructive:
        errors.append(f'Destructive permanent M1 business-table operations detected: {destructive}')

    # Validate INSERT and UPDATE target columns against accepted physical catalog.
    physical = load_physical_catalog()
    dml_errors: list[dict[str, object]] = []
    for name, text in sql_text_by_file.items():
        for m in re.finditer(r'INSERT\s+INTO\s+([\w]+\.[\w]+)\s*\((.*?)\)\s*(?:VALUES|SELECT)', text, re.I | re.S):
            table = m.group(1)
            cols = [c.strip().strip('"') for c in split_top_level(m.group(2))]
            if table not in physical:
                dml_errors.append({'file': name, 'operation': 'INSERT', 'table': table, 'error': 'unknown table'})
            else:
                missing = [c for c in cols if c not in physical[table]]
                if missing:
                    dml_errors.append({'file': name, 'operation': 'INSERT', 'table': table, 'missing_columns': missing})
        for m in re.finditer(r'UPDATE\s+([\w]+\.[\w]+)\s+SET\s+(.*?)(?=\s+WHERE\s|\s+FROM\s|;)', text, re.I | re.S):
            table = m.group(1)
            cols = re.findall(r'(?:^|,)\s*([\w]+)\s*=', m.group(2))
            if table not in physical:
                dml_errors.append({'file': name, 'operation': 'UPDATE', 'table': table, 'error': 'unknown table'})
            else:
                missing = [c for c in cols if c not in physical[table]]
                if missing:
                    dml_errors.append({'file': name, 'operation': 'UPDATE', 'table': table, 'missing_columns': missing})
    checks['dml_target_errors'] = dml_errors
    if dml_errors:
        errors.append(f'Physical DML target validation failed: {dml_errors}')

    # Function result-shape controls for the two wide SQL functions.
    generation = sql_text_by_file['32_msbf_m1_5_daily_deposit_liquidity_generation_v0_2.sql']
    shape_results: dict[str, dict[str, int]] = {}
    shape_specs = [
        ('m1_5_merchant_liquidity_profile', 'FROM final_profile b;', 43),
        ('m1_5_daily_liquidity_blueprint', 'FROM final_rows f', 39),
    ]
    for func, final_from, expected in shape_specs:
        start = generation.find(f'FUNCTION msbf_m1.{func}')
        end = generation.find('$fn$;', start)
        block = generation[start:end]
        m_ret = re.search(r'RETURNS\s+TABLE\s*\((.*?)\)\s*LANGUAGE', block, re.I | re.S)
        if not m_ret:
            errors.append(f'{func}: RETURNS TABLE list not found.')
            continue
        return_count = len(split_top_level(m_ret.group(1)))
        from_pos = block.rfind(final_from)
        select_pos = block.rfind('SELECT', 0, from_pos)
        select_list = block[select_pos + len('SELECT'):from_pos]
        select_count = len(split_top_level(select_list))
        shape_results[func] = {'return_columns': return_count, 'select_expressions': select_count, 'expected': expected}
        if return_count != expected or select_count != expected or return_count != select_count:
            errors.append(f'{func}: result-shape mismatch {shape_results[func]}')
    checks['wide_function_result_shapes'] = shape_results

    # Required accounting/hash controls must be present.
    control_snippets = [
        'closing_balance_calc-b.hold_amount_calc',
        'opening_balance+deposit_amount-withdrawal_amount',
        'base_pos_deposit_amount+non_pos_support_deposit_amount',
        'm1_5_deposit_row_hash',
        'M1_5_DEPOSIT_SET_HASH',
        'CONTRACT_READY_PRE_GENERATION',
        'DEPOSIT_DAILY',
        'support_deposit_increment',
        'existing_financing_remittance_amount',
        'negative_balance_flag IS DISTINCT FROM (minimum_balance<0)',
    ]
    missing_controls = [s for s in control_snippets if s not in all_sql]
    checks['missing_control_snippets'] = missing_controls
    if missing_controls:
        errors.append(f'Missing required design/control snippets: {missing_controls}')

    # Parse JSON and CSV catalogs.
    parse_errors: list[str] = []
    json_files = sorted(ROOT.rglob('*.json'))
    csv_files = sorted(ROOT.rglob('*.csv'))
    for p in json_files:
        try:
            json.loads(p.read_text(encoding='utf-8'))
        except Exception as exc:
            parse_errors.append(f'{p.relative_to(ROOT)}: JSON: {exc}')
    for p in csv_files:
        try:
            with p.open(newline='', encoding='utf-8-sig') as f:
                list(csv.reader(f))
        except Exception as exc:
            parse_errors.append(f'{p.relative_to(ROOT)}: CSV: {exc}')
    checks['catalog_parse_errors'] = parse_errors
    if parse_errors:
        errors.extend(parse_errors)

    # Catalog-specific counts.
    with (ROOT / 'catalogs' / 'M1_5_PARAMETER_USAGE.csv').open(newline='', encoding='utf-8-sig') as f:
        parameter_rows = list(csv.DictReader(f))
    with (ROOT / 'catalogs' / 'M1_5_PHYSICAL_DEPENDENCY_COLUMNS.csv').open(newline='', encoding='utf-8-sig') as f:
        dependency_rows = list(csv.DictReader(f))
    checks['required_parameter_scope_rows'] = len(parameter_rows)
    checks['physical_dependency_column_rows'] = len(dependency_rows)
    checks['physical_dependency_table_count'] = len({(r['schema_name'], r['table_name']) for r in dependency_rows})
    if len(parameter_rows) != 32:
        errors.append(f'Expected 32 parameter/scope rows, observed {len(parameter_rows)}.')

    # Internal Markdown links.
    broken_links: list[str] = []
    for p in sorted(ROOT.rglob('*.md')):
        for target in markdown_links(p):
            resolved = (p.parent / target).resolve()
            if not resolved.exists():
                broken_links.append(f'{p.relative_to(ROOT)} -> {target}')
    checks['broken_internal_links'] = broken_links
    if broken_links:
        errors.append(f'Broken internal Markdown links: {broken_links}')

    # Unfinished markers and known prior typo patterns.
    text_files = [p for p in ROOT.rglob('*') if p.is_file() and p.suffix.lower() in {'.md', '.txt', '.sql', '.json', '.csv'}]
    unfinished: list[str] = []
    for p in text_files:
        text = p.read_text(encoding='utf-8-sig', errors='replace')
        for token in ('TODO', 'FIXME', 'TBD', '[INSERT', 'Gbserve'):
            if token.lower() in text.lower():
                unfinished.append(f'{p.relative_to(ROOT)}: {token}')
    checks['unfinished_markers'] = unfinished
    if unfinished:
        errors.append(f'Unfinished markers found: {unfinished}')

    # Metadata consistency.
    metadata_path = ROOT / 'PACKAGE_METADATA.json'
    metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
    expected_meta = {
        'sql_files': 7,
        'positive_validations': 56,
        'negative_controls': 4,
        'detail_result_sets': 14,
        'expected_rows': 135000,
    }
    metadata_mismatch = {k: {'expected': v, 'actual': metadata.get(k)} for k, v in expected_meta.items() if metadata.get(k) != v}
    checks['metadata_mismatch'] = metadata_mismatch
    if metadata_mismatch:
        errors.append(f'Package metadata mismatch: {metadata_mismatch}')

    report = {
        'package': metadata.get('package_name'),
        'version': metadata.get('version'),
        'static_status': 'PASS' if not errors else 'FAIL',
        'errors': errors,
        'warnings': warnings,
        'checks': checks,
        'file_hashes': {
            str(p.relative_to(ROOT)): sha256(p)
            for p in sorted(ROOT.rglob('*'))
            if p.is_file()
            and p != Path(__file__)
            and p.name not in {'M1_5_STATIC_VALIDATION.json', 'MANIFEST.csv', 'SHA256SUMS.txt'}
        },
    }
    out = ROOT / 'catalogs' / 'M1_5_STATIC_VALIDATION.json'
    out.write_text(json.dumps(report, indent=2), encoding='utf-8')

    print(json.dumps({
        'static_status': report['static_status'],
        'error_count': len(errors),
        'warning_count': len(warnings),
        'sql_files': len(SQL_FILES),
        'sql_source_lines': checks['sql_source_lines'],
        'functions': len(functions),
        'positive_controls': len(pos_unique),
        'negative_controls': len(neg_unique),
        'detail_result_sets': len(result_sets),
        'parameter_scope_rows': len(parameter_rows),
        'dependency_tables': checks['physical_dependency_table_count'],
        'dependency_columns': len(dependency_rows),
        'dml_target_errors': len(dml_errors),
        'broken_links': len(broken_links),
        'unfinished_markers': len(unfinished),
    }, indent=2))
    if errors:
        for error in errors:
            print(f'ERROR: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
