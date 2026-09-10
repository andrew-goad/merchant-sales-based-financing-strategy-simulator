from __future__ import annotations

import copy
import hashlib
import json
import math
import re
from collections import Counter
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any


def canonical_hash(value: Any) -> str:
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    ).hexdigest()


def profile_rows(profile_contract: dict[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for profile in profile_contract["profiles"]:
        weights = profile["w"]
        rows.append(
            {
                "strategy_profile_code": profile["code"],
                "profile_sequence": profile["seq"],
                "selection_mode": profile["mode"],
                "exposure_direction": profile["exposure_direction"],
                "access_weight": weights["access"],
                "exposure_weight": weights["exposure"],
                "finance_weight": weights["finance"],
                "loss_weight": weights["loss"],
                "contribution_weight": weights["contribution"],
                "return_weight": weights["return"],
                "servicing_weight": weights["servicing"],
                "payment_weight": weights["payment"],
                "candidate_weight_total": profile["candidate_weight_total"],
                "scope_weight_total": profile["scope_weight_total"],
                "profile_contract_sha256": profile_contract["profile_contract_sha256"],
            }
        )
    return rows


def contract_tables(contract: dict[str, Any]) -> dict[str, list[dict[str, str]]]:
    return {
        "m2_11_strategy_profile": contract["profile_columns"],
        **contract["simulation_tables"],
        **contract.get("certification_tables", {}),
    }


def parse_ddl_tables(ddl: str, schema: str) -> dict[str, list[dict[str, str]]]:
    pattern = re.compile(
        rf"CREATE\s+TABLE\s+{re.escape(schema)}\.([A-Za-z0-9_]+)\s*\((.*?)\n\);",
        flags=re.IGNORECASE | re.DOTALL,
    )
    tables: dict[str, list[dict[str, str]]] = {}
    for table_name, body in pattern.findall(ddl):
        columns: list[dict[str, str]] = []
        for raw in body.splitlines():
            line = raw.strip().rstrip(",")
            if not line:
                continue
            upper = line.upper()
            if upper.startswith(("PRIMARY KEY", "UNIQUE", "FOREIGN KEY", "CHECK", "CONSTRAINT")):
                continue
            tokens = line.split()
            if len(tokens) < 2:
                raise ValueError(f"Unparseable DDL line in {table_name}: {raw!r}")
            col_type = tokens[1].lower()
            if col_type not in {"text", "integer", "numeric", "boolean", "date"}:
                raise ValueError(f"Unsupported DDL type in {table_name}.{tokens[0]}: {col_type}")
            columns.append({"name": tokens[0], "type": col_type})
        tables[table_name] = columns
    return tables


def ddl_contract_controls(ddl: str, contract: dict[str, Any]) -> list[dict[str, Any]]:
    controls: list[dict[str, Any]] = []

    def add(control_id: str, ok: bool, observed: Any, expected: Any) -> None:
        controls.append(
            {
                "control_id": control_id,
                "status": "PASS" if ok else "FAIL",
                "observed": observed,
                "expected": expected,
            }
        )

    expected = contract_tables(contract)
    parsed = parse_ddl_tables(ddl, contract["schema"])
    add("R19_DDL_TABLE_DOMAIN_EXACT", set(parsed) == set(expected), sorted(parsed), sorted(expected))
    for name in sorted(expected):
        add(
            f"R19_DDL_{name.upper()}_COLUMN_CONTRACT_EXACT",
            parsed.get(name) == expected[name],
            parsed.get(name),
            expected[name],
        )
    expected_views = sorted(contract.get("view_contracts", {}))
    observed_views = sorted(
        set(
            re.findall(
                rf"CREATE\s+VIEW\s+{re.escape(contract['schema'])}\.([A-Za-z0-9_]+)",
                ddl,
                flags=re.IGNORECASE,
            )
        )
    )
    add("R19_DDL_VIEW_DOMAIN_EXACT", observed_views == expected_views, observed_views, expected_views)
    table_body_pattern = re.compile(
        rf"CREATE\s+TABLE\s+{re.escape(contract['schema'])}\.([A-Za-z0-9_]+)\s*\((.*?)\n\);",
        flags=re.IGNORECASE | re.DOTALL,
    )
    table_bodies = {name: body for name, body in table_body_pattern.findall(ddl)}
    primary_key_tables = {
        "m2_11_strategy_profile",
        "m2_12_g3v2_certification_detail",
        "m2_12_g3v2_certification_master",
        "m2_12_report_manifest",
    }
    for table, grain in contract.get("grains", {}).items():
        body = table_bodies.get(table, "")
        escaped = [re.escape(column) for column in grain]
        if table in primary_key_tables:
            column = escaped[0]
            table_level = re.search(rf"PRIMARY\s+KEY\s*\(\s*{column}\s*\)", body, flags=re.IGNORECASE)
            inline = re.search(rf"^\s*{column}\s+[A-Za-z0-9_]+(?:\s+NOT\s+NULL)?\s+PRIMARY\s+KEY\b", body, flags=re.IGNORECASE | re.MULTILINE)
            present = bool(table_level or inline)
            expected_constraint = f"PRIMARY KEY ({grain[0]}) (inline or table-level)"
        else:
            joined = r"\s*,\s*".join(escaped)
            present = bool(re.search(rf"UNIQUE\s*\(\s*{joined}\s*\)", body, flags=re.IGNORECASE))
            expected_constraint = "UNIQUE (" + ", ".join(grain) + ")"
        add(
            f"R19_DDL_{table.upper()}_GRAIN_CONSTRAINT_PRESENT",
            present,
            present,
            expected_constraint,
        )
    return controls


def _is_numeric(value: Any) -> bool:
    if value in (None, ""):
        return True
    if isinstance(value, bool):
        return False
    try:
        d = Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        return False
    return d.is_finite()


def _is_integer(value: Any) -> bool:
    if value in (None, ""):
        return True
    if isinstance(value, bool):
        return False
    if isinstance(value, int):
        return True
    try:
        d = Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        return False
    return d.is_finite() and d == d.to_integral_value()


def _is_date(value: Any) -> bool:
    if value in (None, ""):
        return True
    if isinstance(value, date):
        return True
    try:
        date.fromisoformat(str(value))
        return True
    except ValueError:
        return False


def value_compatible(value: Any, expected_type: str) -> bool:
    if expected_type == "text":
        return value is None or isinstance(value, str)
    if expected_type == "numeric":
        return _is_numeric(value)
    if expected_type == "integer":
        return _is_integer(value)
    if expected_type == "boolean":
        return value is None or isinstance(value, bool)
    if expected_type == "date":
        return _is_date(value)
    return False


def grain_duplicate_count(rows: list[dict[str, Any]], grain: list[str]) -> int:
    counts = Counter(tuple(row.get(column) for column in grain) for row in rows)
    return sum(count - 1 for count in counts.values() if count > 1)


def simulation_payload_controls(
    simulation: dict[str, Any],
    profile_contract: dict[str, Any],
    table_contract: dict[str, Any],
) -> list[dict[str, Any]]:
    controls: list[dict[str, Any]] = []

    def add(control_id: str, ok: bool, observed: Any, expected: Any) -> None:
        controls.append(
            {
                "control_id": control_id,
                "status": "PASS" if ok else "FAIL",
                "observed": observed,
                "expected": expected,
            }
        )

    rows_by_table = {
        "m2_11_strategy_profile": profile_rows(profile_contract),
        "m2_11_candidate_profile_evaluation": simulation["candidate_evaluation"],
        "m2_11_application_strategy_simulation": simulation["application_simulation"],
        "m2_11_account_strategy_simulation": simulation["account_simulation"],
        "m2_11_portfolio_strategy_summary": simulation["portfolio_summary"],
        "m2_11_portfolio_strategy_frontier": simulation["portfolio_frontier"],
        "m2_11_portfolio_strategy_comparison": simulation["portfolio_comparison"],
    }
    table_columns = contract_tables(table_contract)
    profile_codes = {row["strategy_profile_code"] for row in rows_by_table["m2_11_strategy_profile"]}
    for table, rows in rows_by_table.items():
        expected_columns = [c["name"] for c in table_columns[table]]
        observed_columns = list(rows[0]) if rows else []
        add(
            f"R19_PAYLOAD_{table.upper()}_COLUMN_ORDER_EXACT",
            observed_columns == expected_columns,
            observed_columns,
            expected_columns,
        )
        expected_rows = table_contract["expected_rows"][table]
        add(f"R19_PAYLOAD_{table.upper()}_ROW_COUNT", len(rows) == expected_rows, len(rows), expected_rows)
        wrong_shapes = sum(list(row) != expected_columns for row in rows)
        add(f"R19_PAYLOAD_{table.upper()}_ROW_SHAPE_EXACT", wrong_shapes == 0, wrong_shapes, 0)
        incompatible: list[dict[str, Any]] = []
        for row_index, row in enumerate(rows):
            for col in table_columns[table]:
                if not value_compatible(row.get(col["name"]), col["type"]):
                    incompatible.append(
                        {
                            "row_index": row_index,
                            "column": col["name"],
                            "expected_type": col["type"],
                            "value": repr(row.get(col["name"]))[:200],
                        }
                    )
                    if len(incompatible) >= 20:
                        break
            if len(incompatible) >= 20:
                break
        add(f"R19_PAYLOAD_{table.upper()}_TYPE_COMPATIBLE", not incompatible, incompatible, [])
        grain = table_contract["grains"][table]
        duplicates = grain_duplicate_count(rows, grain)
        add(f"R19_PAYLOAD_{table.upper()}_GRAIN_UNIQUE", duplicates == 0, duplicates, 0)
        if table.startswith("m2_11_") and table != "m2_11_strategy_profile":
            bad_hashes = 0
            for row in rows:
                payload = dict(row)
                stored = payload.pop("row_hash")
                if canonical_hash(payload) != stored:
                    bad_hashes += 1
            add(f"R19_PAYLOAD_{table.upper()}_ROW_HASH_RECOMPUTES", bad_hashes == 0, bad_hashes, 0)
        profile_fields = [name for name in expected_columns if "strategy_profile_code" in name]
        invalid_profiles = 0
        for row in rows:
            for field in profile_fields:
                if row.get(field) not in (None, "") and row.get(field) not in profile_codes:
                    invalid_profiles += 1
        add(f"R19_PAYLOAD_{table.upper()}_PROFILE_REFERENCE_VALID", invalid_profiles == 0, invalid_profiles, 0)
    return controls


def all_pass(controls: list[dict[str, Any]]) -> bool:
    return all(control["status"] == "PASS" for control in controls)


def failure_controls(controls: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [control for control in controls if control["status"] != "PASS"]
