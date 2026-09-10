#!/usr/bin/env python3
"""Wave A R9 terminal-state comparison-contract alignment.

R9 preserves accepted M2.5-M2.10 generation methods. It aligns matched-scenario
comparison flags so favorable terminal completion is not misclassified as an
impermissible stress-path improvement.
"""
from __future__ import annotations
import re

ALIGNMENT_VERSION=1
ALIGNMENT_CODE="WAVE_A_R9_TERMINAL_STATE_COMPARISON_ALIGNMENT"

STAGE_ALIGNMENT={
 "5":{"stage_code":"M2.5","comparison_view":"msbf_m2.v_m2_5_matched_monitoring_comparison","terminal_field":"paid_off_flag","disposition":"ACCEPTED_REFERENCE_ALREADY_ALIGNED"},
 "6":{"stage_code":"M2.6","comparison_view":"msbf_m2.v_m2_6_matched_scenario_comparison","terminal_field":"source_paid_off_flag","disposition":"SUCCESSOR_COMPARISON_ALIGNMENT"},
 "7":{"stage_code":"M2.7","comparison_view":"msbf_m2.v_m2_7_matched_scenario_comparison","terminal_field":"no_setup_required_flag","disposition":"SUCCESSOR_COMPARISON_ALIGNMENT"},
 "8":{"stage_code":"M2.8","comparison_view":"msbf_m2.v_m2_8_matched_scenario_comparison","terminal_field":"no_processing_required_flag","disposition":"SUCCESSOR_COMPARISON_ALIGNMENT"},
 "9":{"stage_code":"M2.9","comparison_view":"msbf_m2.v_m2_9_matched_scenario_comparison","terminal_field":"closed_state_flag","disposition":"SUCCESSOR_COMPARISON_ALIGNMENT"},
 "10":{"stage_code":"M2.10","comparison_view":"msbf_m2.v_m2_10_matched_scenario_comparison","terminal_field":"performance_tier_code=CLOSED_STABLE","disposition":"SUCCESSOR_COMPARISON_ALIGNMENT_PLUS_EXISTING_SOURCE_MAPPING_GENERALIZATION"},
}

def overlay_payload(stage:str)->dict:
    payload={
      "overlay_code":ALIGNMENT_CODE,
      "overlay_version":ALIGNMENT_VERSION,
      "comparison_alignment":STAGE_ALIGNMENT[stage],
      "terminal_rule":"IMPROVEMENT_FLAGS_EVALUATED_ONLY_WHEN_BOTH_MATCHED_PATHS_ARE_NONTERMINAL",
      "accepted_generation_method":"UNCHANGED",
    }
    if stage=="10":
      payload["source_mapping_overlay"]={
        "overlay_code":"M2_10_STATE_RECONCILIATION_SOURCE_MAPPING_R3",
        "overlay_version":1,
        "mapping_basis":"CERTIFIED_STATE_PAYMENT_EVENT_EXCEPTION_AND_VARIANCE_SEMANTICS_WITHOUT_PREDECESSOR_DOLLAR_FIXTURES",
      }
    return payload

def configuration_payload()->dict:
    return {
      "strategy_correction_id":"MSBF_M1M2_R1_WAVE_A_R9",
      "alignment_version":ALIGNMENT_VERSION,
      "governing_reference":"M2.5_PAID_OFF_TERMINAL_STATE_EXEMPTION",
      "stages":{f"M2.{s}":overlay_payload(s) for s in ["5","6","7","8","9","10"]},
      "withdrawn_unexecuted_r8_overlays":[
        "M2_6_MONOTONIC_STATUS_TO_STRATEGY_R8",
        "M2_7_SOURCE_REVIEW_AUTHORITY_PRESERVATION_R8",
      ],
    }

def _replace_view(sql:str,view_name:str,next_view_name:str,replacement:str)->str:
    pattern=re.compile(
      r"CREATE\s+OR\s+REPLACE\s+VIEW\s+"+re.escape(view_name)+
      r"\b.*?(?=CREATE\s+OR\s+REPLACE\s+VIEW\s+"+re.escape(next_view_name)+r"\b)",
      re.I|re.S,
    )
    matches=list(pattern.finditer(sql))
    if len(matches)!=1: raise RuntimeError(f"{view_name} replacement boundary count={len(matches)}")
    return pattern.sub(replacement.rstrip()+"\n\n",sql,count=1)

M2_6_VIEW=r"""
CREATE OR REPLACE VIEW msbf_m2.v_m2_6_matched_scenario_comparison AS
SELECT baseline.module1_run_id,baseline.merchant_application_id,
 baseline.strategy_outcome_code AS baseline_strategy_outcome_code,
 stress.strategy_outcome_code AS stress_strategy_outcome_code,
 baseline.strategy_outcome_rank AS baseline_strategy_outcome_rank,
 stress.strategy_outcome_rank AS stress_strategy_outcome_rank,
 baseline.servicing_priority_rank AS baseline_servicing_priority_rank,
 stress.servicing_priority_rank AS stress_servicing_priority_rank,
 baseline.recommended_action_exposure_amount AS baseline_recommended_action_exposure_amount,
 stress.recommended_action_exposure_amount AS stress_recommended_action_exposure_amount,
 (NOT baseline_source.paid_off_flag AND NOT stress_source.paid_off_flag
  AND stress.strategy_outcome_rank<baseline.strategy_outcome_rank) AS stress_strategy_improvement_flag,
 (NOT baseline_source.paid_off_flag AND NOT stress_source.paid_off_flag
  AND stress.servicing_priority_rank<baseline.servicing_priority_rank) AS stress_action_improvement_flag
FROM msbf_m2.advance_intervention_strategy_latest baseline
JOIN msbf_m2.advance_intervention_strategy_latest stress
 ON stress.module1_run_id=baseline.module1_run_id
AND stress.merchant_application_id=baseline.merchant_application_id
AND stress.scenario_code='RECESSION_ENERGY'
JOIN msbf_m2.advance_intervention_source_snapshot baseline_source
 ON baseline_source.module1_run_id=baseline.module1_run_id
AND baseline_source.scenario_id=baseline.scenario_id
AND baseline_source.merchant_application_id=baseline.merchant_application_id
AND baseline_source.synthetic_advance_id=baseline.synthetic_advance_id
JOIN msbf_m2.advance_intervention_source_snapshot stress_source
 ON stress_source.module1_run_id=stress.module1_run_id
AND stress_source.scenario_id=stress.scenario_id
AND stress_source.merchant_application_id=stress.merchant_application_id
AND stress_source.synthetic_advance_id=stress.synthetic_advance_id
WHERE baseline.scenario_code='BASELINE';
"""

M2_7_VIEW=r"""
CREATE OR REPLACE VIEW msbf_m2.v_m2_7_matched_scenario_comparison AS
SELECT baseline.module1_run_id,baseline.merchant_application_id,
 baseline.operational_setup_outcome_code AS baseline_operational_setup_outcome_code,
 stress.operational_setup_outcome_code AS stress_operational_setup_outcome_code,
 baseline.operational_setup_priority_rank AS baseline_operational_setup_priority_rank,
 stress.operational_setup_priority_rank AS stress_operational_setup_priority_rank,
 baseline.setup_authorized_flag AS baseline_setup_authorized_flag,
 stress.setup_authorized_flag AS stress_setup_authorized_flag,
 baseline.source_recommended_action_exposure_amount AS baseline_source_exposure_amount,
 stress.source_recommended_action_exposure_amount AS stress_source_exposure_amount,
 (NOT baseline.no_setup_required_flag AND NOT stress.no_setup_required_flag
  AND stress.setup_authorized_flag AND NOT baseline.setup_authorized_flag) AS stress_setup_permission_improvement_flag,
 (NOT baseline.no_setup_required_flag AND NOT stress.no_setup_required_flag
  AND stress.operational_setup_priority_rank<baseline.operational_setup_priority_rank) AS stress_priority_improvement_flag
FROM msbf_m2.application_operational_activation_latest baseline
JOIN msbf_m2.application_operational_activation_latest stress
 ON stress.module1_run_id=baseline.module1_run_id
AND stress.merchant_application_id=baseline.merchant_application_id
AND stress.scenario_code='RECESSION_ENERGY'
WHERE baseline.scenario_code='BASELINE';
"""

M2_8_VIEW=r"""
CREATE OR REPLACE VIEW msbf_m2.v_m2_8_matched_scenario_comparison AS
WITH paired AS(
 SELECT module1_run_id,merchant_application_id,
  max(servicing_execution_outcome_code) FILTER(WHERE scenario_code='BASELINE') AS baseline_servicing_execution_outcome_code,
  max(servicing_execution_outcome_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_servicing_execution_outcome_code,
  max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='BASELINE') AS baseline_servicing_execution_priority_rank,
  max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_servicing_execution_priority_rank,
  bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='BASELINE') AS baseline_processing_authorized_flag,
  bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_processing_authorized_flag,
  max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='BASELINE') AS baseline_ending_exposure_amount,
  max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_ending_exposure_amount,
  bool_or(no_processing_required_flag) FILTER(WHERE scenario_code='BASELINE') AS baseline_terminal_flag,
  bool_or(no_processing_required_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_terminal_flag,
  count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
  count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
 FROM msbf_m2.application_servicing_execution_latest
 GROUP BY module1_run_id,merchant_application_id)
SELECT module1_run_id,merchant_application_id,
 baseline_servicing_execution_outcome_code,stress_servicing_execution_outcome_code,
 baseline_servicing_execution_priority_rank,stress_servicing_execution_priority_rank,
 baseline_processing_authorized_flag,stress_processing_authorized_flag,
 baseline_ending_exposure_amount,stress_ending_exposure_amount,baseline_rows,stress_rows,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_processing_authorized_flag AND NOT baseline_processing_authorized_flag) AS stress_processing_permission_improvement_flag,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_servicing_execution_priority_rank<baseline_servicing_execution_priority_rank) AS stress_priority_improvement_flag,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_ending_exposure_amount<baseline_ending_exposure_amount) AS stress_exposure_improvement_flag
FROM paired WHERE baseline_rows=1 AND stress_rows=1;
"""

M2_9_VIEW=r"""
CREATE OR REPLACE VIEW msbf_m2.v_m2_9_matched_scenario_comparison AS
WITH paired AS(
 SELECT module1_run_id,merchant_application_id,
  max(reconciliation_outcome_code) FILTER(WHERE scenario_code='BASELINE') AS baseline_reconciliation_outcome_code,
  max(reconciliation_outcome_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_reconciliation_outcome_code,
  max(certified_state_code) FILTER(WHERE scenario_code='BASELINE') AS baseline_certified_state_code,
  max(certified_state_code) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_certified_state_code,
  max(certified_exposure_amount) FILTER(WHERE scenario_code='BASELINE') AS baseline_certified_exposure_amount,
  max(certified_exposure_amount) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_certified_exposure_amount,
  bool_or(state_certified_flag) FILTER(WHERE scenario_code='BASELINE') AS baseline_state_certified_flag,
  bool_or(state_certified_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_state_certified_flag,
  bool_or(closed_state_flag) FILTER(WHERE scenario_code='BASELINE') AS baseline_terminal_flag,
  bool_or(closed_state_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_terminal_flag,
  count(*) FILTER(WHERE scenario_code='BASELINE') AS baseline_rows,
  count(*) FILTER(WHERE scenario_code='RECESSION_ENERGY') AS stress_rows
 FROM msbf_m2.application_payment_reconciliation_certification_latest
 GROUP BY module1_run_id,merchant_application_id),ranked AS(
 SELECT paired.*,
  b.certification_state_rank AS baseline_certification_rank,
  s.certification_state_rank AS stress_certification_rank
 FROM paired
 JOIN msbf_m2.account_state_certification_definition b
  ON b.module1_run_id=paired.module1_run_id AND b.certification_state_code=paired.baseline_certified_state_code
 JOIN msbf_m2.account_state_certification_definition s
  ON s.module1_run_id=paired.module1_run_id AND s.certification_state_code=paired.stress_certified_state_code
 WHERE paired.baseline_rows=1 AND paired.stress_rows=1)
SELECT module1_run_id,merchant_application_id,
 baseline_reconciliation_outcome_code,stress_reconciliation_outcome_code,
 baseline_certified_state_code,stress_certified_state_code,
 baseline_certified_exposure_amount,stress_certified_exposure_amount,
 baseline_state_certified_flag,stress_state_certified_flag,baseline_rows,stress_rows,
 baseline_certification_rank,stress_certification_rank,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_state_certified_flag AND NOT baseline_state_certified_flag) AS stress_certification_permission_improvement_flag,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_certification_rank<baseline_certification_rank) AS stress_certification_rank_improvement_flag,
 (NOT baseline_terminal_flag AND NOT stress_terminal_flag
  AND stress_certified_exposure_amount<baseline_certified_exposure_amount) AS stress_exposure_improvement_flag
FROM ranked;
"""

M2_10_VIEW=r"""
CREATE OR REPLACE VIEW msbf_m2.v_m2_10_matched_scenario_comparison AS
WITH paired AS(
 SELECT latest.module1_run_id,latest.merchant_application_id,
  max(latest.performance_tier_code) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_performance_tier_code,
  max(latest.performance_tier_code) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_performance_tier_code,
  max(tier.performance_tier_rank) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_performance_tier_rank,
  max(tier.performance_tier_rank) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_performance_tier_rank,
  max(latest.servicing_burden_units) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_servicing_burden_units,
  max(latest.servicing_burden_units) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_servicing_burden_units,
  max(latest.certified_exposure_amount) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_certified_exposure_amount,
  max(latest.certified_exposure_amount) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_certified_exposure_amount,
  count(*) FILTER(WHERE latest.scenario_code='BASELINE') AS baseline_rows,
  count(*) FILTER(WHERE latest.scenario_code='RECESSION_ENERGY') AS stress_rows
 FROM msbf_m2.application_portfolio_performance_latest latest
 JOIN msbf_m2.portfolio_performance_tier_definition tier
  ON tier.module1_run_id=latest.module1_run_id AND tier.performance_tier_code=latest.performance_tier_code
 GROUP BY latest.module1_run_id,latest.merchant_application_id)
SELECT paired.*,
 (baseline_performance_tier_code<>'CLOSED_STABLE' AND stress_performance_tier_code<>'CLOSED_STABLE'
  AND stress_performance_tier_rank<baseline_performance_tier_rank) AS stress_tier_improvement_flag,
 (baseline_performance_tier_code<>'CLOSED_STABLE' AND stress_performance_tier_code<>'CLOSED_STABLE'
  AND stress_servicing_burden_units<baseline_servicing_burden_units) AS stress_burden_improvement_flag,
 (baseline_performance_tier_code<>'CLOSED_STABLE' AND stress_performance_tier_code<>'CLOSED_STABLE'
  AND stress_certified_exposure_amount<baseline_certified_exposure_amount) AS stress_exposure_improvement_flag
FROM paired WHERE baseline_rows=1 AND stress_rows=1;
"""

def patch_schema(stage:str,sql:str)->str:
    specs={
      "6":("msbf_m2.v_m2_6_matched_scenario_comparison","msbf_m2.v_m2_6_power_bi_intervention_strategy",M2_6_VIEW),
      "7":("msbf_m2.v_m2_7_matched_scenario_comparison","msbf_m2.v_m2_7_power_bi_operational_setup",M2_7_VIEW),
      "8":("msbf_m2.v_m2_8_matched_scenario_comparison","msbf_m2.v_m2_8_payment_event_ledger",M2_8_VIEW),
      "9":("msbf_m2.v_m2_9_matched_scenario_comparison","msbf_m2.v_m2_9_exception_resolution_ledger",M2_9_VIEW),
      "10":("msbf_m2.v_m2_10_matched_scenario_comparison","msbf_m2.v_m2_10_kpi_matrix",M2_10_VIEW),
    }
    return sql if stage not in specs else _replace_view(sql,*specs[stage])

def patch_generation(stage:str,sql:str)->str:
    return sql

VIEW_COLUMN_CONTRACT={
 "6":["module1_run_id","merchant_application_id","baseline_strategy_outcome_code","stress_strategy_outcome_code","baseline_strategy_outcome_rank","stress_strategy_outcome_rank","baseline_servicing_priority_rank","stress_servicing_priority_rank","baseline_recommended_action_exposure_amount","stress_recommended_action_exposure_amount","stress_strategy_improvement_flag","stress_action_improvement_flag"],
 "7":["module1_run_id","merchant_application_id","baseline_operational_setup_outcome_code","stress_operational_setup_outcome_code","baseline_operational_setup_priority_rank","stress_operational_setup_priority_rank","baseline_setup_authorized_flag","stress_setup_authorized_flag","baseline_source_exposure_amount","stress_source_exposure_amount","stress_setup_permission_improvement_flag","stress_priority_improvement_flag"],
 "8":["module1_run_id","merchant_application_id","baseline_servicing_execution_outcome_code","stress_servicing_execution_outcome_code","baseline_servicing_execution_priority_rank","stress_servicing_execution_priority_rank","baseline_processing_authorized_flag","stress_processing_authorized_flag","baseline_ending_exposure_amount","stress_ending_exposure_amount","baseline_rows","stress_rows","stress_processing_permission_improvement_flag","stress_priority_improvement_flag","stress_exposure_improvement_flag"],
 "9":["module1_run_id","merchant_application_id","baseline_reconciliation_outcome_code","stress_reconciliation_outcome_code","baseline_certified_state_code","stress_certified_state_code","baseline_certified_exposure_amount","stress_certified_exposure_amount","baseline_state_certified_flag","stress_state_certified_flag","baseline_rows","stress_rows","baseline_certification_rank","stress_certification_rank","stress_certification_permission_improvement_flag","stress_certification_rank_improvement_flag","stress_exposure_improvement_flag"],
 "10":["module1_run_id","merchant_application_id","baseline_performance_tier_code","stress_performance_tier_code","baseline_performance_tier_rank","stress_performance_tier_rank","baseline_servicing_burden_units","stress_servicing_burden_units","baseline_certified_exposure_amount","stress_certified_exposure_amount","baseline_rows","stress_rows","stress_tier_improvement_flag","stress_burden_improvement_flag","stress_exposure_improvement_flag"],
}
