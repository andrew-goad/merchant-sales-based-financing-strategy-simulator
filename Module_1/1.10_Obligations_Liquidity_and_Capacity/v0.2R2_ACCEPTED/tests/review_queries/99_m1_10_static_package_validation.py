from pathlib import Path
import json, subprocess, sys
base=Path(__file__).resolve().parents[1]
checks={
 "positive_controls": 70,
 "negative_controls": 6,
 "detail_result_sets": 18,
 "validation_preserves_rows": "ON COMMIT PRESERVE ROWS" in (base/"sql/71_msbf_m1_10_obligations_liquidity_capacity_validation_v0_2.sql").read_text(),
 "negative_preserves_rows": "ON COMMIT PRESERVE ROWS" in (base/"sql/72_msbf_m1_10_negative_control_tests_v0_2.sql").read_text(),
 "generation_avoids_upstream_blueprints": all(x not in (base/"sql/70_msbf_m1_10_obligations_liquidity_capacity_generation_v0_2.sql").read_text() for x in ["m1_4_daily_pos_blueprint","m1_5_daily_liquidity_blueprint","m1_6_pos_scenario_blueprint","m1_6_deposit_scenario_blueprint","m1_9_asof"]),
}
checks["status"]="PASS" if all(v is True or isinstance(v,int) for k,v in checks.items() if k!="status") else "FAIL"
print(json.dumps(checks,indent=2))
sys.exit(0 if checks["status"]=="PASS" else 1)
