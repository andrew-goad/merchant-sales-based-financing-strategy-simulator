#!/usr/bin/env python3
"""Wave A R15 deterministic source-payload canonicalization.

R15 preserves the owner-approved R1 strategy, the R9 terminal-state comparison
alignment, the R12 nullable-hash semantics, the R13 retry-rounding correction,
and the R14 Power BI export-identity contract. It changes only six downstream
source-evidence expressions at M2.7-M2.10 so run-generated ``created_at`` values
from predecessor rows are not embedded inside ``source_payload`` and therefore
cannot contaminate deterministic row/set/contract hashes.

Accepted source SQL bytes are not modified. The correction is applied only to
versioned transformed successor SQL.
"""
from __future__ import annotations
from copy import deepcopy
import wave_a_strategy_r13 as r13

CORRECTION_CODE = "WAVE_A_R15_SOURCE_PAYLOAD_CREATED_AT_CANONICALIZATION"
CORRECTION_VERSION = 1

# Re-export controlling predecessor contracts used by the runtime and static
# verifier. The R13 retry correction remains exact and unchanged.
OLD_RETRY_EXPRESSION = r13.OLD_RETRY_EXPRESSION
NEW_RETRY_EXPRESSION = r13.NEW_RETRY_EXPRESSION
STAGE_ALIGNMENT = r13.STAGE_ALIGNMENT
VIEW_COLUMN_CONTRACT = r13.VIEW_COLUMN_CONTRACT

# Exact transformed-generation anchors and replacements. Every anchor must be
# present exactly once at its governed stage. No generic SQL rewriting occurs.
GENERATION_REPLACEMENTS = {
    "7": [
        (
            "to_jsonb(source) AS source_payload",
            "(to_jsonb(source)-'created_at') AS source_payload",
            "M2.6 intervention-strategy latest -> M2.7 operational source",
        ),
    ],
    "8": [
        (
            "c.source_combined_set_hash,to_jsonb(s) source_payload,NULL::text row_hash",
            "c.source_combined_set_hash,(to_jsonb(s)-'created_at') source_payload,NULL::text row_hash",
            "M2.7 operational latest -> M2.8 servicing source",
        ),
    ],
    "9": [
        (
            "ctx.source_combined_set_hash,to_jsonb(source) source_payload",
            "ctx.source_combined_set_hash,(to_jsonb(source)-'created_at') source_payload",
            "M2.8 servicing latest -> M2.9 account source",
        ),
        (
            "ctx.source_combined_set_hash,to_jsonb(payment) source_payload",
            "ctx.source_combined_set_hash,(to_jsonb(payment)-'created_at') source_payload",
            "M2.8 payment event -> M2.9 payment source",
        ),
        (
            "ctx.source_combined_set_hash,to_jsonb(transition) source_payload",
            "ctx.source_combined_set_hash,(to_jsonb(transition)-'created_at') source_payload",
            "M2.8 lifecycle transition -> M2.9 transition source",
        ),
    ],
    "10": [
        (
            "ctx.source_combined_set_hash,to_jsonb(source) AS source_payload",
            "ctx.source_combined_set_hash,(to_jsonb(source)-'created_at') AS source_payload",
            "M2.9 certification latest -> M2.10 portfolio source",
        ),
    ],
}


def patch_schema(stage: str, sql: str) -> str:
    """Retain the exact R9/R13 schema and terminal-state comparison contract."""
    return r13.patch_schema(stage, sql)


def patch_generation(stage: str, sql: str) -> str:
    """Apply R13 retry rounding, then the six exact R15 payload replacements."""
    corrected = r13.patch_generation(stage, sql)
    replacements = GENERATION_REPLACEMENTS.get(stage, [])
    for old, new, label in replacements:
        count = corrected.count(old)
        if count != 1:
            raise RuntimeError(
                f"R15 source-payload anchor count mismatch stage=M2.{stage} "
                f"label={label!r} expected=1 actual={count}"
            )
        corrected = corrected.replace(old, new, 1)
        if old in corrected:
            raise RuntimeError(
                f"R15 old source-payload expression remains stage=M2.{stage} label={label!r}"
            )
        if corrected.count(new) != 1:
            raise RuntimeError(
                f"R15 canonical source-payload expression is not unique "
                f"stage=M2.{stage} label={label!r}"
            )
    return corrected


def overlay_payload(stage: str) -> dict:
    """Version R13 without changing policy, terminal, nullable-hash, or rounding rules."""
    payload = deepcopy(r13.overlay_payload(stage))
    if stage not in GENERATION_REPLACEMENTS:
        return payload
    payload["r15_successor_correction_code"] = CORRECTION_CODE
    payload["r15_successor_correction_version"] = CORRECTION_VERSION
    payload["policy_change"] = False
    payload["accepted_source_bytes_changed"] = False
    payload["comparison_contract_changed_from_r9"] = False
    payload["nullable_hash_contract_changed_from_r12"] = False
    payload["retry_rounding_contract_changed_from_r13"] = False
    payload["power_bi_export_contract_changed_from_r14"] = False
    payload["source_payload_canonicalization"] = [
        {
            "boundary": label,
            "removed_top_level_key": "created_at",
            "reason": "EXCLUDE_RUN_GENERATED_PREDECESSOR_TIMESTAMP_FROM_DETERMINISTIC_EVIDENCE_HASH",
            "policy_change": False,
        }
        for _, _, label in GENERATION_REPLACEMENTS.get(stage, [])
    ]
    if stage in GENERATION_REPLACEMENTS:
        payload["accepted_generation_method"] = (
            "VERSIONED_R13_RETRY_ROUNDING_PLUS_R15_SOURCE_PAYLOAD_CANONICALIZATION"
            if stage == "8"
            else "VERSIONED_R15_SOURCE_PAYLOAD_CANONICALIZATION"
        )
    return payload


def configuration_payload() -> dict:
    boundaries = []
    for stage, replacements in GENERATION_REPLACEMENTS.items():
        for old, new, label in replacements:
            boundaries.append(
                {
                    "stage": f"M2.{stage}",
                    "boundary": label,
                    "old_expression": old,
                    "new_expression": new,
                    "removed_top_level_key": "created_at",
                }
            )
    return {
        "strategy_correction_id": "MSBF_M1M2_R1_WAVE_A_R15",
        "correction_code": CORRECTION_CODE,
        "correction_version": CORRECTION_VERSION,
        "defect_class": "RUN_GENERATED_TIMESTAMP_EMBEDDED_IN_NESTED_SOURCE_EVIDENCE",
        "lowest_correct_remediation_layer": "GENERATION_SOURCE_PAYLOAD_CANONICALIZATION",
        "governing_r13_configuration_sha256": None,
        "governing_r14_configuration_sha256": None,
        "governing_r14_result_sha256": None,
        "preserved_r9_terminal_alignment": True,
        "preserved_r12_nullable_hash_semantics": True,
        "preserved_r13_retry_rounding": True,
        "preserved_r14_power_bi_export_identity": True,
        "exact_compiler_final_identity_required": True,
        "policy_change": False,
        "accepted_source_bytes_changed": False,
        "validator_business_controls_changed": False,
        "generation_methods_changed": [
            "M2.7_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
            "M2.8_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
            "M2.9_ACCOUNT_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
            "M2.9_PAYMENT_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
            "M2.9_TRANSITION_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
            "M2.10_SOURCE_PAYLOAD_CREATED_AT_EXCLUSION",
        ],
        "canonicalization_boundaries": boundaries,
        "stages": {f"M2.{s}": overlay_payload(s) for s in ["5", "6", "7", "8", "9", "10"]},
    }
