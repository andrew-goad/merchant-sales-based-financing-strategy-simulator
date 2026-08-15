# M2.4 Complete Package Validation

```json
{
  "status": "PASS",
  "module": "M2.4",
  "module_name": "Booking, Funding & Portfolio Activation",
  "accepted_revision": "v0.2",
  "methodology": "M2_4_METHOD_V1",
  "policy": "M2_4_BOOKING_FUNDING_ACTIVATION_POLICY_V1",
  "contract": "M2_PORTFOLIO_ACTIVATION_CONSUMPTION v1",
  "schema": "M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1",
  "acceptance_gate": "M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION",
  "source_contract": "M2_FINAL_OFFER_DECISION_CONSUMPTION v1",
  "source_hash": "bf09349b06ede7e5a2ec830c2f9ffe90",
  "configuration_hash": "d70e8d776bbb643e57ae21496580e4cb",
  "accepted_counts": {
    "policy_rows": 1,
    "outcome_rows": 5,
    "reason_rows": 24,
    "notice_control_rows": 4,
    "source_rows": 1500,
    "activation_snapshot_rows": 1500,
    "activation_latest_rows": 1500,
    "activation_archive_rows": 1500,
    "account_rows": 59,
    "advance_rows": 59,
    "portfolio_rows": 59,
    "comparison_rows": 750,
    "registry_rows": 1,
    "canonical_entities": 6212,
    "positive_controls": 120,
    "negative_controls": 20,
    "detail_result_sets": 24,
    "generation_evidence_rows": 24,
    "activated_rows": 59,
    "review_required_rows": 190,
    "not_activated_insufficient_rows": 178,
    "not_activated_policy_rows": 1073
  },
  "final_hashes": {
    "policy_set_hash": "be653d79ebedf310723753fcaf57ae3f",
    "outcome_set_hash": "ab19c0c8b1c0d43a697e1a0fc6b8e1cb",
    "reason_set_hash": "ef2ca84f961ea871159b4f3dc294a83a",
    "notice_control_set_hash": "db1d4603d84344899fa25123002e2936",
    "source_set_hash": "55264fd44df4767c361e3b0eccb5392e",
    "activation_snapshot_set_hash": "6252de4e64b4983190f646b5d0f4e36b",
    "activation_latest_set_hash": "f26248c112635ebe5254d614f42332d6",
    "activation_archive_set_hash": "bf72bbed8c76db3ecdc6936e78718e04",
    "account_set_hash": "74616dbd7fb66035ee19569ca540a8c4",
    "advance_set_hash": "a5e48577a305be8c06c73c03843c3ce9",
    "portfolio_set_hash": "3da01a068fc41afc40d8af2eb929ff62",
    "contract_set_hash": "fba075bfd6b24e07dc669d6ce25010f1",
    "combined_set_hash": "117450a3eea7bb3d3c74d18cc3c8e96a"
  },
  "evidence_assertions": 1392,
  "evidence_assertions_passed": 1392,
  "evidence_assertions_failed": 0,
  "control_summary": {
    "positive_controls": {
      "expected": 120,
      "passed": 120,
      "failed": 0
    },
    "negative_controls": {
      "expected": 20,
      "passed": 20,
      "failed": 0
    },
    "generation_evidence": {
      "expected": 24,
      "passed": 24,
      "failed": 0
    },
    "acceptance_evidence": {
      "expected": 1,
      "passed": 1,
      "failed": 0
    },
    "detail_result_sets": {
      "expected": 24,
      "present": 24
    },
    "deterministic_mismatch_rows": 0,
    "blocking_or_boundary_violation_rows": 0
  },
  "activation_summary": {
    "status": "PASS",
    "baseline": {
      "activated_rows": 44,
      "review_required_rows": 139,
      "not_activated_insufficient_rows": 43,
      "not_activated_policy_rows": 524,
      "total_synthetic_funded_amount": "472000.00",
      "average_synthetic_funded_amount": "10727.27",
      "average_remittance_rate": "0.118902",
      "average_payback_multiple": "1.205379",
      "average_collection_horizon_days": "75.00"
    },
    "recession_energy": {
      "activated_rows": 15,
      "review_required_rows": 51,
      "not_activated_insufficient_rows": 135,
      "not_activated_policy_rows": 549,
      "total_synthetic_funded_amount": "195600.00",
      "average_synthetic_funded_amount": "13040.00",
      "average_remittance_rate": "0.130038",
      "average_payback_multiple": "1.224195",
      "average_collection_horizon_days": "74.00"
    },
    "portfolio": {
      "activated_rows": 59,
      "review_required_rows": 190,
      "not_activated_insufficient_rows": 178,
      "not_activated_policy_rows": 1073,
      "total_synthetic_funded_amount": "667600.00",
      "average_synthetic_funded_amount": "11315.25",
      "account_rows": 59,
      "advance_rows": 59,
      "portfolio_rows": 59
    },
    "operational_lags_days": {
      "booking": 1,
      "funding": 2,
      "portfolio_activation": 2,
      "first_expected_remittance": 3,
      "monitoring_start": 2
    },
    "stress_activation_improvements": 0,
    "stress_funded_amount_improvements": 0
  },
  "generated_at": "2026-08-01 15:29:06.431 -0400",
  "validated_at": "2026-08-01 15:29:48.140 -0400",
  "accepted_at": "2026-08-01 15:31:09.945 -0400",
  "live_execution_performed": true,
  "formal_acceptance_issued": true,
  "evidence_review_status": "PASS"
}
```
