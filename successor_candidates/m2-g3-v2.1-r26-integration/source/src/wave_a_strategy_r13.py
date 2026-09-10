#!/usr/bin/env python3
"""Wave A R13 M2.8 retry-rounding correction over the retained R9 architecture.

R13 preserves the R9 terminal-state comparison contract, the R12 nullable-hash
semantics, all accepted source bytes, and every generation method except one
M2.8 expression. The corrected expression rounds the scheduled cent amount
before applying the retry catch-up multiplier. This aligns the retry event with
the ledger identity:

    processed = scheduled - returned + retry

No tolerance, policy, terminal-state, or source-mapping rule is relaxed.
"""
from __future__ import annotations
from copy import deepcopy
import wave_a_strategy_r9 as r9

CORRECTION_CODE = "WAVE_A_R13_M2_8_RETRY_ROUNDING_ALIGNMENT"
CORRECTION_VERSION = 1

# Exact expression in the accepted M2.8 generation source after predecessor
# hash and population-guard transformations. The anchor intentionally excludes
# the surrounding CASE so one and only one retry-settlement expression changes.
OLD_RETRY_EXPRESSION = (
    "round(round(m.source_exposure_amount/coalesce(m.source_setup_duration_days,"
    "c.default_setup_duration_days),2)*coalesce(m.source_payment_factor,"
    "c.default_temporary_payment_factor)*c.retry_catchup_multiplier,2)"
)
NEW_RETRY_EXPRESSION = (
    "round(round(round(m.source_exposure_amount/coalesce(m.source_setup_duration_days,"
    "c.default_setup_duration_days),2)*coalesce(m.source_payment_factor,"
    "c.default_temporary_payment_factor),2)*c.retry_catchup_multiplier,2)"
)

STAGE_ALIGNMENT = r9.STAGE_ALIGNMENT
VIEW_COLUMN_CONTRACT = r9.VIEW_COLUMN_CONTRACT


def patch_schema(stage: str, sql: str) -> str:
    """Retain the exact R9 terminal-state comparison views."""
    return r9.patch_schema(stage, sql)


def patch_generation(stage: str, sql: str) -> str:
    """Apply the sole R13 generation correction at M2.8."""
    sql = r9.patch_generation(stage, sql)
    if stage != "8":
        return sql
    count = sql.count(OLD_RETRY_EXPRESSION)
    if count != 1:
        raise RuntimeError(
            "R13 M2.8 retry-rounding anchor count mismatch: "
            f"expected=1 actual={count}"
        )
    corrected = sql.replace(OLD_RETRY_EXPRESSION, NEW_RETRY_EXPRESSION, 1)
    if OLD_RETRY_EXPRESSION in corrected:
        raise RuntimeError("R13 M2.8 old retry-rounding expression remains")
    if corrected.count(NEW_RETRY_EXPRESSION) != 1:
        raise RuntimeError("R13 M2.8 corrected retry-rounding expression is not unique")
    return corrected


def overlay_payload(stage: str) -> dict:
    """Version the R9 overlay and identify the sole M2.8 method correction."""
    payload = deepcopy(r9.overlay_payload(stage))
    payload["r13_successor_correction_code"] = CORRECTION_CODE
    payload["r13_successor_correction_version"] = CORRECTION_VERSION
    payload["policy_change"] = False
    payload["comparison_contract_changed_from_r9"] = False
    payload["nullable_hash_contract_changed_from_r12"] = False
    if stage == "8":
        payload["accepted_generation_method"] = "VERSIONED_M2_8_RETRY_ROUNDING_CORRECTION"
        payload["generation_correction"] = {
            "correction_code": CORRECTION_CODE,
            "correction_version": CORRECTION_VERSION,
            "defect_class": "GENERATION_ROUNDING_ORDER",
            "affected_expression": "SIMULATED_RETRY_SETTLED_PROCESSED_PAYMENT_AMOUNT",
            "old_semantics": "ROUND(ROUNDED_DAILY_AMOUNT * PAYMENT_FACTOR * RETRY_MULTIPLIER, 2)",
            "new_semantics": "ROUND(ROUND(ROUNDED_DAILY_AMOUNT * PAYMENT_FACTOR, 2) * RETRY_MULTIPLIER, 2)",
            "ledger_identity": "PROCESSED = SCHEDULED - RETURNED + RETRY",
            "policy_change": False,
            "expected_known_materiality_usd": "0.01",
            "expected_known_affected_paths": 1,
        }
    else:
        payload["accepted_generation_method"] = "UNCHANGED_FROM_R12"
        payload["generation_correction"] = None
    return payload


def configuration_payload() -> dict:
    return {
        "strategy_correction_id": "MSBF_M1M2_R1_WAVE_A_R13",
        "correction_code": CORRECTION_CODE,
        "correction_version": CORRECTION_VERSION,
        "governing_r9_configuration_sha256": None,
        "preserved_r9_terminal_alignment": True,
        "preserved_r12_nullable_hash_semantics": True,
        "policy_change": False,
        "accepted_source_bytes_changed": False,
        "generation_methods_changed": ["M2.8_RETRY_SETTLEMENT_ROUNDING_ORDER"],
        "stages": {f"M2.{s}": overlay_payload(s) for s in ["5", "6", "7", "8", "9", "10"]},
    }
