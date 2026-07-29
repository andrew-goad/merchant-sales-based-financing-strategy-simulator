#!/usr/bin/env python3
"""Static package validation for MSBF M1.2 v0.2R2.

This script does not replace live PostgreSQL execution. It checks package completeness,
lexical balance, physical INSERT/UPDATE column references, evidence-code counts,
prohibited randomness/destructive operations, catalogs, and internal documentation links.
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
CATALOG = ROOT / "catalogs" / "M1_2_PHYSICAL_DEPENDENCY_COLUMNS.csv"
OUT = ROOT / "catalogs" / "M1_2_STATIC_VALIDATION.json"

EXPECTED_FILES = [
    "README.md",
    "HOTFIX_NOTES_v0_2R1.md",
    "HOTFIX_NOTES_v0_2R2.md",
    "RELEASE_NOTES.md",
    "NEXT_STEP_M1_3_APPLICATION_REQUEST_GENERATION.md",
    "docs/M1_2_DESIGN_AND_GENERATION_SPECIFICATION.md",
    "docs/M1_2_EXECUTION_AND_VALIDATION_GUIDE.md",
    "docs/M1_2_VALIDATION_MATRIX.md",
    "catalogs/M1_2_RUN_CONFIGURATION.json",
    "catalogs/M1_2_EXPECTED_RESULTS.json",
    "catalogs/M1_2_GOVERNED_MIX_TARGETS.csv",
    "catalogs/M1_2_PHYSICAL_DEPENDENCY_COLUMNS.csv",
    "catalogs/M1_2_CANONICAL_SCALE_RECONCILIATION.json",
    "tests/09_msbf_m1_2_failed_generation_recovery_check_v0_2R2.sql",
    "tests/10_msbf_m1_2_preflight_validation_v0_2.sql",
    "sql/11_msbf_m1_2_deterministic_merchant_population_v0_2.sql",
    "sql/12_msbf_m1_2_population_validation_v0_2.sql",
    "sql/13_msbf_m1_2_negative_control_tests_v0_2.sql",
    "sql/14_msbf_m1_2_acceptance_finalize_v0_2.sql",
    "tests/15_MSBF_M1_2_Deterministic_Merchant_Population_Master_Report_v0_2.sql",
    "tests/16_MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2.sql",
    "evidence/README.md",
    "evidence/templates/MSBF_M1_2_Deterministic_Merchant_Population_Build_Acceptance_Milestone_v0_2_template.txt",
]

EXPECTED_FUNCTIONS = {
    "msbf_m1.m1_2_assert_generation_ready",
    "msbf_m1.m1_2_weighted_assignment",
    "msbf_m1.m1_2_weighted_assignment_json",
    "msbf_m1.m1_2_population_blueprint",
    "msbf_m1.m1_2_owner_blueprint",
    "msbf_m1.m1_2_expected_entity_snapshot",
    "msbf_m1.m1_2_actual_entity_snapshot",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def read_columns() -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    with CATALOG.open(newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            key = f"{row['schema_name']}.{row['table_name']}".lower()
            result.setdefault(key, set()).add(row["column_name"].lower())
    return result


def remove_dollar_markers(text: str) -> tuple[str, dict[str, int]]:
    tags = re.findall(r"\$[A-Za-z_][A-Za-z0-9_]*\$|\$\$", text)
    counts = Counter(tags)
    return re.sub(r"\$[A-Za-z_][A-Za-z0-9_]*\$|\$\$", "", text), dict(counts)


def lexical_balance(text: str) -> dict[str, object]:
    text, tag_counts = remove_dollar_markers(text)
    paren = 0
    bracket = 0
    min_paren = 0
    min_bracket = 0
    i = 0
    state = "normal"
    while i < len(text):
        ch = text[i]
        nx = text[i + 1] if i + 1 < len(text) else ""
        if state == "line_comment":
            if ch == "\n":
                state = "normal"
            i += 1
            continue
        if state == "block_comment":
            if ch == "*" and nx == "/":
                state = "normal"
                i += 2
            else:
                i += 1
            continue
        if state == "single":
            if ch == "'" and nx == "'":
                i += 2
            elif ch == "'":
                state = "normal"
                i += 1
            else:
                i += 1
            continue
        if state == "double":
            if ch == '"' and nx == '"':
                i += 2
            elif ch == '"':
                state = "normal"
                i += 1
            else:
                i += 1
            continue
        if ch == "-" and nx == "-":
            state = "line_comment"
            i += 2
            continue
        if ch == "/" and nx == "*":
            state = "block_comment"
            i += 2
            continue
        if ch == "'":
            state = "single"
            i += 1
            continue
        if ch == '"':
            state = "double"
            i += 1
            continue
        if ch == "(":
            paren += 1
        elif ch == ")":
            paren -= 1
            min_paren = min(min_paren, paren)
        elif ch == "[":
            bracket += 1
        elif ch == "]":
            bracket -= 1
            min_bracket = min(min_bracket, bracket)
        i += 1
    odd_tags = {k: v for k, v in tag_counts.items() if v % 2}
    return {
        "parenthesis_balance": paren,
        "minimum_parenthesis_balance": min_paren,
        "bracket_balance": bracket,
        "minimum_bracket_balance": min_bracket,
        "ending_lexical_state": state,
        "dollar_tag_counts": tag_counts,
        "odd_dollar_tags": odd_tags,
        "pass": paren == 0 and min_paren >= 0 and bracket == 0 and min_bracket >= 0 and state == "normal" and not odd_tags,
    }


def extract_insert_targets(text: str) -> list[tuple[str, list[str]]]:
    results = []
    pattern = re.compile(r"\bINSERT\s+INTO\s+(msbf_[a-z0-9_]+\.[a-z0-9_]+)\s*\((.*?)\)\s*(?:VALUES|SELECT)", re.I | re.S)
    for m in pattern.finditer(text):
        table = m.group(1).lower()
        cols = [c.strip().strip('"').lower() for c in m.group(2).split(",") if c.strip()]
        results.append((table, cols))
    return results


def extract_update_targets(text: str) -> list[tuple[str, list[str]]]:
    results = []
    # Direct UPDATE statements only; ON CONFLICT DO UPDATE clauses are excluded.
    pattern = re.compile(r"(?<!DO\s)\bUPDATE\s+(msbf_[a-z0-9_]+\.[a-z0-9_]+)(?:\s+[a-z][a-z0-9_]*)?\s+SET\s+(.*?)(?=\s+WHERE\b)", re.I | re.S)
    for m in pattern.finditer(text):
        table = m.group(1).lower()
        set_text = m.group(2)
        cols = re.findall(r"(?:^|,)\s*([a-z_][a-z0-9_]*)\s*=", set_text, re.I | re.M)
        results.append((table, [c.lower() for c in cols]))
    return results


def validate_targets(sql_files: Iterable[Path], columns: dict[str, set[str]]) -> dict[str, object]:
    insert_errors = []
    update_errors = []
    inserts = 0
    updates = 0
    for path in sql_files:
        text = path.read_text(encoding="utf-8")
        for table, cols in extract_insert_targets(text):
            inserts += 1
            if table not in columns:
                insert_errors.append({"file": str(path.relative_to(ROOT)), "table": table, "error": "table_not_in_dependency_catalog"})
                continue
            bad = sorted(set(cols) - columns[table])
            if bad:
                insert_errors.append({"file": str(path.relative_to(ROOT)), "table": table, "invalid_columns": bad})
        for table, cols in extract_update_targets(text):
            updates += 1
            if table not in columns:
                update_errors.append({"file": str(path.relative_to(ROOT)), "table": table, "error": "table_not_in_dependency_catalog"})
                continue
            bad = sorted(set(cols) - columns[table])
            if bad:
                update_errors.append({"file": str(path.relative_to(ROOT)), "table": table, "invalid_columns": bad})
    return {
        "insert_statements_checked": inserts,
        "update_statements_checked": updates,
        "insert_target_errors": insert_errors,
        "update_target_errors": update_errors,
        "pass": not insert_errors and not update_errors,
    }


def validate_markdown_links(md_files: Iterable[Path]) -> list[dict[str, str]]:
    broken = []
    for path in md_files:
        text = path.read_text(encoding="utf-8")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            target = target.strip().split("#", 1)[0]
            if not target or re.match(r"^(?:https?://|mailto:|sandbox:)", target):
                continue
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                broken.append({"file": str(path.relative_to(ROOT)), "target": target})
    return broken


def main() -> int:
    sql_files = sorted(ROOT.glob("sql/*.sql")) + sorted(ROOT.glob("tests/*.sql"))
    md_files = sorted(ROOT.rglob("*.md"))
    txt_files = sorted(ROOT.rglob("*.txt"))
    all_text_files = sql_files + md_files + txt_files
    columns = read_columns()

    missing_files = [p for p in EXPECTED_FILES if not (ROOT / p).exists()]
    lexical = {str(p.relative_to(ROOT)): lexical_balance(p.read_text(encoding="utf-8")) for p in sql_files}
    lexical_errors = [p for p, v in lexical.items() if not v["pass"]]

    target_validation = validate_targets(sql_files, columns)
    generation_text = (ROOT / "sql/11_msbf_m1_2_deterministic_merchant_population_v0_2.sql").read_text(encoding="utf-8")
    validation_text = (ROOT / "sql/12_msbf_m1_2_population_validation_v0_2.sql").read_text(encoding="utf-8")
    negative_text = (ROOT / "sql/13_msbf_m1_2_negative_control_tests_v0_2.sql").read_text(encoding="utf-8")
    finalizer_text = (ROOT / "sql/14_msbf_m1_2_acceptance_finalize_v0_2.sql").read_text(encoding="utf-8")
    detail_text = (ROOT / "tests/16_MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2.sql").read_text(encoding="utf-8")

    function_names = set(re.findall(r"CREATE\s+OR\s+REPLACE\s+FUNCTION\s+([a-z0-9_.]+)", generation_text, re.I))
    positive_codes = sorted(set(re.findall(r"'((?:M1_2_POS_)[A-Z0-9_]+)'", validation_text)))
    negative_codes = sorted(set(re.findall(r"'((?:M1_2_NEG_)[A-Z0-9_]+)'", negative_text)))
    result_sets = len(re.findall(r"/\*\s*Result set\s+\d+", detail_text, re.I))

    prohibited_random = []
    destructive = []
    wrong_run_columns = []
    structured_snapshot_scalar_extractions = []
    untyped_canonical_zero_branches = []
    wrong_patterns = {
        "merchant_application uses module1_run_id": r"msbf_m1\.merchant_application(?:\s+[a-z][a-z0-9_]*)?\s+WHERE\s+(?:[a-z][a-z0-9_]*\.)?module1_run_id\b",
        "daily base uses module1_run_id": r"msbf_m1\.merchant_(?:pos|deposit)_daily_base(?:\s+[a-z][a-z0-9_]*)?\s+WHERE\s+(?:[a-z][a-z0-9_]*\.)?module1_run_id\b",
        "source snapshot uses created_by_run_id": r"msbf_m1\.source_snapshot(?:\s+[a-z][a-z0-9_]*)?\s+WHERE\s+(?:[a-z][a-z0-9_]*\.)?created_by_run_id\b",
    }
    for p in sql_files:
        text = p.read_text(encoding="utf-8")
        if re.search(r"\brandom\s*\(", text, re.I):
            prohibited_random.append(str(p.relative_to(ROOT)))
        if re.search(r"resolved_value\s*#>>\s*['\"]\{\}['\"]", text, re.I):
            structured_snapshot_scalar_extractions.append(str(p.relative_to(ROOT)))
        if re.search(r"THEN\s+0::numeric(?!\s*\()", text, re.I):
            untyped_canonical_zero_branches.append(str(p.relative_to(ROOT)))
        if re.search(r"\b(?:TRUNCATE|DROP\s+TABLE|DELETE\s+FROM\s+msbf_m1\.(?:merchant_master|merchant_owner_guarantor|merchant_industry_assignment|processor_account|merchant_relationship_snapshot))\b", text, re.I):
            destructive.append(str(p.relative_to(ROOT)))
        for label, pat in wrong_patterns.items():
            if re.search(pat, text, re.I | re.S):
                wrong_run_columns.append({"file": str(p.relative_to(ROOT)), "pattern": label})

    placeholders = []
    for p in all_text_files:
        text = p.read_text(encoding="utf-8")
        if re.search(r"\b(?:TODO|FIXME|TBD)\b", text, re.I):
            placeholders.append(str(p.relative_to(ROOT)))

    broken_links = validate_markdown_links(md_files)

    json_errors = []
    for p in sorted(ROOT.rglob("*.json")):
        try:
            json.loads(p.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - evidence output
            json_errors.append({"file": str(p.relative_to(ROOT)), "error": str(exc)})

    csv_errors = []
    csv_counts = {}
    for p in sorted(ROOT.rglob("*.csv")):
        try:
            with p.open(newline="", encoding="utf-8") as f:
                rows = list(csv.reader(f))
            if not rows:
                raise ValueError("empty CSV")
            csv_counts[str(p.relative_to(ROOT))] = max(len(rows) - 1, 0)
        except Exception as exc:
            csv_errors.append({"file": str(p.relative_to(ROOT)), "error": str(exc)})

    required_literals = {
        "generation_canonical_entity_lock": "v_expected_entities<>4352" in generation_text.replace(" ", ""),
        "validation_positive_count_lock": "v_count<>36" in validation_text.replace(" ", ""),
        "finalizer_positive_lock": "v_positive_count=36" in finalizer_text.replace(" ", ""),
        "finalizer_negative_lock": "v_negative_count=3" in finalizer_text.replace(" ", ""),
        "generation_transaction": generation_text.count("BEGIN;") >= 1 and generation_text.count("COMMIT;") >= 1,
        "regeneration_prohibition": "regeneration is prohibited" in generation_text,
        "expected_actual_snapshot_comparison": "m1_2_expected_entity_snapshot" in generation_text and "m1_2_actual_entity_snapshot" in generation_text,
        "accepted_g1_parameter_hash": "bd09e598c82db96e47459d77fd11e7c8" in generation_text,
        "accepted_g1_profile_hash": "462cbd2ed92f68e5bdecf6b17537a973" in generation_text,
        "accepted_g1_source_hash": "93c3d1368fb2450ab4a08e2b721f92d3" in generation_text,
        "funded_amount_physical_scale": "'total_prior_funded_amount',p.total_prior_funded_amount::numeric(18,2)" in generation_text,
        "repaid_amount_physical_scale": "'total_prior_repaid_amount',p.total_prior_repaid_amount::numeric(18,2)" in generation_text,
        "guarantee_capacity_physical_scale": "'guarantee_capacity_amount',f.guarantee_capacity_amount::numeric(18,2)" in generation_text,
        "owner_rate_physical_scale": "'ownership_rate',f.ownership_rate::numeric(9,6)" in generation_text,
        "wallet_share_physical_scale": "'wallet_share_proxy',p.wallet_share_proxy::numeric(9,6)" in generation_text,
        "mismatch_entity_summary": "v_mismatch_summary" in generation_text and "v_mismatch_examples" in generation_text,
    }

    findings = {
        "package_root": str(ROOT),
        "sql_file_count": len(sql_files),
        "expected_file_count": len(EXPECTED_FILES),
        "missing_required_files": missing_files,
        "physical_dependency_table_count": len(columns),
        "physical_dependency_column_count": sum(len(v) for v in columns.values()),
        "lexical_validation": lexical,
        "lexical_error_files": lexical_errors,
        "target_column_validation": target_validation,
        "helper_functions_found": sorted(function_names),
        "helper_function_count": len(function_names),
        "missing_helper_functions": sorted(EXPECTED_FUNCTIONS - function_names),
        "unexpected_helper_functions": sorted(function_names - EXPECTED_FUNCTIONS),
        "positive_evidence_code_count": len(positive_codes),
        "positive_evidence_codes": positive_codes,
        "negative_evidence_code_count": len(negative_codes),
        "negative_evidence_codes": negative_codes,
        "detail_report_result_set_count": result_sets,
        "prohibited_random_references": prohibited_random,
        "destructive_population_operations": destructive,
        "wrong_known_run_column_patterns": wrong_run_columns,
        "structured_snapshot_scalar_extractions": structured_snapshot_scalar_extractions,
        "untyped_canonical_zero_branches": untyped_canonical_zero_branches,
        "placeholder_files": placeholders,
        "broken_markdown_links": broken_links,
        "json_parse_errors": json_errors,
        "csv_parse_errors": csv_errors,
        "csv_data_row_counts": csv_counts,
        "required_literal_checks": required_literals,
    }

    pass_flags = {
        "required_files": not missing_files,
        "lexical": not lexical_errors,
        "physical_targets": target_validation["pass"],
        "helper_functions": function_names == EXPECTED_FUNCTIONS,
        "positive_checks": len(positive_codes) == 36,
        "negative_controls": len(negative_codes) == 3,
        "detail_result_sets": result_sets == 10,
        "no_random": not prohibited_random,
        "no_destructive_population_sql": not destructive,
        "no_wrong_run_columns": not wrong_run_columns,
        "typed_snapshot_accessors": not structured_snapshot_scalar_extractions,
        "canonical_numeric_scale_controls": not untyped_canonical_zero_branches,
        "no_placeholders": not placeholders,
        "links": not broken_links,
        "json": not json_errors,
        "csv": not csv_errors,
        "required_literals": all(required_literals.values()),
    }
    findings["validation_flags"] = pass_flags
    findings["overall_static_status"] = "PASS" if all(pass_flags.values()) else "FAIL"

    OUT.write_text(json.dumps(findings, indent=2), encoding="utf-8")
    print(json.dumps({
        "overall_static_status": findings["overall_static_status"],
        "sql_files": len(sql_files),
        "helper_functions": len(function_names),
        "positive_checks": len(positive_codes),
        "negative_controls": len(negative_codes),
        "detail_result_sets": result_sets,
        "missing_files": len(missing_files),
        "lexical_errors": len(lexical_errors),
        "insert_update_target_errors": len(target_validation["insert_target_errors"]) + len(target_validation["update_target_errors"]),
        "broken_links": len(broken_links),
    }, indent=2))
    return 0 if findings["overall_static_status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
