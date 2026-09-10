#!/usr/bin/env python3
from __future__ import annotations
import argparse,csv,getpass,hashlib,io,json,os,re,shutil,subprocess,time,zipfile
from pathlib import Path
from datetime import datetime,timezone
import wave_a_core_r3 as core
import wave_a_strategy_r13 as r13_strategy
import wave_a_strategy_r15 as strategy

HERE=Path(__file__).resolve().parents[1]
META=core.META
SRC_MAN=core.SRC_MAN
STAGES=core.STAGES
TIME_KEYS=core.TIME_KEYS

def sha256_file(p): return core.sha256_file(p)
def hash_text(t,alg='sha256'): return core.hash_text(t,alg)
def canon(obj): return core.canon(obj)
def run(cmd,env,log,input_text=None,check=True): return core.run(cmd,env,log,input_text,check)
def scalar(psql,conn,db,env,log,sql): return core.scalar(psql,conn,db,env,log,sql)
def qident(s): return core.qident(s)
def database_exists(psql,conn,env,log,db): return core.database_exists(psql,conn,env,log,db)


POWER_BI_EXPORT_CONTRACT={
  'm2_5_power_bi':{
    'stage':'M2.5','view':'msbf_m2.v_m2_5_power_bi_daily_monitoring',
    'grain':'module1_run_id x scenario_code x merchant_application_id x monitoring_day_index',
    'order_by':['module1_run_id','scenario_code','merchant_application_id','monitoring_day_index'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_advance_id',
      'monitoring_day_index','monitoring_date','source_eligible_pos_sales','actual_remittance_amount',
      'cumulative_remittance_amount','receivable_balance_after','principal_exposure_proxy',
      'cumulative_shortfall_amount','cumulative_pace_ratio','monitoring_status_code',
      'stress_status_floor_applied_flag','daily_shortfall_alert_flag','cumulative_pace_watch_alert_flag',
      'cumulative_pace_high_alert_flag','zero_sales_streak_alert_flag','liquidity_stress_alert_flag',
      'horizon_overrun_alert_flag','paid_off_flag']},
  'm2_6_power_bi':{
    'stage':'M2.6','view':'msbf_m2.v_m2_6_power_bi_intervention_strategy',
    'grain':'module1_run_id x scenario_code x merchant_application_id',
    'order_by':['module1_run_id','scenario_code','merchant_application_id'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_account_id',
      'synthetic_advance_id','strategy_outcome_code','servicing_action_code','servicing_queue_code',
      'servicing_priority_rank','recommended_action_flag','review_required_flag',
      'recommended_action_exposure_amount','primary_intervention_reason_code']},
  'm2_7_power_bi':{
    'stage':'M2.7','view':'msbf_m2.v_m2_7_power_bi_operational_setup',
    'grain':'module1_run_id x scenario_code x merchant_application_id',
    'order_by':['module1_run_id','scenario_code','merchant_application_id'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_account_id',
      'synthetic_advance_id','source_strategy_outcome_code','source_servicing_action_code',
      'operational_setup_outcome_code','operational_setup_action_code','operational_setup_priority_rank',
      'operational_setup_queue_code','account_setup_status_code','setup_authorized_flag',
      'setup_review_required_flag','no_setup_required_flag','source_recommended_action_exposure_amount',
      'operational_activation_date','next_reassessment_date']},
  'm2_8_power_bi':{
    'stage':'M2.8','view':'msbf_m2.v_m2_8_power_bi_servicing_execution',
    'grain':'module1_run_id x scenario_code x merchant_application_id',
    'order_by':['module1_run_id','scenario_code','merchant_application_id'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_account_id',
      'synthetic_advance_id','source_operational_setup_outcome_code','servicing_execution_outcome_code',
      'servicing_execution_action_code','servicing_execution_priority_rank','servicing_execution_queue_code',
      'processing_authorized_flag','processing_review_required_flag','no_processing_required_flag',
      'final_lifecycle_state_code','payment_event_count','settled_event_count','returned_event_count',
      'retry_event_count','scheduled_payment_amount','processed_payment_amount','returned_payment_amount',
      'retry_payment_amount','ending_simulated_exposure_amount']},
  'm2_9_power_bi':{
    'stage':'M2.9','view':'msbf_m2.v_m2_9_power_bi_account_certification',
    'grain':'module1_run_id x scenario_code x merchant_application_id',
    'order_by':['module1_run_id','scenario_code','merchant_application_id'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_account_id',
      'synthetic_advance_id','reconciliation_outcome_code','resolution_action_code','certified_state_code',
      'state_certified_flag','closed_state_flag','active_state_flag','review_hold_state_flag',
      'exception_resolved_flag','payment_event_count','scheduled_payment_amount','processed_payment_amount',
      'returned_payment_amount','retry_payment_amount','reconciliation_variance_amount',
      'certified_exposure_amount','exposure_variance_amount','certification_date']},
  'm2_10_power_bi':{
    'stage':'M2.10','view':'msbf_m2.v_m2_10_power_bi_portfolio_analytics',
    'grain':'module1_run_id x scenario_code x merchant_application_id',
    'order_by':['module1_run_id','scenario_code','merchant_application_id'],
    'columns':['module1_run_id','scenario_code','merchant_application_id','synthetic_account_id',
      'performance_tier_code','servicing_queue_code','state_certified_flag','payment_activity_flag',
      'exception_incident_flag','exception_resolved_flag','certified_exposure_amount',
      'scheduled_payment_amount','processed_payment_amount','returned_payment_amount','retry_payment_amount',
      'gross_collection_rate','return_rate','retry_cure_rate','servicing_burden_units']}
}

CONTROL_EXPORT_SPECS={
  'wave_a_stage_registry':'SELECT * FROM msbf_m12r1e.wave_a_stage_registry ORDER BY stage_code',
  'wave_a_validation_result':'SELECT * FROM msbf_m12r1e.wave_a_validation_result ORDER BY stage_code,control_id',
  'downstream_rebase_status':'SELECT * FROM msbf_m12r1e.downstream_rebase_status ORDER BY stage_code'
}

R13_ROUNDING_CONTROL_IDS=[
 'R13_KNOWN_RETRY_EVENT_POPULATION','R13_RETRY_EVENT_CENT_ROUNDING_ALIGNMENT',
 'R13_M2_8_ACCOUNT_LEDGER_EXACT_RECONCILIATION','R13_M2_9_ZERO_VARIANCE_ROW_POPULATION',
 'R13_M2_9_RETRY_PATH_CERTIFIED_ACTIVE','R13_M2_10_RETRY_PATH_ACTIVE_RECONCILED'
]


R15_SOURCE_PAYLOAD_CONTROL_IDS=[
 'R15_M2_7_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_7_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
 'R15_M2_8_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_8_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
 'R15_M2_9_ACCOUNT_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_9_ACCOUNT_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
 'R15_M2_9_PAYMENT_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_9_PAYMENT_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
 'R15_M2_9_TRANSITION_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_9_TRANSITION_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
 'R15_M2_10_SOURCE_PAYLOAD_VOLATILE_TIME_KEYS_ABSENT',
 'R15_M2_10_SOURCE_PAYLOAD_PREDECESSOR_EXACT'
]

SOURCE_PAYLOAD_SPECS={
 'M2.7':{
   'source_table':'msbf_m2.operational_activation_source_snapshot',
   'predecessor_table':'msbf_m2.advance_intervention_strategy_latest',
   'keys':['module1_run_id','scenario_id','merchant_application_id']},
 'M2.8':{
   'source_table':'msbf_m2.servicing_execution_source_snapshot',
   'predecessor_table':'msbf_m2.application_operational_activation_latest',
   'keys':['module1_run_id','scenario_id','merchant_application_id']},
 'M2.9_ACCOUNT':{
   'source_table':'msbf_m2.account_reconciliation_source_snapshot',
   'predecessor_table':'msbf_m2.application_servicing_execution_latest',
   'keys':['module1_run_id','scenario_id','merchant_application_id']},
 'M2.9_PAYMENT':{
   'source_table':'msbf_m2.payment_reconciliation_source_event',
   'predecessor_table':'msbf_m2.synthetic_payment_processing_event',
   'keys':['module1_run_id','scenario_id','merchant_application_id','event_sequence']},
 'M2.9_TRANSITION':{
   'source_table':'msbf_m2.lifecycle_certification_source_transition',
   'predecessor_table':'msbf_m2.account_lifecycle_transition_snapshot',
   'keys':['module1_run_id','scenario_id','merchant_application_id','transition_sequence']},
 'M2.10':{
   'source_table':'msbf_m2.portfolio_performance_source_snapshot',
   'predecessor_table':'msbf_m2.application_payment_reconciliation_certification_latest',
   'keys':['module1_run_id','scenario_id','merchant_application_id']}
}

VOLATILE_PAYLOAD_KEYS=list(TIME_KEYS)

R16_DIAGNOSTIC_COMPARATOR_CONTROL_IDS=[
 'R16_R13_R14_M2_7_FIELD_DOMAIN_EXACT',
 'R16_R13_R14_M2_7_MUST_MATCH_FIELDS_EXACT',
 'R16_R13_R14_M2_7_MUST_DIFFER_FIELDS_EXACT',
 'R16_R13_R14_M2_7_LEGACY_POLICY_HASH_STABLE'
]

R16_M2_7_LEGACY_POLICY_CONFIGURATION_HASH='cff16c013fc0f6186ce0b43fb163b107'

M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT={
 'must_match':[
   'stage_code','predecessor_stage_code','accepted_predecessor_combined_hash',
   'accepted_schema_source_sha256','accepted_generation_source_sha256',
   'transformed_schema_sha256','transformed_generation_sha256','policy_method_hash',
   'legacy_policy_configuration_hash','source_rows','baseline_rows','stress_rows',
   'actual_population_payload','legacy_registry_status','validation_status'
 ],
 'must_differ':[
   'accepted_output_combined_hash','successor_contract_hash','successor_contract_sha256',
   'successor_evidence_hash','successor_evidence_sha256','contract_table_set_sha256'
 ]
}


R17_EXPORT_PREFLIGHT_COMPARATOR_CONTROL_IDS=[
 'R17_EXPORT_PREFLIGHT_OBJECT_DOMAIN_EXACT',
 'R17_EXPORT_PREFLIGHT_FIELD_DOMAIN_EXACT',
 'R17_EXPORT_PREFLIGHT_QUERY_IDENTITY_EXACT',
 'R17_EXPORT_PREFLIGHT_EXECUTION_STATUS_EXACT',
 'R17_EXPORT_PREFLIGHT_NONVALIDATION_ROW_COUNTS_EXACT',
 'R17_EXPORT_PREFLIGHT_VALIDATION_CONTROL_DELTA_EXACT'
]

R17_PREFLIGHT_FIELD_DOMAIN=['name','query','query_sha256','rows','status','returncode','stderr']
R17_BASELINE_PREFLIGHT_ROWS={
 'wave_a_stage_registry':6,
 'wave_a_validation_result':103,
 'm2_5_power_bi':15600,
 'm2_6_power_bi':130,
 'm2_7_power_bi':130,
 'm2_8_power_bi':130,
 'm2_9_power_bi':130,
 'm2_10_power_bi':130,
 'downstream_rebase_status':9
}
R17_SUCCESSOR_PREFLIGHT_ROWS={**R17_BASELINE_PREFLIGHT_ROWS,'wave_a_validation_result':115}
R17_VALIDATION_CONTROL_DELTA=12

def build_export_specs():
    specs=dict(CONTROL_EXPORT_SPECS)
    for name,contract in POWER_BI_EXPORT_CONTRACT.items():
        order=', '.join(qident(x) for x in contract['order_by'])
        specs[name]=f"SELECT * FROM {contract['view']} ORDER BY {order}"
    # Preserve the historical delivery order while deriving every Power BI query from its contract.
    order=['wave_a_stage_registry','wave_a_validation_result','m2_5_power_bi','m2_6_power_bi',
           'm2_7_power_bi','m2_8_power_bi','m2_9_power_bi','m2_10_power_bi',
           'downstream_rebase_status']
    return {name:specs[name] for name in order}

def power_bi_view_contract_snapshot(psql,conn,db,env,log):
    rows=[]
    for name,contract in POWER_BI_EXPORT_CONTRACT.items():
        schema_name,view_name=contract['view'].split('.',1)
        columns_sql=("SELECT column_name FROM information_schema.columns WHERE table_schema='"+
          schema_name.replace("'","''")+"' AND table_name='"+view_name.replace("'","''")+
          "' ORDER BY ordinal_position;")
        cp=run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',columns_sql],env,log)
        actual=[x.strip() for x in cp.stdout.splitlines() if x.strip()]
        keys=contract['order_by']
        key_sql=','.join(qident(x) for x in keys)
        null_where=' OR '.join(qident(x)+' IS NULL' for x in keys)
        row_count=int(scalar(psql,conn,db,env,log,f"SELECT count(*) FROM {contract['view']};"))
        distinct_count=int(scalar(psql,conn,db,env,log,
          f"SELECT count(DISTINCT ({key_sql})) FROM {contract['view']};"))
        null_key_rows=int(scalar(psql,conn,db,env,log,
          f"SELECT count(*) FROM {contract['view']} WHERE {null_where};"))
        status=('PASS' if actual==contract['columns'] and all(k in actual for k in keys)
                and row_count==distinct_count and null_key_rows==0 else 'FAIL')
        rows.append({'name':name,'stage':contract['stage'],'view':contract['view'],
          'grain':contract['grain'],'expected_columns':contract['columns'],'actual_columns':actual,
          'order_by':keys,'rows':row_count,'distinct_key_rows':distinct_count,
          'duplicate_key_rows':row_count-distinct_count,'null_key_rows':null_key_rows,'status':status})
    return rows

def require_power_bi_view_contract(snapshot):
    failures=[x for x in snapshot if x['status']!='PASS']
    if failures:
        raise RuntimeError('Power BI export projection/grain contract failed: '+canon(failures))
    return snapshot

def export_query_preflight_all(psql,conn,db,env,log,queries):
    results=[]
    for name,query in queries.items():
        cp=run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',
                f'SELECT count(*) FROM ({query}) z;'],env,log,check=False)
        observed=cp.stdout.strip()
        results.append({'name':name,'query':query,'query_sha256':hash_text(query,'sha256'),
          'rows':int(observed) if cp.returncode==0 and observed.isdigit() else None,
          'status':'PASS' if cp.returncode==0 else 'FAIL','returncode':cp.returncode,
          'stderr':(cp.stderr or '').strip()})
    failures=[x for x in results if x['status']!='PASS']
    if failures:
        raise RuntimeError('Export query preflight failed: '+canon(failures))
    return results

def power_bi_export_identity(psql,conn,db,env,log,contract_snapshot=None):
    snapshot=require_power_bi_view_contract(contract_snapshot or power_bi_view_contract_snapshot(
      psql,conn,db,env,log))
    row_meta={x['name']:x for x in snapshot}
    specs=build_export_specs()
    identities=[]
    for name,contract in POWER_BI_EXPORT_CONTRACT.items():
        query=specs[name]
        copy_sql=f"COPY ({query}) TO STDOUT WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');"
        cp=run([psql,*conn,'-d',db,'-X','-q','-v','ON_ERROR_STOP=1','-c',copy_sql],env,log)
        payload=(cp.stdout or '').replace('\r\n','\n').replace('\r','\n')
        payload=payload.rstrip('\n')+'\n'
        identities.append({'name':name,'stage':contract['stage'],'view':contract['view'],
          'grain':contract['grain'],'order_by':contract['order_by'],'columns':contract['columns'],
          'rows':row_meta[name]['rows'],'query_sha256':hash_text(query,'sha256'),
          'csv_sha256':hash_text(payload,'sha256'),'csv_bytes':len(payload.encode('utf-8'))})
    identities=sorted(identities,key=lambda x:x['name'])
    return {'objects':identities,'object_count':len(identities),
            'bundle_sha256':hash_text(canon(identities),'sha256')}

def r14_runtime_configuration_payload():
    return {
      'correction_code':'WAVE_A_R14_POWER_BI_EXPORT_IDENTITY_CONTRACT',
      'correction_class':'RUNTIME_EVIDENCE_EXPORT_IDENTITY',
      'policy_change':False,'accepted_source_bytes_changed':False,
      'transformed_sql_bytes_changed_from_r13':False,'generation_methods_changed':[],
      'validator_business_controls_changed':False,
      'runtime_evidence_methods_changed':[
        'POWER_BI_VIEW_PROJECTION_CONTRACT','POWER_BI_EXPORT_GRAIN_KEY_CONTRACT',
        'POWER_BI_EXPORT_ORDERING_KEYS','ALL_EXPORT_QUERY_PREFLIGHT',
        'POWER_BI_EXPORT_CONTENT_SHA256','R13_COMPILER_R14_COMPILER_FINAL_IDENTITY_EQUALITY'],
      'preserved_r13_retry_rounding':True,'preserved_r12_nullable_hash_semantics':True,
      'preserved_r9_terminal_alignment':True,'fresh_compiler_and_final_required':True,
      'r12_rerun_authorized':False,'r13_rerun_authorized':False,
      'power_bi_export_objects':[
        {'name':name,'stage':c['stage'],'view':c['view'],'grain':c['grain'],
         'order_by':c['order_by'],'columns':c['columns']}
        for name,c in POWER_BI_EXPORT_CONTRACT.items()]
    }

def r15_runtime_configuration_payload():
    return {
      'correction_code':'WAVE_A_R15_SOURCE_PAYLOAD_CREATED_AT_CANONICALIZATION',
      'correction_class':'GENERATION_EVIDENCE_CANONICALIZATION',
      'defect_class':'RUN_GENERATED_TIMESTAMP_EMBEDDED_IN_NESTED_SOURCE_EVIDENCE',
      'lowest_correct_remediation_layer':'GENERATION_SOURCE_PAYLOAD_CANONICALIZATION',
      'policy_change':False,'accepted_source_bytes_changed':False,
      'transformed_sql_bytes_changed_from_r14':True,
      'validator_business_controls_changed':False,
      'generation_methods_changed':strategy.configuration_payload()['generation_methods_changed'],
      'added_validation_controls':R15_SOURCE_PAYLOAD_CONTROL_IDS,
      'preserved_r13_retry_rounding':True,'preserved_r12_nullable_hash_semantics':True,
      'preserved_r9_terminal_alignment':True,'preserved_r14_power_bi_export_identity':True,
      'exact_compiler_final_identity_required':True,'fresh_compiler_and_final_required':True,
      'r12_rerun_authorized':False,'r13_rerun_authorized':False,'r14_rerun_authorized':False,
      'source_payload_boundaries':[
        {'code':code,'source_table':spec['source_table'],'predecessor_table':spec['predecessor_table'],
         'keys':spec['keys'],'excluded_top_level_key':'created_at'}
        for code,spec in SOURCE_PAYLOAD_SPECS.items()],
      'power_bi_export_objects':[
        {'name':name,'stage':c['stage'],'view':c['view'],'grain':c['grain'],
         'order_by':c['order_by'],'columns':c['columns']}
        for name,c in POWER_BI_EXPORT_CONTRACT.items()]
    }

def r16_runtime_configuration_payload():
    return {
      'correction_code':'WAVE_A_R16_R13_R14_M2_7_DIAGNOSTIC_COMPARATOR_CONTRACT',
      'correction_class':'READ_ONLY_DIAGNOSTIC_COMPARISON_CONTRACT',
      'defect_class':'OVER_SPECIFIED_FIRST_DIVERGENCE_FIELD_SET',
      'lowest_correct_remediation_layer':'R13_R14_M2_7_DIAGNOSTIC_COMPARATOR',
      'policy_change':False,'accepted_source_bytes_changed':False,
      'transformed_sql_bytes_changed_from_r15':False,
      'generation_methods_changed':[],
      'validator_business_controls_changed':False,
      'database_validation_control_population_changed':False,
      'runtime_evidence_methods_changed':[
        'EXACT_M2_7_COMPARATOR_FIELD_DOMAIN',
        'EXACT_M2_7_MUST_MATCH_FIELD_SET',
        'EXACT_M2_7_MUST_DIFFER_FIELD_SET',
        'LEGACY_POLICY_CONFIGURATION_HASH_POSITIVE_STABILITY_ASSERTION',
        'EXACT_R15_FAILURE_EVIDENCE_REPLAY',
        'COMPARATOR_MUTATION_NEGATIVE_TESTS'
      ],
      'diagnostic_comparator_controls':R16_DIAGNOSTIC_COMPARATOR_CONTROL_IDS,
      'm2_7_first_divergence_field_contract':M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT,
      'expected_legacy_policy_configuration_hash':R16_M2_7_LEGACY_POLICY_CONFIGURATION_HASH,
      'preserved_r15_source_payload_canonicalization':True,
      'preserved_r14_power_bi_export_identity':True,
      'preserved_r13_retry_rounding':True,
      'preserved_r12_nullable_hash_semantics':True,
      'preserved_r9_terminal_alignment':True,
      'exact_compiler_final_identity_required':True,
      'fresh_compiler_and_final_required':True,
      'r12_rerun_authorized':False,'r13_rerun_authorized':False,
      'r14_rerun_authorized':False,'r15_rerun_authorized':False,
      'database_validation_controls_carried_forward':115,
      'power_bi_export_objects':[
        {'name':name,'stage':c['stage'],'view':c['view'],'grain':c['grain'],
         'order_by':c['order_by'],'columns':c['columns']}
        for name,c in POWER_BI_EXPORT_CONTRACT.items()]
    }




def r17_runtime_configuration_payload():
    return {
      'correction_code':'WAVE_A_R17_R14_SUCCESSOR_EXPORT_PREFLIGHT_CONTROL_POPULATION_CONTRACT',
      'correction_class':'READ_ONLY_CROSS_VERSION_EXPORT_PREFLIGHT_COMPARISON_CONTRACT',
      'defect_class':'UNQUALIFIED_FULL_OBJECT_EQUALITY_ACROSS_VERSIONED_VALIDATION_POPULATIONS',
      'lowest_correct_remediation_layer':'R14_SUCCESSOR_EXPORT_PREFLIGHT_COMPARATOR',
      'policy_change':False,'accepted_source_bytes_changed':False,
      'transformed_sql_bytes_changed_from_r16':False,
      'generation_methods_changed':[],
      'validator_business_controls_changed':False,
      'database_validation_control_population_changed':False,
      'runtime_evidence_methods_changed':[
        'EXACT_EXPORT_PREFLIGHT_OBJECT_DOMAIN',
        'EXACT_EXPORT_PREFLIGHT_FIELD_DOMAIN',
        'EXACT_EXPORT_QUERY_TEXT_AND_SHA256',
        'EXACT_EXPORT_EXECUTION_STATUS',
        'EXACT_NONVALIDATION_ROW_COUNTS',
        'VERSIONED_VALIDATION_CONTROL_ROW_DELTA',
        'R16_RESULT_AND_PHYSICAL_DIAGNOSTIC_BINDING',
        'R16_R17_EXACT_COMPILER_AND_FINAL_REPLAY'
      ],
      'export_preflight_comparator_controls':R17_EXPORT_PREFLIGHT_COMPARATOR_CONTROL_IDS,
      'baseline_preflight_rows':R17_BASELINE_PREFLIGHT_ROWS,
      'successor_preflight_rows':R17_SUCCESSOR_PREFLIGHT_ROWS,
      'controlled_delta_object':'wave_a_validation_result',
      'controlled_delta_field':'rows',
      'controlled_validation_row_delta':R17_VALIDATION_CONTROL_DELTA,
      'added_validation_control_ids':R15_SOURCE_PAYLOAD_CONTROL_IDS,
      'preserved_r16_diagnostic_comparator_correction':True,
      'preserved_r15_source_payload_canonicalization':True,
      'preserved_r14_power_bi_export_identity':True,
      'preserved_r13_retry_rounding':True,
      'preserved_r12_nullable_hash_semantics':True,
      'preserved_r9_terminal_alignment':True,
      'exact_r16_r17_identity_required':True,
      'exact_compiler_final_identity_required':True,
      'fresh_compiler_and_final_required':True,
      'r12_rerun_authorized':False,'r13_rerun_authorized':False,
      'r14_rerun_authorized':False,'r15_rerun_authorized':False,'r16_rerun_authorized':False,
      'database_validation_controls_carried_forward':115,
      'power_bi_export_objects':[
        {'name':name,'stage':c['stage'],'view':c['view'],'grain':c['grain'],
         'order_by':c['order_by'],'columns':c['columns']}
        for name,c in POWER_BI_EXPORT_CONTRACT.items()]
    }

def safe_database_probe(psql,conn,env,log,db):
    """Probe database existence without masking the controlling runtime error.

    Exit/failure evidence must survive even when PostgreSQL becomes unavailable.
    All R12 probes receive the read-only environment.
    """
    try:
        return {'status':'PASS','exists':database_exists(psql,conn,env,log,db),'error':None}
    except Exception as error:
        return {'status':'UNAVAILABLE','exists':None,'error':repr(error)}

def verify_package_manifest():
    manifest_path=HERE/'PACKAGE_MANIFEST.csv'
    if not manifest_path.exists(): raise RuntimeError('PACKAGE_MANIFEST.csv is absent')
    rows=list(csv.DictReader(manifest_path.open(encoding='utf-8')))
    if not rows: raise RuntimeError('PACKAGE_MANIFEST.csv is empty')
    paths=[r['path'] for r in rows]
    if len(paths)!=len(set(paths)): raise RuntimeError('PACKAGE_MANIFEST.csv contains duplicate paths')
    failures=[]
    for row in rows:
        p=HERE/row['path']
        if not p.exists():
            failures.append({'path':row['path'],'reason':'MISSING'});continue
        actual=sha256_file(p)
        if actual!=row['sha256'] or p.stat().st_size!=int(row['bytes']):
            failures.append({'path':row['path'],'reason':'CONTENT_MISMATCH',
                             'expected_sha256':row['sha256'],'actual_sha256':actual,
                             'expected_bytes':int(row['bytes']),'actual_bytes':p.stat().st_size})
    if failures: raise RuntimeError('Package-manifest verification failed: '+canon(failures[:20]))
    active_runner=Path(__file__).resolve().relative_to(HERE).as_posix()
    required={
      active_runner,'src/wave_a_core_r3.py','src/wave_a_strategy_r9.py','src/wave_a_strategy_r13.py',
      'src/wave_a_strategy_r15.py','tests/static_validate_r17.py','RUN_WAVE_A_R17.ps1',
      'NO_RERUN_R12.txt','NO_RERUN_R13.txt','NO_RERUN_R14.txt','NO_RERUN_R15.txt','NO_RERUN_R16.txt',
      'config/R9_TERMINAL_STATE_COMPARISON_ALIGNMENT.json',
      'config/R13_M2_8_RETRY_ROUNDING_CORRECTION.json',
      'config/R14_POWER_BI_EXPORT_IDENTITY_CORRECTION.json',
      'config/R15_SOURCE_PAYLOAD_CANONICALIZATION_CORRECTION.json',
      'config/R15_STRATEGY_SOURCE_PAYLOAD_CANONICALIZATION.json',
      'config/R16_R13_R14_M2_7_DIAGNOSTIC_COMPARATOR_CORRECTION.json',
      'config/R17_R14_SUCCESSOR_EXPORT_PREFLIGHT_COMPARATOR_CORRECTION.json',
      'diagnostic_inputs/msbf_r1_wave_a_r12_20260830_165946_WAVE_A_R12_RESULTS.zip',
      'diagnostic_inputs/msbf_r1_wave_a_r12_20260830_165946_WAVE_A_R12_RESULTS.zip.sha256',
      'diagnostic_inputs/msbf_r1_wave_a_r13_20260830_190007_WAVE_A_R13_RESULTS.zip',
      'diagnostic_inputs/msbf_r1_wave_a_r13_20260830_190007_WAVE_A_R13_RESULTS.zip.sha256',
      'diagnostic_inputs/msbf_r1_wave_a_r14_20260830_195709_WAVE_A_R14_RESULTS.zip',
      'diagnostic_inputs/msbf_r1_wave_a_r14_20260830_195709_WAVE_A_R14_RESULTS.zip.sha256',
      'diagnostic_inputs/msbf_r1_wave_a_r15_20260830_223334_WAVE_A_R15_RESULTS.zip',
      'diagnostic_inputs/msbf_r1_wave_a_r15_20260830_223334_WAVE_A_R15_RESULTS.zip.sha256',
      'diagnostic_inputs/msbf_r1_wave_a_r16_20260830_231947_WAVE_A_R16_RESULTS.zip',
      'diagnostic_inputs/msbf_r1_wave_a_r16_20260830_231947_WAVE_A_R16_RESULTS.zip.sha256',
      'manifests/01_ACCEPTED_SOURCE_MANIFEST.csv','manifests/17_R14_POWER_BI_EXPORT_IDENTITY_CONTRACT.csv',
      'manifests/18_R15_SOURCE_PAYLOAD_CANONICALIZATION_CONTRACT.csv',
      'manifests/19_R16_R13_R14_DIAGNOSTIC_COMPARATOR_CONTRACT.csv',
      'manifests/20_R17_EXPORT_PREFLIGHT_COMPARATOR_CONTRACT.csv',
      'diagnostics/READ_ONLY_R17_R16_EXPORT_PREFLIGHT_DIAGNOSTIC.sql',
      'docs/38_R16_EXPORT_PREFLIGHT_FAILURE_AND_R17_CORRECTION.md',
      'docs/39_R17_OPERATOR_GUIDE.md','docs/40_R17_AUTHORITY_AND_DOWNSTREAM_BOUNDARY.md',
      'evidence/46_R16_FAILURE_ADJUDICATION.json','evidence/47_R17_CORRECTION_REGISTER.csv',
      'evidence/48_R17_EXPECTED_RUNTIME_CONTROLS.json',
      'evidence/49_R17_COMPREHENSIVE_STATIC_VALIDATION.csv',
      'evidence/49_R17_COMPREHENSIVE_STATIC_VALIDATION_SUMMARY.json',
      'evidence/50_R17_PREARCHIVE_ASSEMBLY_VALIDATION.json','BUILD_RECEIPT_R17.json',
      'superseded/R16/src/run_wave_a_r16.py','superseded/R16/RUN_WAVE_A_R16.ps1',
      'superseded/R16/tests/static_validate_r16.py','superseded/R16/PACKAGE_MANIFEST_R16.csv'
    }
    missing=sorted(required-set(paths))
    if missing: raise RuntimeError('Package manifest omits required files: '+canon(missing))
    forbidden={
      'RUN_WAVE_A_R12.ps1','RUN_WAVE_A_R13.ps1','RUN_WAVE_A_R14.ps1','RUN_WAVE_A_R15.ps1','RUN_WAVE_A_R16.ps1',
      'src/run_wave_a_r12.py','src/run_wave_a_r13.py','src/run_wave_a_r14.py','src/run_wave_a_r15.py','src/run_wave_a_r16.py',
      'tests/static_validate_r12.py','tests/static_validate_r13.py','tests/static_validate_r14.py',
      'tests/static_validate_r15.py','tests/static_validate_r16.py'}
    active_forbidden=sorted(forbidden & set(paths))
    if active_forbidden:
        raise RuntimeError('Package manifest exposes superseded active entry points: '+canon(active_forbidden))
    accepted_manifest=list(csv.DictReader((HERE/'manifests/01_ACCEPTED_SOURCE_MANIFEST.csv').open(encoding='utf-8')))
    accepted_paths={row['package_path'] for row in accepted_manifest}
    omitted_accepted=sorted(accepted_paths-set(paths))
    if omitted_accepted:
        raise RuntimeError('Package manifest omits accepted source files: '+canon(omitted_accepted))
    return {'manifest_rows':len(rows),'manifest_sha256':sha256_file(manifest_path),
            'verified_files':len(rows),'required_files':sorted(required),
            'accepted_source_files':len(accepted_paths),'failures':0}

def verify_r12_failure_evidence():
    result_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r12_20260830_165946_WAVE_A_R12_RESULTS.zip'
    sidecar=Path(str(result_zip)+'.sha256')
    if not result_zip.exists() or not sidecar.exists():
        raise RuntimeError('R12 failure evidence package or sidecar is absent')
    actual=sha256_file(result_zip)
    declared=sidecar.read_text(encoding='utf-8').split()[0]
    expected_sha='7f246bebe1ed8522b1b0d68556511ec431be51b8ab6597a65e9292533aee887f'
    if actual!=declared or actual!=expected_sha:
        raise RuntimeError(f'R12 failure evidence SHA mismatch actual={actual} declared={declared}')
    with zipfile.ZipFile(result_zip) as z:
        if z.testzip() is not None:
            raise RuntimeError('R12 failure evidence ZIP integrity failed')
        receipt=json.loads(z.read('WAVE_A_R12_RECEIPT.json'))
        m2_8_detail=json.loads(z.read('evidence/compiler/M2_8_VALIDATION_DETAIL.json'))
        m2_9_detail=json.loads(z.read('evidence/compiler/M2_9_VALIDATION_DETAIL.json'))
        m2_9_schema=json.loads(z.read('evidence/compiler/M2_9_PHYSICAL_SCHEMA_VALIDATION.json'))
        log_text=z.read('logs/WAVE_A_R12.log').decode('utf-8').replace('\r\n','\n')
    expected_receipt={
      'status':'FAIL','last_stage':'COMPILER_FULL_PATH','source_modified':False,
      'diagnostic_clone_dropped':True,'compiler_clone_created':True,
      'compiler_clone_dropped':False,'final_clone_created':False,
      'compiler_db':'msbf_r1_wave_a_r12_compile_20260830_165946',
      'error':"RuntimeError('M2.9 successor checkpoint validation failed')"
    }
    bad={k:{'expected':v,'actual':receipt.get(k)} for k,v in expected_receipt.items()
         if receipt.get(k)!=v}
    if bad:
        raise RuntimeError('R12 failure receipt mismatch: '+canon(bad))
    if any(int(x.get('invalid_rows',0))!=0 for x in m2_9_detail.get('hash_columns',[])):
        raise RuntimeError('R12 M2.9 contained a hash-integrity failure')
    if any(int(x.get('true_rows',0))!=0 for x in m2_9_detail.get('boundary_flags',[])):
        raise RuntimeError('R12 M2.9 contained a no-real-world-action failure')
    if any(int(x.get('true_rows',0))!=0 for x in m2_9_detail.get('comparison',[])):
        raise RuntimeError('R12 M2.9 contained a comparison-contract failure')
    if any(x.get('status')!='PASS' for x in m2_9_detail.get('lineage',[])):
        raise RuntimeError('R12 M2.9 contained a lineage failure')
    if any(x.get('status')!='PASS' for x in m2_9_detail.get('r9_terminal_state_comparison_controls',[])):
        raise RuntimeError('R12 M2.9 contained an R9 terminal-state failure')
    schema_failures=(len(m2_9_schema.get('column_semantics_failures',[]))+
      sum(x.get('status')!='PASS' for key in ['support_objects','keys','foreign_keys','named_constraints']
          for x in m2_9_schema.get(key,[]))+
      (1 if m2_9_schema.get('comparison_view_column_contract',{}).get('status')=='FAIL' else 0))
    if schema_failures:
        raise RuntimeError(f'R12 M2.9 physical schema had {schema_failures} failures')
    expected_log_fragments=[
      "SELECT coalesce(sum(abs(reconciliation_variance_amount))+sum(abs(exposure_variance_amount)),0)::text FROM msbf_m2.account_payment_reconciliation_snapshot;\n0.02",
      "reconciliation_variance_amount<>0 OR exposure_variance_amount<>0 OR unresolved_exception_count<0;\n1"
    ]
    missing=[x for x in expected_log_fragments if x not in log_text]
    if missing:
        raise RuntimeError('R12 exact M2.9 failure outputs are absent from the retained log')
    m2_8_nullable=[x for x in m2_8_detail.get('hash_columns',[])
      if x.get('table')=='msbf_m2.account_lifecycle_transition_snapshot'
      and x.get('column')=='related_payment_event_row_hash']
    if len(m2_8_nullable)!=1 or m2_8_nullable[0].get('nullable') is not True        or int(m2_8_nullable[0].get('null_rows',-1))!=131        or int(m2_8_nullable[0].get('malformed_rows',-1))!=0        or int(m2_8_nullable[0].get('invalid_rows',-1))!=0:
        raise RuntimeError('R12 preserved M2.8 nullable-hash semantics are not exact')
    return {
      'sha256':actual,
      'compiler_db':receipt['compiler_db'],
      'failure_stage':'M2.9',
      'failure_class':'UPSTREAM_M2_8_RETRY_SETTLEMENT_ROUNDING_ORDER',
      'm2_9_total_absolute_variance':'0.02',
      'm2_9_invalid_certification_rows':1,
      'm2_9_schema_validation':'PASS',
      'm2_9_hash_boundary_comparison_lineage_terminal_controls':'PASS',
      'r12_no_rerun_required':True
    }


def verify_r13_failure_evidence():
    result_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r13_20260830_190007_WAVE_A_R13_RESULTS.zip'
    sidecar=Path(str(result_zip)+'.sha256')
    if not result_zip.exists() or not sidecar.exists():
        raise RuntimeError('R13 failure evidence package or sidecar is absent')
    actual=sha256_file(result_zip);declared=sidecar.read_text(encoding='utf-8').split()[0]
    expected='97a04a5a7b4b18c81e4ea9b0182020a9b26e9c01872221ab420ba0dff61a0ccb'
    if actual!=declared or actual!=expected:
        raise RuntimeError(f'R13 failure evidence SHA mismatch actual={actual} declared={declared}')
    with zipfile.ZipFile(result_zip) as z:
        if z.testzip() is not None: raise RuntimeError('R13 failure evidence ZIP integrity failed')
        receipt=json.loads(z.read('WAVE_A_R13_RECEIPT.json'))
        log_text=z.read('logs/WAVE_A_R13.log').decode('utf-8').replace('\r\n','\n')
        details={stage:json.loads(z.read(f'evidence/compiler/M2_{stage}_VALIDATION_DETAIL.json'))
                 for stage in ['5','6','7','8','9','10']}
        m25_schema=z.read('transformed_sources/M2_5_SCHEMA.sql').decode('utf-8')
    expected_receipt={
      'status':'FAIL','last_stage':'COMPILER_FULL_PATH','source_modified':False,
      'r12_diagnostic_retained':True,'compiler_clone_created':True,
      'compiler_clone_dropped':False,'final_clone_created':False,
      'compiler_db':'msbf_r1_wave_a_r13_compile_20260830_190007',
      'error':("RuntimeError('Command failed (1): C:\\\\Program Files\\\\PostgreSQL\\\\17\\\\bin\\\\psql.exe "
               "-h localhost -p 5432 -U postgres -d msbf_r1_wave_a_r13_compile_20260830_190007 -X -At "
               "-v ON_ERROR_STOP=1 -c SELECT count(*) FROM (SELECT * FROM "
               "msbf_m2.v_m2_5_power_bi_daily_monitoring ORDER BY scenario_id,merchant_application_id,monitoring_day_index) z;')")
    }
    bad={k:{'expected':v,'actual':receipt.get(k)} for k,v in expected_receipt.items()
         if receipt.get(k)!=v}
    if bad: raise RuntimeError('R13 failure receipt mismatch: '+canon(bad))
    required_log=[
      "INSERT INTO msbf_m12r1e.wave_a_validation_result(stage_code,control_id,status,observed) VALUES ('M2.10','R13_M2_10_RETRY_PATH_ACTIVE_RECONCILED','PASS','0');",
      "SELECT count(*) FROM (SELECT * FROM msbf_m2.v_m2_5_power_bi_daily_monitoring ORDER BY scenario_id,merchant_application_id,monitoring_day_index) z;",
      'ERROR:  column "scenario_id" does not exist',
      'Perhaps you meant to reference the column "v_m2_5_power_bi_daily_monitoring.scenario_code".'
    ]
    missing=[x for x in required_log if x not in log_text]
    if missing: raise RuntimeError('R13 exact export failure evidence is incomplete: '+canon(missing))
    if 'daily.scenario_code' not in m25_schema or 'daily.scenario_id' in m25_schema[m25_schema.find('CREATE OR REPLACE VIEW msbf_m2.v_m2_5_power_bi_daily_monitoring'):m25_schema.find('CREATE OR REPLACE VIEW msbf_m2.v_m2_5_power_bi_portfolio_summary')]:
        raise RuntimeError('R13 M2.5 Power BI physical projection evidence is inconsistent')
    recurrence=[]
    for stage,obj in details.items():
        recurrence.extend(obj.get('r13_rounding_recurrence_controls',[]))
    observed={x.get('control_id'):x.get('status') for x in recurrence}
    if observed!={cid:'PASS' for cid in R13_ROUNDING_CONTROL_IDS}:
        raise RuntimeError('R13 rounding recurrence controls did not all pass: '+canon(observed))
    return {'sha256':actual,'compiler_db':receipt['compiler_db'],
      'failure_class':'POWER_BI_EXPORT_ORDERING_COLUMN_CONTRACT',
      'failed_object':'msbf_m2.v_m2_5_power_bi_daily_monitoring',
      'invalid_ordering_column':'scenario_id','physical_projected_column':'scenario_code',
      'affected_export_objects':sorted(POWER_BI_EXPORT_CONTRACT),
      'm2_5_through_m2_10_stage_validation':'PASS',
      'r13_retry_rounding_recurrence_controls':'6_OF_6_PASS',
      'r13_no_rerun_required':True}

def verify_r14_failure_evidence():
    result_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r14_20260830_195709_WAVE_A_R14_RESULTS.zip'
    sidecar=Path(str(result_zip)+'.sha256')
    if not result_zip.exists() or not sidecar.exists():
        raise RuntimeError('R14 failure evidence package or sidecar is absent')
    actual=sha256_file(result_zip);declared=sidecar.read_text(encoding='utf-8').split()[0]
    expected='999603f8d248915431aef212392c7a8897aed859204ffa296abcf6c73ad3addf'
    if actual!=declared or actual!=expected:
        raise RuntimeError(f'R14 failure evidence SHA mismatch actual={actual} declared={declared}')
    r13_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r13_20260830_190007_WAVE_A_R13_RESULTS.zip'
    with zipfile.ZipFile(result_zip) as z:
        if z.testzip() is not None: raise RuntimeError('R14 failure evidence ZIP integrity failed')
        receipt=json.loads(z.read('WAVE_A_R14_RECEIPT.json'))
        normalized=json.loads(z.read('evidence/COMPILER_NORMALIZED_RESULT.json'))
        compiler_identity=json.loads(z.read('evidence/COMPILER_DATABASE_IDENTITY.json'))
        compiler_pbi=json.loads(z.read('evidence/compiler/91_POWER_BI_EXPORT_IDENTITY.json'))
        compiler_contract=json.loads(z.read('evidence/compiler/89_POWER_BI_VIEW_EXPORT_CONTRACT.json'))
        compiler_preflight=json.loads(z.read('evidence/compiler/90_EXPORT_QUERY_PREFLIGHT.json'))
        r13_diag=json.loads(z.read('evidence/diagnostic/R13_EXPORT_IDENTITY_READ_ONLY_DIAGNOSTIC.json'))
        r14_sql={stage:{cls:z.read(f'transformed_sources/M2_{stage}_{cls}.sql').decode('utf-8')
                         for cls in ['SCHEMA','GEN']} for stage in ['5','6','7','8','9','10']}
        log_text=z.read('logs/WAVE_A_R14.log').decode('utf-8',errors='replace').replace('\r\n','\n')
    expected_receipt={
      'status':'FAIL','last_stage':'COMPILER_FULL_PATH','source_modified':False,
      'r12_diagnostic_retained':True,'r13_diagnostic_retained':True,
      'r12_diagnostic_modified':False,'r13_diagnostic_modified':False,
      'compiler_clone_created':True,'compiler_clone_dropped':False,'final_clone_created':False,
      'compiler_db':'msbf_r1_wave_a_r14_compile_20260830_195709',
      'error':"RuntimeError('R13 diagnostic/R14 compiler database-derived identity mismatch')"
    }
    bad={k:{'expected':v,'actual':receipt.get(k)} for k,v in expected_receipt.items()
         if receipt.get(k)!=v}
    if bad: raise RuntimeError('R14 failure receipt mismatch: '+canon(bad))
    if len(normalized)!=6:
        raise RuntimeError(f'R14 compiler normalized stage count {len(normalized)} != 6')
    controls=[c for stage in normalized for c in stage.get('validation_checks',[])]
    expected_stage_counts={'M2.5':16,'M2.6':14,'M2.7':14,'M2.8':20,'M2.9':21,'M2.10':18}
    observed_stage_counts={stage:sum(c.get('stage')==stage for c in controls) for stage in expected_stage_counts}
    if len(controls)!=103 or observed_stage_counts!=expected_stage_counts or any(c.get('status')!='PASS' for c in controls):
        raise RuntimeError('R14 compiler did not preserve the exact 103-control PASS population: '+canon({
          'total':len(controls),'stage_counts':observed_stage_counts,
          'failures':[c for c in controls if c.get('status')!='PASS'][:10]}))
    if compiler_pbi!=r13_diag.get('power_bi_export_identity'):
        raise RuntimeError('R14 compiler Power BI identity differs from retained R13 diagnostic')
    if len(compiler_contract)!=6 or any(x.get('status')!='PASS' for x in compiler_contract):
        raise RuntimeError('R14 compiler Power BI view contract did not pass')
    if len(compiler_preflight)!=9 or any(x.get('status')!='PASS' for x in compiler_preflight):
        raise RuntimeError('R14 compiler complete nine-query export preflight did not pass')
    r13_identity=r13_diag.get('stable_database_identity',{})
    if compiler_identity==r13_identity:
        raise RuntimeError('R14 expected database-derived identity divergence is absent')
    if compiler_identity.get('downstream_status_sha256')!=r13_identity.get('downstream_status_sha256'):
        raise RuntimeError('R14 downstream status identity unexpectedly diverged from R13')
    if compiler_identity.get('stage_registry_rows')!=6 or compiler_identity.get('validation_rows')!=103:
        raise RuntimeError('R14 compiler database identity row counts are not exact')
    with zipfile.ZipFile(r13_zip) as z13:
        for stage in ['5','6','7']:
            for cls in ['SCHEMA','GEN']:
                prior=z13.read(f'transformed_sources/M2_{stage}_{cls}.sql').decode('utf-8')
                if prior!=r14_sql[stage][cls]:
                    raise RuntimeError(f'R13/R14 transformed SQL unexpectedly differs at M2.{stage} {cls}')
    if "jsonb_build_object('m2_5_latest',to_jsonb(latest)-'created_at','m2_5_source',to_jsonb(source)-'created_at')" not in r14_sql['6']['GEN']:
        raise RuntimeError('M2.6 predecessor source payload was not already canonicalized')
    contaminated={
      'M2.7':['to_jsonb(source) AS source_payload'],
      'M2.8':['c.source_combined_set_hash,to_jsonb(s) source_payload,NULL::text row_hash'],
      'M2.9':['ctx.source_combined_set_hash,to_jsonb(source) source_payload',
              'ctx.source_combined_set_hash,to_jsonb(payment) source_payload',
              'ctx.source_combined_set_hash,to_jsonb(transition) source_payload'],
      'M2.10':['ctx.source_combined_set_hash,to_jsonb(source) AS source_payload']}
    missing=[]
    for stage,tokens in contaminated.items():
        sql=r14_sql[stage.split('.')[1]]['GEN']
        for token in tokens:
            if sql.count(token)!=1: missing.append({'stage':stage,'token':token,'count':sql.count(token)})
    if missing: raise RuntimeError('R14 source-payload contamination anchors are not exact: '+canon(missing))
    required_log=[
      'M2.7,M2.6,fe7e331f1ea1c534d964140a8d1c5a58,746f3ae042bdc3928a81c65dd1684862',
      'M2.7,M2.6,fe7e331f1ea1c534d964140a8d1c5a58,2adc61a38c9fab9e6e6ac1e0aa662c54']
    absent=[x for x in required_log if x not in log_text]
    if absent: raise RuntimeError('R14 first-divergence log evidence is incomplete: '+canon(absent))
    return {
      'sha256':actual,'compiler_db':receipt['compiler_db'],
      'failure_class':'RUN_GENERATED_CREATED_AT_EMBEDDED_IN_NESTED_SOURCE_PAYLOAD',
      'failure_layer':'POST_BUSINESS_VALIDATION_DATABASE_DERIVED_IDENTITY',
      'business_validation':'103_OF_103_PASS',
      'power_bi_export_identity_match':True,
      'r13_database_identity':r13_identity,'r14_compiler_database_identity':compiler_identity,
      'r14_power_bi_bundle_sha256':compiler_pbi['bundle_sha256'],
      'first_divergent_stage':'M2.7','first_divergent_population_rows':130,
      'recurring_source_payload_boundaries':6,'expected_total_payload_rows':665,
      'r14_no_rerun_required':True
    }


def comparator_mutation_negative_tests(r13_snapshot,r14_snapshot):
    """Prove the corrected comparator rejects weakened, broadened, and shifted contracts."""
    import copy
    tests=[]
    def expect_failure(code,mutator,expected_fragment):
        left=copy.deepcopy(r13_snapshot);right=copy.deepcopy(r14_snapshot)
        mutator(left,right)
        try:
            compare_r13_r14_diagnostics(left,right)
        except Exception as error:
            text=repr(error)
            if expected_fragment not in text:
                raise RuntimeError(code+' raised unexpected error: '+text)
            tests.append({'test_id':code,'status':'PASS','expected_error_fragment':expected_fragment,'actual_error':text})
            return
        raise RuntimeError(code+' unexpectedly passed')

    def stage(snapshot,stage_code='M2.7'):
        return next(x for x in snapshot['stable_database_rows']['stage_registry'] if x['stage_code']==stage_code)

    expect_failure('R16_NEG_001_MUST_DIFFER_FORCED_EQUAL',
      lambda l,r: stage(r).__setitem__('accepted_output_combined_hash',stage(l)['accepted_output_combined_hash']),
      'must-differ fields unexpectedly match')
    expect_failure('R16_NEG_002_STABLE_LEGACY_HASH_MUTATED',
      lambda l,r: stage(r).__setitem__('legacy_policy_configuration_hash','00000000000000000000000000000000'),
      'must-match fields unexpectedly differ')
    expect_failure('R16_NEG_003_UNLISTED_FIELD_ADDED',
      lambda l,r: stage(r).__setitem__('uncontracted_runtime_field','unexpected'),
      'comparator field domain mismatch')
    expect_failure('R16_NEG_004_CONTRACTED_FIELD_REMOVED',
      lambda l,r: stage(r).pop('contract_table_set_sha256'),
      'comparator field domain mismatch')
    return {'status':'PASS','tests':tests,'test_count':len(tests)}


def verify_r15_failure_evidence():
    result_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r15_20260830_223334_WAVE_A_R15_RESULTS.zip'
    sidecar=Path(str(result_zip)+'.sha256')
    if not result_zip.exists() or not sidecar.exists():
        raise RuntimeError('R15 failure evidence package or sidecar is absent')
    actual=sha256_file(result_zip);declared=sidecar.read_text(encoding='utf-8').split()[0]
    expected_sha='c2c697fca404279360dacb571547fa5725ef35b1823988be0d485a83974d90fc'
    if actual!=declared or actual!=expected_sha:
        raise RuntimeError(f'R15 failure evidence SHA mismatch actual={actual} declared={declared}')
    with zipfile.ZipFile(result_zip) as z:
        if z.testzip() is not None: raise RuntimeError('R15 failure evidence ZIP integrity failed')
        receipt=json.loads(z.read('WAVE_A_R15_RECEIPT.json'))
        r13_snapshot=json.loads(z.read('evidence/diagnostic/R13_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json'))
        r14_snapshot=json.loads(z.read('evidence/diagnostic/R14_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json'))
        # The controlling runtime exception is bound in the signed-style receipt;
        # R15's command log ends at the read-only exit probes and does not duplicate it.
    exact={
      'status':'FAIL','last_stage':'R14_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC_PREFLIGHT',
      'source_db':'msbf_r1_m2_4_r6_20260830_030634',
      'r12_diagnostic_db':'msbf_r1_wave_a_r12_compile_20260830_165946',
      'r13_diagnostic_db':'msbf_r1_wave_a_r13_compile_20260830_190007',
      'r14_diagnostic_db':'msbf_r1_wave_a_r14_compile_20260830_195709',
      'compiler_db':'msbf_r1_wave_a_r15_compile_20260830_223334',
      'final_db':'msbf_r1_wave_a_r15_20260830_223334',
      'compiler_clone_created':False,'compiler_clone_exists_at_exit':False,
      'final_clone_created':False,'final_clone_exists_at_exit':False,
      'source_modified':False,'r12_diagnostic_modified':False,
      'r13_diagnostic_modified':False,'r14_diagnostic_modified':False,
      'r12_rerun_performed':False,'r13_rerun_performed':False,'r14_rerun_performed':False
    }
    bad={k:{'expected':v,'actual':receipt.get(k)} for k,v in exact.items() if receipt.get(k)!=v}
    expected_error=("RuntimeError('R13/R14 M2.7 first-divergence field set mismatch: "
      "[\"accepted_output_combined_hash\",\"successor_contract_hash\","
      "\"successor_contract_sha256\",\"successor_evidence_hash\","
      "\"successor_evidence_sha256\",\"contract_table_set_sha256\"]')")
    if receipt.get('error')!=expected_error:
        bad['error']={'expected':expected_error,'actual':receipt.get('error')}
    if bad: raise RuntimeError('R15 failure receipt mismatch: '+canon(bad))
    validate_successful_wave_diagnostic_snapshot(r13_snapshot,'R13')
    validate_successful_wave_diagnostic_snapshot(r14_snapshot,'R14')
    r13_stage={x['stage_code']:x for x in r13_snapshot['stable_database_rows']['stage_registry']}
    r14_stage={x['stage_code']:x for x in r14_snapshot['stable_database_rows']['stage_registry']}
    actual_diffs=sorted(k for k in r13_stage['M2.7'] if r13_stage['M2.7'].get(k)!=r14_stage['M2.7'].get(k))
    expected_diffs=sorted(M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT['must_differ'])
    if actual_diffs!=expected_diffs:
        raise RuntimeError('R15 evidence M2.7 actual field difference set mismatch: '+canon(actual_diffs))
    legacy_field='legacy_policy_configuration_hash'
    if r13_stage['M2.7'][legacy_field]!=r14_stage['M2.7'][legacy_field]:
        raise RuntimeError('R15 evidence legacy policy configuration hash is not stable')
    if r13_stage['M2.7'][legacy_field]!=R16_M2_7_LEGACY_POLICY_CONFIGURATION_HASH:
        raise RuntimeError('R15 evidence legacy policy configuration hash exact value mismatch')
    superseded=(HERE/'superseded/R15/src/run_wave_a_r15.py').read_text(encoding='utf-8')
    buggy_fragment=("'successor_evidence_hash','successor_evidence_sha256','legacy_policy_configuration_hash',\n"
      "      'contract_table_set_sha256'")
    if buggy_fragment not in superseded:
        raise RuntimeError('Superseded R15 over-specified comparator fragment is absent')
    comparison=compare_r13_r14_diagnostics(r13_snapshot,r14_snapshot)
    if comparison.get('status')!='PASS': raise RuntimeError('Corrected R16 comparator did not pass exact R15 snapshots')
    negative_tests=comparator_mutation_negative_tests(r13_snapshot,r14_snapshot)
    return {
      'sha256':actual,'failure_class':'READ_ONLY_DIAGNOSTIC_COMPARATOR_EXPECTED_FIELD_SET_OVER_SPECIFICATION',
      'lowest_correct_remediation_layer':'R13_R14_M2_7_DIAGNOSTIC_COMPARATOR',
      'last_stage':receipt['last_stage'],'compiler_clone_created':False,'final_clone_created':False,
      'r13_r14_m2_7_actual_different_fields':actual_diffs,
      'r13_r14_m2_7_legacy_policy_configuration_hash':r13_stage['M2.7'][legacy_field],
      'r16_corrected_comparator_replay':'PASS',
      'r16_comparator_mutation_negative_tests':negative_tests,
      'r13_database_identity':r13_snapshot['stable_database_identity'],
      'r14_database_identity':r14_snapshot['stable_database_identity'],
      'r13_power_bi_bundle_sha256':r13_snapshot['power_bi_export_identity']['bundle_sha256'],
      'r14_power_bi_bundle_sha256':r14_snapshot['power_bi_export_identity']['bundle_sha256'],
      'r13_business_bundle_sha256':r13_snapshot['source_payload_identity']['business_bundle_sha256'],
      'r14_business_bundle_sha256':r14_snapshot['source_payload_identity']['business_bundle_sha256'],
      'r15_source_payload_correction_execution_status':'NOT_STARTED',
      'r15_no_rerun_required':True
    }



def compare_r14_successor_export_preflight(baseline,candidate):
    expected_order=list(build_export_specs())
    failures=[]
    controls=[]
    baseline_names=[x.get('name') for x in baseline] if isinstance(baseline,list) else []
    candidate_names=[x.get('name') for x in candidate] if isinstance(candidate,list) else []
    domain_ok=(baseline_names==expected_order and candidate_names==expected_order and
               len(baseline_names)==len(set(baseline_names)) and
               len(candidate_names)==len(set(candidate_names)))
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_OBJECT_DOMAIN_EXACT',
      'status':'PASS' if domain_ok else 'FAIL','observed':{'expected':expected_order,
      'baseline':baseline_names,'candidate':candidate_names}})
    if not domain_ok: failures.append(controls[-1])
    base_by={x.get('name'):x for x in baseline} if isinstance(baseline,list) else {}
    cand_by={x.get('name'):x for x in candidate} if isinstance(candidate,list) else {}
    expected_fields=set(R17_PREFLIGHT_FIELD_DOMAIN)
    field_bad=[]
    for name in expected_order:
        if name not in base_by or name not in cand_by: continue
        if set(base_by[name])!=expected_fields or set(cand_by[name])!=expected_fields:
            field_bad.append({'name':name,'expected':sorted(expected_fields),
              'baseline':sorted(base_by[name]),'candidate':sorted(cand_by[name])})
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_FIELD_DOMAIN_EXACT',
      'status':'PASS' if not field_bad else 'FAIL','observed':field_bad})
    if field_bad: failures.append(controls[-1])
    query_bad=[];status_bad=[];row_bad=[]
    specs=build_export_specs()
    for name in expected_order:
        if name not in base_by or name not in cand_by: continue
        b=base_by[name];c=cand_by[name];expected_query=specs[name]
        expected_query_sha=hash_text(expected_query,'sha256')
        if (b.get('query')!=expected_query or c.get('query')!=expected_query or
            b.get('query_sha256')!=expected_query_sha or c.get('query_sha256')!=expected_query_sha):
            query_bad.append({'name':name,'expected_query':expected_query,
              'expected_query_sha256':expected_query_sha,'baseline_query':b.get('query'),
              'candidate_query':c.get('query'),'baseline_query_sha256':b.get('query_sha256'),
              'candidate_query_sha256':c.get('query_sha256')})
        for label,row in [('baseline',b),('candidate',c)]:
            if row.get('status')!='PASS' or row.get('returncode')!=0 or row.get('stderr')!='':
                status_bad.append({'name':name,'side':label,'status':row.get('status'),
                  'returncode':row.get('returncode'),'stderr':row.get('stderr')})
        expected_base=R17_BASELINE_PREFLIGHT_ROWS[name]
        expected_cand=R17_SUCCESSOR_PREFLIGHT_ROWS[name]
        if b.get('rows')!=expected_base or c.get('rows')!=expected_cand:
            row_bad.append({'name':name,'expected_baseline':expected_base,
              'actual_baseline':b.get('rows'),'expected_candidate':expected_cand,
              'actual_candidate':c.get('rows')})
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_QUERY_IDENTITY_EXACT',
      'status':'PASS' if not query_bad else 'FAIL','observed':query_bad})
    if query_bad: failures.append(controls[-1])
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_EXECUTION_STATUS_EXACT',
      'status':'PASS' if not status_bad else 'FAIL','observed':status_bad})
    if status_bad: failures.append(controls[-1])
    nonvalidation_bad=[x for x in row_bad if x['name']!='wave_a_validation_result']
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_NONVALIDATION_ROW_COUNTS_EXACT',
      'status':'PASS' if not nonvalidation_bad else 'FAIL','observed':nonvalidation_bad})
    if nonvalidation_bad: failures.append(controls[-1])
    validation_bad=[x for x in row_bad if x['name']=='wave_a_validation_result']
    delta_observed=(cand_by.get('wave_a_validation_result',{}).get('rows',-1)-
                    base_by.get('wave_a_validation_result',{}).get('rows',-1))
    validation_ok=(not validation_bad and delta_observed==R17_VALIDATION_CONTROL_DELTA and
      len(R15_SOURCE_PAYLOAD_CONTROL_IDS)==R17_VALIDATION_CONTROL_DELTA)
    controls.append({'control_id':'R17_EXPORT_PREFLIGHT_VALIDATION_CONTROL_DELTA_EXACT',
      'status':'PASS' if validation_ok else 'FAIL','observed':{
        'baseline_rows':base_by.get('wave_a_validation_result',{}).get('rows'),
        'candidate_rows':cand_by.get('wave_a_validation_result',{}).get('rows'),
        'delta':delta_observed,'expected_delta':R17_VALIDATION_CONTROL_DELTA,
        'added_control_ids':R15_SOURCE_PAYLOAD_CONTROL_IDS,'row_mismatches':validation_bad}})
    if not validation_ok: failures.append(controls[-1])
    if failures:
        raise RuntimeError('R14/successor export preflight contract failed: '+canon(failures))
    return {'status':'PASS','object_count':len(expected_order),'exact_match_object_count':8,
      'controlled_delta_object':'wave_a_validation_result','controlled_delta_field':'rows',
      'baseline_validation_rows':R17_BASELINE_PREFLIGHT_ROWS['wave_a_validation_result'],
      'successor_validation_rows':R17_SUCCESSOR_PREFLIGHT_ROWS['wave_a_validation_result'],
      'validation_control_delta':R17_VALIDATION_CONTROL_DELTA,
      'added_validation_control_ids':R15_SOURCE_PAYLOAD_CONTROL_IDS,
      'controls':controls}


def export_preflight_comparator_mutation_negative_tests(baseline,candidate):
    import copy
    tests=[]
    mutations=[
      ('R17_NEG_001_VALIDATION_DELTA_REDUCED',lambda b,c: c[1].__setitem__('rows',114),
       'VALIDATION_CONTROL_DELTA_EXACT'),
      ('R17_NEG_002_POWER_BI_ROW_COUNT_MUTATED',lambda b,c: c[2].__setitem__('rows',15599),
       'NONVALIDATION_ROW_COUNTS_EXACT'),
      ('R17_NEG_003_QUERY_TEXT_MUTATED',lambda b,c: c[3].__setitem__('query',c[3]['query']+' '),
       'QUERY_IDENTITY_EXACT'),
      ('R17_NEG_004_UNCONTRACTED_OBJECT_ADDED',lambda b,c: c.append(dict(c[-1],name='unexpected_object')),
       'OBJECT_DOMAIN_EXACT'),
      ('R17_NEG_005_EXECUTION_STATUS_MUTATED',lambda b,c: c[4].update({'status':'FAIL','returncode':1,'stderr':'forced'}),
       'EXECUTION_STATUS_EXACT'),
      ('R17_NEG_006_FIELD_DOMAIN_MUTATED',lambda b,c: c[5].__setitem__('unexpected_field','x'),
       'FIELD_DOMAIN_EXACT')]
    for test_id,mutator,fragment in mutations:
        b=copy.deepcopy(baseline);c=copy.deepcopy(candidate);mutator(b,c)
        try:
            compare_r14_successor_export_preflight(b,c)
        except Exception as error:
            ok=fragment in repr(error)
            tests.append({'test_id':test_id,'status':'PASS' if ok else 'FAIL',
              'expected_error_fragment':fragment,'actual_error':repr(error)})
        else:
            tests.append({'test_id':test_id,'status':'FAIL','expected_error_fragment':fragment,
              'actual_error':'UNEXPECTED_PASS'})
    if any(x['status']!='PASS' for x in tests):
        raise RuntimeError('R17 export-preflight comparator mutation suite failed: '+canon(tests))
    return {'status':'PASS','test_count':len(tests),'tests':tests}

def verify_r16_failure_evidence():
    result_zip=HERE/'diagnostic_inputs/msbf_r1_wave_a_r16_20260830_231947_WAVE_A_R16_RESULTS.zip'
    sidecar=Path(str(result_zip)+'.sha256')
    if not result_zip.exists() or not sidecar.exists():
        raise RuntimeError('R16 failure evidence package or sidecar is absent')
    actual=sha256_file(result_zip);declared=sidecar.read_text(encoding='utf-8').split()[0]
    expected_sha='09ce9df8d8fe3de947df025f815b09d7938c1134d457a3c2ff5a4c763c9111c9'
    if actual!=declared or actual!=expected_sha:
        raise RuntimeError(f'R16 failure evidence SHA mismatch actual={actual} declared={declared}')
    with zipfile.ZipFile(result_zip) as z:
        if z.testzip() is not None: raise RuntimeError('R16 failure evidence ZIP integrity failed')
        receipt=json.loads(z.read('WAVE_A_R16_RECEIPT.json'))
        normalized=json.loads(z.read('evidence/COMPILER_NORMALIZED_RESULT.json'))
        stable_rows=json.loads(z.read('evidence/COMPILER_STABLE_DATABASE_ROWS.json'))
        database_identity=json.loads(z.read('evidence/COMPILER_DATABASE_IDENTITY.json'))
        view_contract=json.loads(z.read('evidence/compiler/89_POWER_BI_VIEW_EXPORT_CONTRACT.json'))
        export_preflight=json.loads(z.read('evidence/compiler/90_EXPORT_QUERY_PREFLIGHT.json'))
        power_bi_identity=json.loads(z.read('evidence/compiler/91_POWER_BI_EXPORT_IDENTITY.json'))
        source_payload_identity=json.loads(z.read('evidence/compiler/92_SOURCE_PAYLOAD_CANONICALIZATION_IDENTITY.json'))
        r14_snapshot=json.loads(z.read('evidence/diagnostic/R14_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json'))
        log_text=z.read('logs/WAVE_A_R16.log').decode('utf-8').replace('\r\n','\n')
    exact={
      'status':'FAIL','last_stage':'COMPILER_FULL_PATH','source_modified':False,
      'r12_diagnostic_retained':True,'r13_diagnostic_retained':True,'r14_diagnostic_retained':True,
      'compiler_clone_created':True,'compiler_clone_dropped':False,'compiler_clone_exists_at_exit':True,
      'final_clone_created':False,'final_clone_exists_at_exit':False,
      'compiler_db':'msbf_r1_wave_a_r16_compile_20260830_231947',
      'error':"RuntimeError('R14/R16 export preflight mismatch')",
      'r12_rerun_performed':False,'r13_rerun_performed':False,'r14_rerun_performed':False,
      'r15_rerun_performed':False}
    bad={k:{'expected':v,'actual':receipt.get(k)} for k,v in exact.items() if receipt.get(k)!=v}
    if bad: raise RuntimeError('R16 failure receipt mismatch: '+canon(bad))
    stage_counts={x['stage']:len(x['validation_checks']) for x in normalized}
    expected_counts={'M2.5':16,'M2.6':14,'M2.7':16,'M2.8':22,'M2.9':27,'M2.10':20}
    checks=[c for x in normalized for c in x['validation_checks']]
    if len(normalized)!=6 or stage_counts!=expected_counts or len(checks)!=115 or any(x['status']!='PASS' for x in checks):
        raise RuntimeError('R16 compiler validation population mismatch: '+canon({
          'stage_counts':stage_counts,'total':len(checks),'failures':[x for x in checks if x['status']!='PASS']}))
    expected_identity={
      'stage_registry_sha256':'6c7b268f188d79a2f449420b2d9157b74fe0812bd90651ec2dbcf4e70855b337',
      'validation_sha256':'f7aa8c368d5869acea2a210a425418cf39aeaa5c663db378b7b4255867ecb6b0',
      'downstream_status_sha256':'2da051e8f2595c7a0b1a540ac08d5ad4890bc13620ddb79bb1ae3d7b96d94d61',
      'stage_registry_rows':6,'validation_rows':115,'downstream_status_rows':9}
    if database_identity!=expected_identity:
        raise RuntimeError('R16 compiler database identity mismatch: '+canon(database_identity))
    if power_bi_identity.get('bundle_sha256')!='f1cd6caed7568dea0b65ad1e3e5d1965453568a246dbca8f4c4ccebbcad40f20':
        raise RuntimeError('R16 curated Power BI identity mismatch')
    payload_expected={'object_count':6,'total_source_rows':665,'total_volatile_time_key_rows':0,
      'business_bundle_sha256':'76073f9a794e2ae82f30f2c37ee3170ea89c3a5b6114b6df4179d546f60b4bb0',
      'raw_payload_bundle_sha256':'4239b622d8de7e715b725ce36ba24a773922114c940023e5491320ab66c0ce2f',
      'canonical_payload_bundle_sha256':'4239b622d8de7e715b725ce36ba24a773922114c940023e5491320ab66c0ce2f'}
    payload_bad={k:{'expected':v,'actual':source_payload_identity.get(k)} for k,v in payload_expected.items()
      if source_payload_identity.get(k)!=v}
    if payload_bad: raise RuntimeError('R16 source-payload identity mismatch: '+canon(payload_bad))
    preflight_comparison=compare_r14_successor_export_preflight(r14_snapshot['export_preflight'],export_preflight)
    negative_tests=export_preflight_comparator_mutation_negative_tests(r14_snapshot['export_preflight'],export_preflight)
    if r14_snapshot['power_bi_export_identity']!=power_bi_identity:
        raise RuntimeError('R16 result R14/R16 curated Power BI identity mismatch')
    if r14_snapshot['power_bi_view_contract']!=view_contract:
        raise RuntimeError('R16 result R14/R16 Power BI view contract mismatch')
    required_log=[
      'INSERT INTO msbf_m12r1e.wave_a_validation_result(stage_code,control_id,status,observed)',
      'R15_M2_10_SOURCE_PAYLOAD_PREDECESSOR_EXACT',
      'SELECT count(*) FROM (SELECT * FROM msbf_m12r1e.wave_a_validation_result ORDER BY stage_code,control_id) z;\n115']
    missing=[x for x in required_log if x not in log_text]
    if missing: raise RuntimeError('R16 exact compiler evidence is incomplete: '+canon(missing))
    superseded=(HERE/'superseded/R16/src/run_wave_a_r16.py').read_text(encoding='utf-8')
    buggy="if candidate['export_preflight']!=r14_snapshot['export_preflight']:"
    if buggy not in superseded:
        raise RuntimeError('Superseded R16 strict export-preflight comparator is absent')
    return {
      'summary':{
        'sha256':actual,'compiler_db':receipt['compiler_db'],'failure_class':
        'CROSS_VERSION_EXPORT_PREFLIGHT_VALIDATION_POPULATION_NOT_VERSIONED',
        'lowest_correct_remediation_layer':'R14_SUCCESSOR_EXPORT_PREFLIGHT_COMPARATOR',
        'compiler_validation':'115_OF_115_PASS','power_bi_export_identity_match':True,
        'source_payload_canonicalization':'6_OBJECTS_665_ROWS_0_VOLATILE_KEYS',
        'preflight_exact_match_objects':8,'controlled_delta_object':'wave_a_validation_result',
        'baseline_validation_rows':103,'successor_validation_rows':115,'controlled_delta':12,
        'compiler_clone_created':True,'final_clone_created':False,'r16_no_rerun_required':True},
      'compiler_normalized_result':normalized,'compiler_stable_database_rows':stable_rows,
      'compiler_database_identity':database_identity,'compiler_power_bi_view_contract':view_contract,
      'compiler_export_preflight':export_preflight,'compiler_power_bi_export_identity':power_bi_identity,
      'compiler_source_payload_identity':source_payload_identity,'r14_snapshot':r14_snapshot,
      'preflight_comparison':preflight_comparison,'comparator_mutation_negative_tests':negative_tests}

def verify_strategy_configuration():
    r9_path=HERE/'config/R9_TERMINAL_STATE_COMPARISON_ALIGNMENT.json'
    r9_actual=json.loads(r9_path.read_text(encoding='utf-8'))
    r9_expected=__import__('wave_a_strategy_r9').configuration_payload()
    if r9_actual!=r9_expected:
        raise RuntimeError('R9 terminal-state comparison configuration differs from executable configuration')
    r13_path=HERE/'config/R13_M2_8_RETRY_ROUNDING_CORRECTION.json'
    r13_actual=json.loads(r13_path.read_text(encoding='utf-8'))
    r13_expected=r13_strategy.configuration_payload();r13_expected['governing_r9_configuration_sha256']=sha256_file(r9_path)
    if r13_actual!=r13_expected:
        raise RuntimeError('R13 retry-rounding configuration differs from executable configuration')
    r14_path=HERE/'config/R14_POWER_BI_EXPORT_IDENTITY_CORRECTION.json'
    r14_actual=json.loads(r14_path.read_text(encoding='utf-8'))
    r14_expected=r14_runtime_configuration_payload()
    r14_expected['governing_r13_configuration_sha256']=sha256_file(r13_path)
    r14_expected['governing_r13_result_sha256']='97a04a5a7b4b18c81e4ea9b0182020a9b26e9c01872221ab420ba0dff61a0ccb'
    if r14_actual!=r14_expected:
        raise RuntimeError('R14 export-identity configuration differs from executable configuration')
    r15_path=HERE/'config/R15_SOURCE_PAYLOAD_CANONICALIZATION_CORRECTION.json'
    r15_actual=json.loads(r15_path.read_text(encoding='utf-8'))
    r15_expected=r15_runtime_configuration_payload()
    r15_expected['governing_r13_configuration_sha256']=sha256_file(r13_path)
    r15_expected['governing_r14_configuration_sha256']=sha256_file(r14_path)
    r15_expected['governing_r14_result_sha256']='999603f8d248915431aef212392c7a8897aed859204ffa296abcf6c73ad3addf'
    strategy_path=HERE/'config/R15_STRATEGY_SOURCE_PAYLOAD_CANONICALIZATION.json'
    r15_expected['strategy_configuration_sha256']=sha256_file(strategy_path)
    if r15_actual!=r15_expected:
        raise RuntimeError('R15 source-payload configuration differs from executable configuration')
    strategy_actual=json.loads(strategy_path.read_text(encoding='utf-8'))
    strategy_expected=strategy.configuration_payload()
    strategy_expected['governing_r13_configuration_sha256']=sha256_file(r13_path)
    strategy_expected['governing_r14_configuration_sha256']=sha256_file(r14_path)
    strategy_expected['governing_r14_result_sha256']='999603f8d248915431aef212392c7a8897aed859204ffa296abcf6c73ad3addf'
    if strategy_actual!=strategy_expected:
        raise RuntimeError('R15 executable strategy configuration differs from frozen strategy configuration')
    r16_path=HERE/'config/R16_R13_R14_M2_7_DIAGNOSTIC_COMPARATOR_CORRECTION.json'
    r16_actual=json.loads(r16_path.read_text(encoding='utf-8'))
    r16_expected=r16_runtime_configuration_payload()
    r16_expected['governing_r15_runtime_configuration_sha256']=sha256_file(r15_path)
    r16_expected['governing_r15_strategy_configuration_sha256']=sha256_file(strategy_path)
    r16_expected['governing_r15_result_sha256']='c2c697fca404279360dacb571547fa5725ef35b1823988be0d485a83974d90fc'
    if r16_actual!=r16_expected:
        raise RuntimeError('R16 diagnostic-comparator configuration differs from executable configuration')
    r17_path=HERE/'config/R17_R14_SUCCESSOR_EXPORT_PREFLIGHT_COMPARATOR_CORRECTION.json'
    r17_actual=json.loads(r17_path.read_text(encoding='utf-8'))
    r17_expected=r17_runtime_configuration_payload()
    r17_expected['governing_r16_runtime_configuration_sha256']=sha256_file(r16_path)
    r17_expected['governing_r16_result_sha256']='09ce9df8d8fe3de947df025f815b09d7938c1134d457a3c2ff5a4c763c9111c9'
    r17_expected['governing_r15_strategy_configuration_sha256']=sha256_file(strategy_path)
    if r17_actual!=r17_expected:
        raise RuntimeError('R17 export-preflight comparator configuration differs from executable configuration')
    return {
      'r9_configuration_sha256':sha256_file(r9_path),
      'r13_configuration_sha256':sha256_file(r13_path),
      'r14_configuration_sha256':sha256_file(r14_path),
      'r15_runtime_configuration_sha256':sha256_file(r15_path),
      'r15_strategy_configuration_sha256':sha256_file(strategy_path),
      'r16_runtime_configuration_sha256':sha256_file(r16_path),
      'r17_runtime_configuration_sha256':sha256_file(r17_path),
      'correction_code':r17_actual['correction_code'],'policy_change':False,
      'generation_methods_changed':r15_actual['generation_methods_changed'],
      'database_validation_controls_carried_forward':115,
      'export_preflight_comparator_controls':r17_actual['export_preflight_comparator_controls'],
      'stage_codes':[x['stage'] for x in r17_actual['power_bi_export_objects']]}

def source_control(psql,conn,db,env,log):
    sql=r"""
    WITH r AS (
      SELECT count(*)::bigint row_count,max(rr.run_id)::bigint run_id,max(rr.run_status)::text run_status
      FROM msbf_ctl.run_registry rr
      WHERE rr.run_code='M1_V0_2_BASELINE_BUILD' AND rr.run_version=1
    ), reg AS (
      SELECT count(*)::bigint row_count,max(cr.contract_status)::text contract_status,max(cr.combined_set_hash)::text combined_set_hash
      FROM msbf_ctl.m2_4_portfolio_activation_contract_registry cr CROSS JOIN r
      WHERE cr.module1_run_id=r.run_id
    ), gate AS (
      SELECT count(*)::bigint row_count,(array_agg(agr.result_status ORDER BY agr.review_version DESC))[1]::text result_status
      FROM msbf_ctl.acceptance_gate_result agr CROSS JOIN r
      WHERE agr.run_id=r.run_id AND agr.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'
    ), rb AS (
      SELECT count(*)::bigint row_count,max(ds.rebase_status)::text rebase_status
      FROM msbf_m12r1e.downstream_rebase_status ds WHERE ds.stage_code='M2_4'
    )
    SELECT jsonb_build_object(
      'run_row_count',r.row_count,'run_id',r.run_id,'run_status',r.run_status,
      'm2_4_registry_row_count',reg.row_count,'m2_4_contract_status',reg.contract_status,
      'm2_4_combined_set_hash',reg.combined_set_hash,
      'm2_4_gate_row_count',gate.row_count,'m2_4_gate_status',gate.result_status,
      'm2_4_rebase_row_count',rb.row_count,'m2_4_rebase_status',rb.rebase_status,
      'account_rows',(SELECT count(*) FROM msbf_m2.synthetic_account_activation),
      'advance_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding),
      'portfolio_rows',(SELECT count(*) FROM msbf_m2.initial_portfolio_activation),
      'baseline_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE scenario_code='BASELINE'),
      'stress_funded_rows',(SELECT count(*) FROM msbf_m2.synthetic_advance_funding WHERE scenario_code='RECESSION_ENERGY'),
      'physical_m2_4_rows',(SELECT sum(n) FROM (
        SELECT count(*) n FROM msbf_m2.application_booking_funding_source_snapshot
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_snapshot
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_latest
        UNION ALL SELECT count(*) FROM msbf_m2.application_booking_funding_activation_archive
        UNION ALL SELECT count(*) FROM msbf_m2.synthetic_account_activation
        UNION ALL SELECT count(*) FROM msbf_m2.synthetic_advance_funding
        UNION ALL SELECT count(*) FROM msbf_m2.initial_portfolio_activation
      ) x),
      'downstream_pending',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status
        WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12') AND rebase_status='PENDING_REBASE'),
      'active_downstream_registries',(SELECT sum(n) FROM (
        SELECT count(*) n FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_6_intervention_strategy_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_7_operational_activation_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_8_servicing_execution_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry
        UNION ALL SELECT count(*) FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry
      ) x),
      'rebase_status_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status),
      'rebase_status_exact_domain_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status
        WHERE stage_code IN ('M2_4','M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12')),
      'r4_application_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_application_scenario),
      'r4_candidate_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_offer_candidate),
      'r4_final_decision_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_final_decision),
      'r4_gate_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_decision_gate),
      'r4_proof_rows',(SELECT count(*) FROM msbf_m12r1d.pbi_fact_no_feasible_structure_proof),
      'source_integration_rows',(SELECT count(*) FROM msbf_m12r1e.source_integration_registry),
      'compatibility_rows',(SELECT count(*) FROM msbf_m12r1e.application_final_offer_decision_compatibility),
      'active_downstream_gates',(SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE gate_id IN (
        'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING','M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY',
        'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL',
        'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION',
        'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'))
    )::text FROM r CROSS JOIN reg CROSS JOIN gate CROSS JOIN rb;
    """
    raw=scalar(psql,conn,db,env,log,sql)
    if not raw: raise RuntimeError('R6 source-control query returned no row')
    return json.loads(raw)

def validate_source_control(c):
    expected={
      'run_row_count':1,'run_status':'M2_4_ACCEPTED','m2_4_registry_row_count':1,
      'm2_4_contract_status':'ACCEPTED','m2_4_combined_set_hash':'deedb8bd7696e441126a6f4526fc4842',
      'm2_4_gate_row_count':1,'m2_4_gate_status':'PASS','m2_4_rebase_row_count':1,
      'm2_4_rebase_status':'VALIDATED_CANDIDATE','account_rows':130,'advance_rows':130,
      'portfolio_rows':130,'baseline_funded_rows':103,'stress_funded_rows':27,
      'physical_m2_4_rows':6390,'downstream_pending':8,'active_downstream_registries':0,
      'active_downstream_gates':0,'rebase_status_rows':9,'rebase_status_exact_domain_rows':9,
      'r4_application_rows':1500,'r4_candidate_rows':6519,'r4_final_decision_rows':1500,
      'r4_gate_rows':84228,'r4_proof_rows':652,'source_integration_rows':1,'compatibility_rows':1500}
    bad={k:{'expected':v,'actual':c.get(k)} for k,v in expected.items() if c.get(k)!=v}
    if bad: raise RuntimeError('R6 source control mismatch: '+canon(bad))
    return expected

def control_fingerprint(c): return hash_text(canon(c),'sha256')

def catalog_column_preflight(psql,conn,db,env,log):
    req=list(csv.DictReader((HERE/'manifests/12_SOURCE_CONTROL_COLUMN_CONTRACT.csv').open(encoding='utf-8')))
    out=[]
    aliases={'int8':'bigint','int4':'integer','int2':'smallint','timestamp with time zone':'timestamptz','timestamp without time zone':'timestamp'}
    for r in req:
        sql=f"SELECT data_type FROM information_schema.columns WHERE table_schema='{r['schema_name']}' AND table_name='{r['object_name']}' AND column_name='{r['column_name']}';"
        actual=scalar(psql,conn,db,env,log,sql)
        exp=r['expected_type'].strip().lower();act=actual.strip().lower()
        ok=bool(actual) and aliases.get(act,act)==aliases.get(exp,exp)
        out.append({**r,'actual_type':actual,'status':'PASS' if ok else 'FAIL'})
    failures=[x for x in out if x['status']=='FAIL']
    if failures: raise RuntimeError('Source-control column contract failed: '+canon(failures))
    return out

def normalize_default(x):
    if x is None:return ''
    x=re.sub(r'\s+','',x.lower())
    while x.startswith('(') and x.endswith(')'):x=x[1:-1]
    x=x.replace('::timestampwithtimezone','').replace('::timestampwithouttimezone','')
    return x

def physical_semantics_validate(psql,conn,db,env,log,stage):
    cols=list(csv.DictReader((HERE/'manifests/06_PHYSICAL_COLUMN_SEMANTICS_M2_5_M2_10.csv').open(encoding='utf-8')))
    cols=[r for r in cols if r['stage']==stage];bad=[]
    for r in cols:
        sql=f"""SELECT format_type(a.atttypid,a.atttypmod),a.attnotnull,coalesce(pg_get_expr(ad.adbin,ad.adrelid),''),a.attidentity,a.attgenerated
        FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace
        LEFT JOIN pg_attrdef ad ON ad.adrelid=a.attrelid AND ad.adnum=a.attnum
        WHERE n.nspname='{r['schema_name']}' AND c.relname='{r['object_name_only']}' AND a.attname='{r['column_name']}' AND a.attnum>0 AND NOT a.attisdropped;"""
        cp=run([psql,*conn,'-d',db,'-X','-At','-F','|','-v','ON_ERROR_STOP=1','-c',sql],env,log)
        lines=[x for x in cp.stdout.splitlines() if x]
        if len(lines)!=1:bad.append({**r,'issue':'MISSING_OR_DUPLICATE_COLUMN'});continue
        typ,nn,default_expr,ident,gen=lines[0].split('|')
        type_ok=core.normalize_pg_type(r['data_type_sql'])==core.normalize_pg_type(typ)
        expected_default=(r['default_present']=='1');default_ok=expected_default==(default_expr!='')
        if expected_default:default_ok=default_ok and normalize_default(default_expr)==normalize_default(r.get('default_expression') or '')
        semantics_ok=(r['not_null_required']=='1')==(nn=='t') and default_ok and (r['identity_or_generated_required']=='1')==bool(ident or gen)
        if not type_ok or not semantics_ok:
            bad.append({**r,'issue':'SEMANTICS_MISMATCH','actual_type':typ,'actual_not_null':nn,'actual_default_expression':default_expr,'actual_identity':ident,'actual_generated':gen})
    return bad

def patch_m2_10_mapping(txt):
    start='DROP TABLE IF EXISTS _m2_10_source_classified;';end='ANALYZE _m2_10_source_classified;'
    if txt.count(start)!=1 or txt.count(end)!=1:raise RuntimeError('M2.10 source-classification block boundary mismatch')
    a=txt.index(start);b=txt.index(end,a)+len(end)
    block=r"""DROP TABLE IF EXISTS _m2_10_source_classified;
CREATE TEMP TABLE _m2_10_source_classified ON COMMIT DROP AS
WITH classified AS
(
 SELECT source.*,
 CASE
  WHEN source.reconciliation_outcome_code='NO_PAYMENT_ACTIVITY_RECONCILED'
   AND source.certified_state_code='CERTIFIED_CLOSED_NO_PROCESSING'
   AND source.state_certified_flag IS TRUE AND source.closed_state_flag IS TRUE
   AND source.active_state_flag IS FALSE AND source.review_hold_state_flag IS FALSE
   AND source.exception_resolved_flag IS FALSE AND source.exception_case_count=0
   AND source.resolved_exception_count=0 AND source.unresolved_exception_count=0
   AND source.certified_exposure_amount=0 AND source.scheduled_payment_amount=0
   AND source.processed_payment_amount=0 AND source.returned_payment_amount=0
   AND source.retry_payment_amount=0 AND source.reconciliation_variance_amount=0
   AND source.exposure_variance_amount=0
  THEN 'CLOSED_STABLE'
  WHEN source.reconciliation_outcome_code IN ('PAYMENT_ACTIVITY_RECONCILED','PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY')
   AND source.certified_state_code IN ('CERTIFIED_ACTIVE_CURRENT','CERTIFIED_ACTIVE_AFTER_RETRY','CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY')
   AND source.state_certified_flag IS TRUE AND source.active_state_flag IS TRUE
   AND source.closed_state_flag IS FALSE AND source.review_hold_state_flag IS FALSE
   AND source.payment_event_count>0
   AND source.payment_event_count=source.settled_event_count+source.returned_event_count+source.retry_event_count
   AND source.unresolved_exception_count=0
   AND source.scheduled_payment_amount>0 AND source.processed_payment_amount=source.scheduled_payment_amount
   AND source.returned_payment_amount=source.retry_payment_amount
   AND source.certified_exposure_amount>=0 AND source.reconciliation_variance_amount=0
   AND source.exposure_variance_amount=0
   AND (source.reconciliation_outcome_code<>'PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
        OR (source.exception_resolved_flag IS TRUE AND source.exception_case_count>=1
            AND source.resolved_exception_count=source.exception_case_count
            AND source.returned_event_count>=1 AND source.retry_event_count>=1))
  THEN 'ACTIVE_RECONCILED'
  WHEN source.reconciliation_outcome_code IN ('RECONCILIATION_REVIEW_HOLD','PAYMENT_ACTIVITY_VARIANCE','PAYMENT_EXCEPTION_UNRESOLVED','RECONCILIATION_CERTIFICATION_FAILED')
    OR source.review_hold_state_flag IS TRUE OR source.state_certified_flag IS FALSE
  THEN 'CONTROLLED_REVIEW'
  ELSE 'SOURCE_MAPPING_ERROR'
 END AS successor_posture_code
 FROM _m2_10_source_expected source
)
SELECT classified.*,
 successor_posture_code AS source_mapping_code,
 successor_posture_code AS performance_tier_code,
 CASE successor_posture_code WHEN 'CLOSED_STABLE' THEN 'NO_SERVICING_REQUIRED'
  WHEN 'ACTIVE_RECONCILED' THEN 'ACTIVE_REASSESSMENT'
  WHEN 'CONTROLLED_REVIEW' THEN 'GOVERNANCE_REVIEW_HOLD' ELSE 'SOURCE_MAPPING_ERROR' END AS servicing_queue_code,
 CASE successor_posture_code WHEN 'CLOSED_STABLE' THEN 'M2_10_REASON_CLOSED_STABLE'
  WHEN 'ACTIVE_RECONCILED' THEN 'M2_10_REASON_ACTIVE_RECONCILED'
  WHEN 'CONTROLLED_REVIEW' THEN 'M2_10_REASON_CONTROLLED_REVIEW'
  ELSE 'M2_10_REASON_SOURCE_MAPPING_ERROR' END AS primary_portfolio_reason_code
FROM classified;
CREATE UNIQUE INDEX ON _m2_10_source_classified(module1_run_id,scenario_id,merchant_application_id);
CREATE INDEX ON _m2_10_source_classified(module1_run_id,source_mapping_code);
ANALYZE _m2_10_source_classified;"""
    return txt[:a]+block+txt[b:]

def transform(stage,src_class,txt,prior_hash):
    m=META[stage]
    count=txt.count(m['old_hash'])
    if count<1: raise RuntimeError(f"{m['stage']} {src_class} predecessor hash literal absent")
    txt=txt.replace(m['old_hash'],prior_hash)
    if stage!='5':
        prev=m['prev'].replace('.','_')
        txt=txt.replace(prev+'_ACCEPTED',prev+'_GENERATED')
        txt=txt.replace("registry.contract_status='ACCEPTED'","registry.contract_status='GENERATED'")
        txt=txt.replace("registry.contract_status = 'ACCEPTED'","registry.contract_status = 'GENERATED'")
    if src_class=='SCHEMA': txt=strategy.patch_schema(stage,txt)
    if src_class=='GEN':
        for tag in m.get('remove_tags',[]): txt=core.remove_tagged_block(txt,tag)
        if stage=='10': txt=patch_m2_10_mapping(txt)
        txt=strategy.patch_generation(stage,txt)
    return txt

def static_transform_preflight():
    controls=[];placeholder='0123456789abcdef0123456789abcdef'
    schema_markers={
      '6':['NOT baseline_source.paid_off_flag','NOT stress_source.paid_off_flag'],
      '7':['NOT baseline.no_setup_required_flag','NOT stress.no_setup_required_flag'],
      '8':['NOT baseline_terminal_flag','NOT stress_terminal_flag','no_processing_required_flag'],
      '9':['NOT baseline_terminal_flag','NOT stress_terminal_flag','closed_state_flag'],
      '10':["baseline_performance_tier_code<>'CLOSED_STABLE'","stress_performance_tier_code<>'CLOSED_STABLE'"]}
    for stage in STAGES:
        m=META[stage];srcs={r['source_class']:r for r in SRC_MAN if r['stage']==m['stage']}
        for cls in ['SCHEMA','GEN']:
            p=HERE/srcs[cls]['package_path'];raw=p.read_text(encoding='utf-8')
            transformed=transform(stage,cls,raw,placeholder);core.lexical_sql_check(transformed)
            if m['old_hash'] in transformed or placeholder not in transformed: raise RuntimeError(f'{m["stage"]} {cls} transform binding failed')
            tags=re.findall(r'DO\s+\$([A-Za-z0-9_]*)\$',transformed,re.I)
            if cls=='GEN' and sorted(tags)!=sorted(m.get('retained_do_tags',[])): raise RuntimeError(f'{m["stage"]} retained DO tags mismatch {tags}')
            for tag in m.get('remove_tags',[]):
                if re.search(r'DO\s+\$'+re.escape(tag)+r'\$',transformed,re.I): raise RuntimeError(f'{m["stage"]} retained removed guard {tag}')
            if cls=='SCHEMA' and stage in schema_markers:
                missing=[x for x in schema_markers[stage] if x not in transformed]
                if missing: raise RuntimeError(f'{m["stage"]} terminal-state alignment missing {missing}')
            if cls=='GEN' and stage=='6':
                if 'open_rank' not in transformed: raise RuntimeError('M2.6 accepted generation method was unexpectedly replaced')
                forbidden=['M2_6_REASON_DORMANT_WORKOUT_REVIEW','R8_SUCCESSOR_M2_6_STATUS_MONOTONIC_MAPPING']
                present=[x for x in forbidden if x in transformed]
                if present: raise RuntimeError(f'M2.6 retained withdrawn R8 generation overlay {present}')
            if cls=='GEN' and stage=='7' and 'R8_SUCCESSOR_M2_7_SOURCE_REVIEW_GATE_PRESERVED' in transformed:
                raise RuntimeError('M2.7 retained withdrawn R8 generation overlay')
            if cls=='GEN' and stage=='8':
                if strategy.OLD_RETRY_EXPRESSION in transformed:
                    raise RuntimeError('M2.8 retained the R12 retry-rounding expression')
                if transformed.count(strategy.NEW_RETRY_EXPRESSION)!=1:
                    raise RuntimeError('M2.8 corrected retry-rounding expression is not unique')
            if cls=='GEN':
                for old_payload,new_payload,label in strategy.GENERATION_REPLACEMENTS.get(stage,[]):
                    if old_payload in transformed:
                        raise RuntimeError(f'{m["stage"]} retained volatile source-payload expression {label}')
                    if transformed.count(new_payload)!=1:
                        raise RuntimeError(f'{m["stage"]} canonical source-payload expression is not unique {label}')
            if stage=='10' and cls=='GEN':
                for literal in ['=323.79','=461.69','=194.25','=27.75']:
                    if literal in transformed: raise RuntimeError(f'M2.10 retained fixture mapping literal {literal}')
                for token in ['exception_resolved_flag IS FALSE','payment_event_count=source.settled_event_count+source.returned_event_count+source.retry_event_count','successor_posture_code']:
                    if token not in transformed: raise RuntimeError(f'M2.10 generalized mapping missing {token}')
            controls.append({'stage':m['stage'],'source_class':cls,'status':'PASS','transformed_bytes':len(transformed.encode()),
                'sha256':hash_text(transformed,'sha256'),'hash_literal_replacements':raw.count(m['old_hash']),'retained_do_tags':'|'.join(tags)})
    return controls

def db_drop(dropdb,conn,db,env,log):
    cp=run([dropdb,*conn,'--force',db],env,log,check=False)
    return cp.returncode==0


def clone_base_control(psql,conn,db,env,log):
    """Validate the cleaned pre-M2.5 candidate state without assuming future-stage tables exist."""
    run_status=scalar(psql,conn,db,env,log,"SELECT run_status FROM msbf_ctl.run_registry WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;")
    stage_tables=[]
    for s in STAGES:
        stage_tables.extend(META[s]['tables'])
    present=[]
    for t in sorted(set(stage_tables)):
        if scalar(psql,conn,db,env,log,f"SELECT to_regclass('{t}') IS NOT NULL;")=='t':
            present.append(t)
    stage_registry_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1e.wave_a_stage_registry;"))
    validation_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1e.wave_a_validation_result;"))
    status_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status;"))
    m24_status=scalar(psql,conn,db,env,log,"SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_4';")
    pending=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12') AND rebase_status='PENDING_REBASE';"))
    gates=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE gate_id IN ('M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING','M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY','M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP','M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL','M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION','M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS');"))
    r4_apps=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1d.pbi_fact_application_scenario;"))
    r4_cands=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1d.pbi_fact_offer_candidate;"))
    r4_decisions=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1d.pbi_fact_final_decision;"))
    compatibility=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m12r1e.application_final_offer_decision_compatibility;"))
    return {
      'run_status':run_status,'present_stage_tables':present,'stage_registry_rows':stage_registry_rows,
      'validation_rows':validation_rows,'rebase_status_rows':status_rows,'m2_4_rebase_status':m24_status,
      'downstream_pending':pending,'active_downstream_gates':gates,'r4_application_rows':r4_apps,
      'r4_candidate_rows':r4_cands,'r4_final_decision_rows':r4_decisions,'compatibility_rows':compatibility}

def validate_clone_base(c):
    expected={'run_status':'M2_4_ACCEPTED','stage_registry_rows':0,'validation_rows':0,
      'rebase_status_rows':9,'m2_4_rebase_status':'VALIDATED_CANDIDATE','downstream_pending':8,
      'active_downstream_gates':0,'r4_application_rows':1500,'r4_candidate_rows':6519,
      'r4_final_decision_rows':1500,'compatibility_rows':1500}
    bad={k:{'expected':v,'actual':c.get(k)} for k,v in expected.items() if c.get(k)!=v}
    if c.get('present_stage_tables'):bad['present_stage_tables']={'expected':[],'actual':c.get('present_stage_tables')}
    if bad:raise RuntimeError('Wave A cleaned-clone base mismatch: '+canon(bad))
    return expected

def setup_wave_database(psql,conn,db,env,log):
    ctl_sql="""
    CREATE SCHEMA IF NOT EXISTS msbf_m12r1e;
    DROP TABLE IF EXISTS msbf_m12r1e.wave_a_stage_registry CASCADE;
    DROP TABLE IF EXISTS msbf_m12r1e.wave_a_validation_result CASCADE;
    DROP TABLE IF EXISTS msbf_m12r1e.wave_a_legacy_run_evidence_archive CASCADE;
    CREATE TABLE msbf_m12r1e.wave_a_stage_registry(
      stage_code text primary key,predecessor_stage_code text not null,
      accepted_predecessor_combined_hash text not null,accepted_output_combined_hash text not null,
      successor_contract_hash text not null,successor_contract_sha256 text not null,
      successor_evidence_hash text not null,successor_evidence_sha256 text not null,
      accepted_schema_source_sha256 text not null,accepted_generation_source_sha256 text not null,
      transformed_schema_sha256 text not null,transformed_generation_sha256 text not null,
      policy_method_hash text not null,policy_method_payload jsonb not null,
      legacy_policy_configuration_hash text,contract_table_set_sha256 text not null,
      source_rows bigint not null,baseline_rows bigint not null,stress_rows bigint not null,
      actual_population_payload jsonb not null,legacy_registry_payload jsonb,
      legacy_registry_status text not null,contract_authority text not null,
      validation_status text not null,validated_at timestamptz not null default clock_timestamp());
    CREATE TABLE msbf_m12r1e.wave_a_validation_result(stage_code text not null,control_id text not null,status text not null,observed text,evaluated_at timestamptz not null default clock_timestamp(),primary key(stage_code,control_id));
    CREATE TABLE msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code text not null,evidence_payload jsonb not null,archived_at timestamptz not null default clock_timestamp());
    """
    run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1'],env,log,input_text=ctl_sql)
    all_tables=[]
    for s in reversed(STAGES):all_tables+=META[s]['tables']
    drop='\n'.join(f'DROP TABLE IF EXISTS {t} CASCADE;' for t in all_tables)
    cleanup=drop+"""
    INSERT INTO msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code,evidence_payload)
      SELECT split_part(evidence_code,'_',1)||'.'||split_part(evidence_code,'_',2),to_jsonb(e)
      FROM msbf_ctl.run_evidence e WHERE run_id=1 AND evidence_code ~ '^M2_(5|6|7|8|9|10)_';
    DELETE FROM msbf_ctl.run_evidence WHERE run_id=1 AND evidence_code ~ '^M2_(5|6|7|8|9|10)_';
    DELETE FROM msbf_ctl.acceptance_gate_result WHERE run_id=1 AND gate_id ~ '^M2_(5|6|7|8|9|10)_';
    UPDATE msbf_ctl.run_registry SET run_status='M2_4_ACCEPTED' WHERE run_id=1;
    """
    run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1'],env,log,input_text=cleanup)

def compile_transformed(stage,prior,transformed_root,mode,compiler_stage=None):
    m=META[stage];srcs={r['source_class']:r for r in SRC_MAN if r['stage']==m['stage']};trans={}
    for cls in ['SCHEMA','GEN']:
        tp=transformed_root/f"{m['stage'].replace('.','_')}_{cls}.sql"
        if mode=='COMPILER':
            txt=(HERE/srcs[cls]['package_path']).read_text(encoding='utf-8');ot=transform(stage,cls,txt,prior);core.lexical_sql_check(ot);tp.write_text(ot,encoding='utf-8',newline='\n')
        else:
            if not tp.exists():raise RuntimeError(f'Missing compiler-transformed source {tp}')
            expected=(compiler_stage or {}).get('transformed_'+cls.lower()+'_sha256')
            if expected and sha256_file(tp)!=expected:raise RuntimeError(f'Final transformed source hash changed {m["stage"]} {cls}')
            text=tp.read_text(encoding='utf-8')
            if prior not in text:raise RuntimeError(f'Final transformed source predecessor hash mismatch {m["stage"]} {cls}')
        trans[cls]=tp
    return trans,srcs

def insert_registry(psql,conn,db,env,log,vals):
    cols=list(vals);lits=[]
    for c in cols:
        v=vals[c]
        if v is None:lits.append('NULL')
        elif c in ('source_rows','baseline_rows','stress_rows'):lits.append(str(v))
        elif c in ('actual_population_payload','legacy_registry_payload','policy_method_payload'):lits.append("'"+v.replace("'","''")+"'::jsonb")
        else:lits.append("'"+str(v).replace("'","''")+"'")
    run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',f"INSERT INTO msbf_m12r1e.wave_a_stage_registry({','.join(cols)}) VALUES ({','.join(lits)});"],env,log)

def check_row(stage,control_id,ok,observed):
    return {'stage':META[stage]['stage'],'control_id':control_id,'status':'PASS' if ok else 'FAIL',
            'observed':canon(observed) if not isinstance(observed,str) else observed}


def normalized_csv_payload(text):
    payload=(text or '').replace('\r\n','\n').replace('\r','\n')
    return payload.rstrip('\n')+'\n'


def query_csv_rows(psql,conn,db,env,log,sql):
    cp=run([psql,*conn,'-d',db,'-X','--csv','-v','ON_ERROR_STOP=1','-c',sql],env,log)
    payload=normalized_csv_payload(cp.stdout)
    rows=list(csv.DictReader(io.StringIO(payload)))
    return rows,payload


def stable_database_rows(psql,conn,db,env,log):
    stage_sql="""SELECT stage_code,predecessor_stage_code,accepted_predecessor_combined_hash,
      accepted_output_combined_hash,successor_contract_hash,successor_contract_sha256,
      successor_evidence_hash,successor_evidence_sha256,accepted_schema_source_sha256,
      accepted_generation_source_sha256,transformed_schema_sha256,transformed_generation_sha256,
      policy_method_hash,legacy_policy_configuration_hash,contract_table_set_sha256,
      source_rows,baseline_rows,stress_rows,actual_population_payload,legacy_registry_status,
      validation_status FROM msbf_m12r1e.wave_a_stage_registry ORDER BY stage_code;"""
    validation_sql="""SELECT stage_code,control_id,status,observed
      FROM msbf_m12r1e.wave_a_validation_result ORDER BY stage_code,control_id;"""
    downstream_sql="""SELECT stage_code,rebase_status
      FROM msbf_m12r1e.downstream_rebase_status
      WHERE stage_code IN ('M2_4','M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12')
      ORDER BY stage_code;"""
    stages,_=query_csv_rows(psql,conn,db,env,log,stage_sql)
    validations,_=query_csv_rows(psql,conn,db,env,log,validation_sql)
    downstream,_=query_csv_rows(psql,conn,db,env,log,downstream_sql)
    for row in stages:
        try: row['actual_population_payload']=json.loads(row['actual_population_payload'])
        except Exception: pass
    return {'stage_registry':stages,'validation':validations,'downstream':downstream}


def table_business_identity(psql,conn,db,env,log,table,keys):
    schema_name,table_name=table.split('.',1)
    cols=run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',
      "SELECT column_name FROM information_schema.columns WHERE table_schema='"+
      schema_name.replace("'","''")+"' AND table_name='"+table_name.replace("'","''")+
      "' ORDER BY ordinal_position;"],env,log).stdout.splitlines()
    excluded=set(TIME_KEYS)|{'source_payload'}
    projected=[c for c in cols if c not in excluded and 'hash' not in c.lower()]
    if not projected: raise RuntimeError('No business columns available for '+table)
    query='SELECT '+','.join(qident(c) for c in projected)+' FROM '+table+' ORDER BY '+','.join(qident(c) for c in keys)+';'
    rows,payload=query_csv_rows(psql,conn,db,env,log,query)
    return {'table':table,'keys':keys,'columns':projected,'rows':len(rows),
      'csv_sha256':hash_text(payload,'sha256'),'csv_bytes':len(payload.encode('utf-8'))}


def source_payload_identity_snapshot(psql,conn,db,env,log):
    output={}
    time_array="ARRAY["+','.join("'"+k.replace("'","''")+"'" for k in VOLATILE_PAYLOAD_KEYS)+"]::text[]"
    for code,spec in SOURCE_PAYLOAD_SPECS.items():
        source=spec['source_table'];predecessor=spec['predecessor_table'];keys=spec['keys']
        order=','.join('s.'+qident(k) for k in keys)
        join=' AND '.join('s.'+qident(k)+'=p.'+qident(k) for k in keys)
        key_select=','.join('s.'+qident(k) for k in keys)
        raw_query='SELECT '+key_select+',s.source_payload::text AS source_payload FROM '+source+' s ORDER BY '+order+';'
        canonical_query=('SELECT '+key_select+',(s.source_payload-'+time_array+
          ')::text AS source_payload FROM '+source+' s ORDER BY '+order+';')
        predecessor_query=('SELECT '+','.join('p.'+qident(k) for k in keys)+
          ',(to_jsonb(p)-'+time_array+')::text AS source_payload FROM '+predecessor+
          ' p ORDER BY '+','.join('p.'+qident(k) for k in keys)+';')
        raw_rows,raw_payload=query_csv_rows(psql,conn,db,env,log,raw_query)
        canonical_rows,canonical_payload=query_csv_rows(psql,conn,db,env,log,canonical_query)
        predecessor_rows,predecessor_payload=query_csv_rows(psql,conn,db,env,log,predecessor_query)
        volatile=int(scalar(psql,conn,db,env,log,
          'SELECT count(*) FROM '+source+' WHERE source_payload ?| ARRAY['+
          ','.join("'"+k.replace("'","''")+"'" for k in VOLATILE_PAYLOAD_KEYS)+'];'))
        created=int(scalar(psql,conn,db,env,log,
          "SELECT count(*) FROM "+source+" WHERE source_payload ? 'created_at';"))
        raw_predecessor_mismatch=int(scalar(psql,conn,db,env,log,
          'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+
          ' WHERE s.source_payload IS DISTINCT FROM to_jsonb(p);'))
        canonical_predecessor_mismatch=int(scalar(psql,conn,db,env,log,
          'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+
          ' WHERE (s.source_payload-'+time_array+') IS DISTINCT FROM (to_jsonb(p)-'+time_array+');'))
        active_canonical_mismatch=int(scalar(psql,conn,db,env,log,
          'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+
          " WHERE s.source_payload IS DISTINCT FROM (to_jsonb(p)-'created_at');"))
        join_rows=int(scalar(psql,conn,db,env,log,
          'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+';'))
        source_rows=int(scalar(psql,conn,db,env,log,'SELECT count(*) FROM '+source+';'))
        predecessor_rows_count=int(scalar(psql,conn,db,env,log,'SELECT count(*) FROM '+predecessor+';'))
        output[code]={
          'source_table':source,'predecessor_table':predecessor,'keys':keys,
          'source_rows':source_rows,'predecessor_rows':predecessor_rows_count,'joined_rows':join_rows,
          'volatile_time_key_rows':volatile,'created_at_key_rows':created,
          'raw_predecessor_mismatch_rows':raw_predecessor_mismatch,
          'canonical_predecessor_mismatch_rows':canonical_predecessor_mismatch,
          'active_canonical_predecessor_mismatch_rows':active_canonical_mismatch,
          'raw_payload_sha256':hash_text(raw_payload,'sha256'),
          'canonical_payload_sha256':hash_text(canonical_payload,'sha256'),
          'predecessor_canonical_payload_sha256':hash_text(predecessor_payload,'sha256'),
          'raw_payload_bytes':len(raw_payload.encode('utf-8')),
          'canonical_payload_bytes':len(canonical_payload.encode('utf-8')),
          'business_identity':table_business_identity(psql,conn,db,env,log,source,keys)}
    items=[{'code':code,**output[code]} for code in sorted(output)]
    return {'objects':output,'object_count':len(output),
      'total_source_rows':sum(x['source_rows'] for x in output.values()),
      'total_volatile_time_key_rows':sum(x['volatile_time_key_rows'] for x in output.values()),
      'business_bundle_sha256':hash_text(canon([{'code':x['code'],**x['business_identity']} for x in items]),'sha256'),
      'raw_payload_bundle_sha256':hash_text(canon([{'code':x['code'],'sha256':x['raw_payload_sha256']} for x in items]),'sha256'),
      'canonical_payload_bundle_sha256':hash_text(canon([{'code':x['code'],'sha256':x['canonical_payload_sha256']} for x in items]),'sha256')}


def r12_diagnostic_snapshot(psql,conn,db,env_ro,log):
    state_sql="""SELECT jsonb_build_object(
      'run_status',(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=1),
      'stage_registry_rows',(SELECT count(*) FROM msbf_m12r1e.wave_a_stage_registry),
      'validation_failures',(SELECT count(*) FROM msbf_m12r1e.wave_a_validation_result WHERE status='FAIL'),
      'm2_5_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_5'),
      'm2_6_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_6'),
      'm2_7_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_7'),
      'm2_8_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_8'),
      'm2_9_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_9'),
      'm2_9_successor_registry_rows',(SELECT count(*) FROM msbf_m12r1e.wave_a_stage_registry WHERE stage_code='M2.9'),
      'm2_9_legacy_registry_rows',(SELECT count(*) FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry),
      'm2_9_latest_rows',(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest),
      'm2_9_account_reconciliation_rows',(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot),
      'm2_9_total_absolute_variance',(SELECT coalesce(sum(abs(reconciliation_variance_amount))+sum(abs(exposure_variance_amount)),0)::text FROM msbf_m2.account_payment_reconciliation_snapshot),
      'm2_9_nonzero_variance_rows',(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE reconciliation_variance_amount<>0 OR exposure_variance_amount<>0),
      'm2_9_invalid_certification_rows',(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE active_state_flag::int+closed_state_flag::int+review_hold_state_flag::int<>1 OR NOT state_certified_flag OR certified_exposure_amount<0 OR reconciliation_variance_amount<>0 OR exposure_variance_amount<>0 OR unresolved_exception_count<0)
    )::text;"""
    state=json.loads(scalar(psql,conn,db,env_ro,log,state_sql))
    affected_sql="""SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x.scenario_id,x.merchant_application_id),'[]'::jsonb)::text
    FROM (
      SELECT r.module1_run_id,r.scenario_id,r.scenario_code,r.merchant_application_id,
       r.synthetic_account_id,r.synthetic_advance_id,
       r.source_exposure_amount::text source_exposure_amount,
       r.scheduled_payment_amount::text scheduled_payment_amount,
       r.processed_payment_amount::text processed_payment_amount,
       r.returned_payment_amount::text returned_payment_amount,
       r.retry_payment_amount::text retry_payment_amount,
       r.expected_net_processed_amount::text expected_net_processed_amount,
       r.reconciliation_variance_amount::text reconciliation_variance_amount,
       r.source_ending_exposure_amount::text source_ending_exposure_amount,
       r.expected_ending_exposure_amount::text expected_ending_exposure_amount,
       r.exposure_variance_amount::text exposure_variance_amount,
       c.reconciliation_outcome_code,c.certified_state_code,c.state_certified_flag,
       c.active_state_flag,c.closed_state_flag,c.review_hold_state_flag
      FROM msbf_m2.account_payment_reconciliation_snapshot r
      JOIN msbf_m2.application_payment_reconciliation_certification_latest c
        USING(module1_run_id,scenario_id,merchant_application_id)
      WHERE r.reconciliation_variance_amount<>0 OR r.exposure_variance_amount<>0
    ) x;"""
    affected=json.loads(scalar(psql,conn,db,env_ro,log,affected_sql))
    nullable_sql="""SELECT jsonb_build_object(
      'transition_hash_null_rows',(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE related_payment_event_row_hash IS NULL),
      'transition_hash_malformed_nonnull_rows',(SELECT count(*) FROM msbf_m2.lifecycle_certification_source_transition WHERE related_payment_event_row_hash IS NOT NULL AND related_payment_event_row_hash !~ '^[0-9a-f]{32}$'),
      'resolved_exception_hash_null_rows',(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE exception_status_code='RESOLVED_BY_RETRY' AND resolving_event_row_hash IS NULL),
      'resolved_exception_hash_malformed_rows',(SELECT count(*) FROM msbf_m2.payment_exception_case_snapshot WHERE resolving_event_row_hash IS NOT NULL AND resolving_event_row_hash !~ '^[0-9a-f]{32}$')
    )::text;"""
    nullable=json.loads(scalar(psql,conn,db,env_ro,log,nullable_sql))
    payload={'state':state,'affected_rows':affected,'nullable_hash_semantics':nullable}
    payload['diagnostic_fingerprint_sha256']=hash_text(canon(payload),'sha256')
    return payload


def validate_r12_diagnostic_snapshot(snapshot):
    expected_state={
      'run_status':'M2_9_GENERATED','stage_registry_rows':4,'validation_failures':0,
      'm2_5_status':'VALIDATED_CANDIDATE','m2_6_status':'VALIDATED_CANDIDATE',
      'm2_7_status':'VALIDATED_CANDIDATE','m2_8_status':'VALIDATED_CANDIDATE',
      'm2_9_status':'PENDING_REBASE','m2_9_successor_registry_rows':0,
      'm2_9_legacy_registry_rows':1,'m2_9_latest_rows':130,
      'm2_9_account_reconciliation_rows':130,'m2_9_total_absolute_variance':'0.02',
      'm2_9_nonzero_variance_rows':1,'m2_9_invalid_certification_rows':1
    }
    bad={k:{'expected':v,'actual':snapshot['state'].get(k)} for k,v in expected_state.items()
         if snapshot['state'].get(k)!=v}
    if bad:
        raise RuntimeError('R12 M2.9 diagnostic checkpoint mismatch: '+canon(bad))
    expected_affected={
      'scenario_code':'BASELINE','merchant_application_id':'MSBF_POP_0001_M000749_A01',
      'synthetic_account_id':'MSBF_ACCT_A481F369D0F0D8A976DB',
      'synthetic_advance_id':'MSBF_ADV_61A8900F4167686F0072',
      'source_exposure_amount':'4699.37','scheduled_payment_amount':'1762.25',
      'processed_payment_amount':'1762.26','returned_payment_amount':'251.75',
      'retry_payment_amount':'251.75','expected_net_processed_amount':'1762.25',
      'reconciliation_variance_amount':'0.01','source_ending_exposure_amount':'2937.11',
      'expected_ending_exposure_amount':'2937.12','exposure_variance_amount':'-0.01'
    }
    rows=snapshot['affected_rows']
    if len(rows)!=1:
        raise RuntimeError('R12 M2.9 affected population is not exactly one row')
    row=rows[0]
    affected_bad={k:{'expected':v,'actual':row.get(k)} for k,v in expected_affected.items()
                  if row.get(k)!=v}
    if affected_bad:
        raise RuntimeError('R12 M2.9 affected-row detail mismatch: '+canon(affected_bad))
    expected_nullable={'transition_hash_null_rows':131,'transition_hash_malformed_nonnull_rows':0,
      'resolved_exception_hash_null_rows':0,'resolved_exception_hash_malformed_rows':0}
    nullable_bad={k:{'expected':v,'actual':snapshot['nullable_hash_semantics'].get(k)}
      for k,v in expected_nullable.items() if snapshot['nullable_hash_semantics'].get(k)!=v}
    if nullable_bad:
        raise RuntimeError('R12 nullable-hash semantics mismatch: '+canon(nullable_bad))
    return True



def r13_diagnostic_snapshot(psql,conn,db,env_ro,log):
    state_sql="""SELECT jsonb_build_object(
      'run_status',(SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=1),
      'stage_registry_rows',(SELECT count(*) FROM msbf_m12r1e.wave_a_stage_registry),
      'validation_rows',(SELECT count(*) FROM msbf_m12r1e.wave_a_validation_result),
      'validation_failures',(SELECT count(*) FROM msbf_m12r1e.wave_a_validation_result WHERE status='FAIL'),
      'validated_stage_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10') AND rebase_status='VALIDATED_CANDIDATE'),
      'pending_stage_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code IN ('M2_11','M2_12') AND rebase_status='PENDING_REBASE'),
      'm2_9_total_absolute_variance',(SELECT coalesce(sum(abs(reconciliation_variance_amount))+sum(abs(exposure_variance_amount)),0)::text FROM msbf_m2.account_payment_reconciliation_snapshot),
      'm2_9_nonzero_variance_rows',(SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE reconciliation_variance_amount<>0 OR exposure_variance_amount<>0),
      'm2_9_invalid_certification_rows',(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE active_state_flag::int+closed_state_flag::int+review_hold_state_flag::int<>1 OR NOT state_certified_flag OR certified_exposure_amount<0 OR reconciliation_variance_amount<>0 OR exposure_variance_amount<>0 OR unresolved_exception_count<0),
      'retry_path_rows',(SELECT count(*) FROM msbf_m2.application_payment_reconciliation_certification_latest WHERE retry_event_count>0),
      'active_reconciled_retry_rows',(SELECT count(*) FROM msbf_m2.application_portfolio_performance_latest p JOIN msbf_m2.application_payment_reconciliation_certification_latest c USING(module1_run_id,scenario_id,merchant_application_id) WHERE c.retry_event_count>0 AND p.performance_tier_code='ACTIVE_RECONCILED' AND p.servicing_queue_code='ACTIVE_REASSESSMENT')
    )::text;"""
    state=json.loads(scalar(psql,conn,db,env_ro,log,state_sql))
    ids=','.join("'"+x.replace("'","''")+"'" for x in R13_ROUNDING_CONTROL_IDS)
    controls_raw=scalar(psql,conn,db,env_ro,log,
      "SELECT coalesce(jsonb_agg(jsonb_build_object('stage_code',stage_code,'control_id',control_id,'status',status,'observed',observed) ORDER BY stage_code,control_id),'[]'::jsonb)::text FROM msbf_m12r1e.wave_a_validation_result WHERE control_id IN ("+ids+");")
    controls=json.loads(controls_raw)
    view_contract=power_bi_view_contract_snapshot(psql,conn,db,env_ro,log)
    require_power_bi_view_contract(view_contract)
    export_preflight=export_query_preflight_all(psql,conn,db,env_ro,log,build_export_specs())
    export_identity=power_bi_export_identity(psql,conn,db,env_ro,log,view_contract)
    stable=stable_database_identity(psql,conn,db,env_ro,log)
    stable_rows=stable_database_rows(psql,conn,db,env_ro,log)
    source_payload_identity=source_payload_identity_snapshot(psql,conn,db,env_ro,log)
    payload={'state':state,'rounding_controls':controls,'power_bi_view_contract':view_contract,
             'export_preflight':export_preflight,'power_bi_export_identity':export_identity,
             'stable_database_identity':stable,'stable_database_rows':stable_rows,
             'source_payload_identity':source_payload_identity}
    payload['diagnostic_fingerprint_sha256']=hash_text(canon(payload),'sha256')
    return payload

def validate_r13_diagnostic_snapshot(snapshot):
    state=snapshot['state']
    expected={'run_status':'M2_10_GENERATED','stage_registry_rows':6,'validation_rows':103,
      'validation_failures':0,'validated_stage_rows':6,'pending_stage_rows':2,
      'm2_9_total_absolute_variance':'0.00','m2_9_nonzero_variance_rows':0,
      'm2_9_invalid_certification_rows':0,'retry_path_rows':1,'active_reconciled_retry_rows':1}
    bad={k:{'expected':v,'actual':state.get(k)} for k,v in expected.items() if state.get(k)!=v}
    observed={x['control_id']:x['status'] for x in snapshot['rounding_controls']}
    if observed!={cid:'PASS' for cid in R13_ROUNDING_CONTROL_IDS}:
        bad['rounding_controls']={'expected':{cid:'PASS' for cid in R13_ROUNDING_CONTROL_IDS},'actual':observed}
    if snapshot['power_bi_export_identity'].get('object_count')!=6:
        bad['power_bi_export_identity']={'expected_objects':6,'actual':snapshot['power_bi_export_identity'].get('object_count')}
    if bad: raise RuntimeError('Retained R13 compiler diagnostic mismatch: '+canon(bad))
    return True

def validate_successful_wave_diagnostic_snapshot(snapshot,label):
    validate_r13_diagnostic_snapshot(snapshot)
    payload=snapshot.get('source_payload_identity',{})
    if payload.get('object_count')!=6 or payload.get('total_source_rows')!=665:
        raise RuntimeError(label+' source-payload diagnostic population mismatch: '+canon(payload))
    rows=snapshot.get('stable_database_rows',{})
    if len(rows.get('stage_registry',[]))!=6 or len(rows.get('validation',[]))!=103 or len(rows.get('downstream',[]))!=9:
        raise RuntimeError(label+' stable database row population mismatch')
    return True



def r16_diagnostic_snapshot(psql,conn,db,env_ro,log):
    snapshot=r13_diagnostic_snapshot(psql,conn,db,env_ro,log)
    snapshot.pop('diagnostic_fingerprint_sha256',None)
    ids=','.join("'"+x.replace("'","''")+"'" for x in R15_SOURCE_PAYLOAD_CONTROL_IDS)
    controls_raw=scalar(psql,conn,db,env_ro,log,
      "SELECT coalesce(jsonb_agg(jsonb_build_object('stage_code',stage_code,'control_id',control_id,'status',status,'observed',observed) ORDER BY stage_code,control_id),'[]'::jsonb)::text FROM msbf_m12r1e.wave_a_validation_result WHERE control_id IN ("+ids+");")
    snapshot['source_payload_controls']=json.loads(controls_raw)
    snapshot['diagnostic_fingerprint_sha256']=hash_text(canon(snapshot),'sha256')
    return snapshot


def validate_canonicalized_wave_diagnostic_snapshot(snapshot,label):
    state=snapshot['state']
    expected={'run_status':'M2_10_GENERATED','stage_registry_rows':6,'validation_rows':115,
      'validation_failures':0,'validated_stage_rows':6,'pending_stage_rows':2,
      'm2_9_total_absolute_variance':'0.00','m2_9_nonzero_variance_rows':0,
      'm2_9_invalid_certification_rows':0,'retry_path_rows':1,'active_reconciled_retry_rows':1}
    bad={k:{'expected':v,'actual':state.get(k)} for k,v in expected.items() if state.get(k)!=v}
    rounding={x['control_id']:x['status'] for x in snapshot.get('rounding_controls',[])}
    if rounding!={cid:'PASS' for cid in R13_ROUNDING_CONTROL_IDS}:
        bad['rounding_controls']={'expected':{cid:'PASS' for cid in R13_ROUNDING_CONTROL_IDS},'actual':rounding}
    payload_controls={x['control_id']:x['status'] for x in snapshot.get('source_payload_controls',[])}
    if payload_controls!={cid:'PASS' for cid in R15_SOURCE_PAYLOAD_CONTROL_IDS}:
        bad['source_payload_controls']={'expected':{cid:'PASS' for cid in R15_SOURCE_PAYLOAD_CONTROL_IDS},'actual':payload_controls}
    payload=snapshot.get('source_payload_identity',{})
    if (payload.get('object_count')!=6 or payload.get('total_source_rows')!=665 or
        payload.get('total_volatile_time_key_rows')!=0 or
        payload.get('raw_payload_bundle_sha256')!=payload.get('canonical_payload_bundle_sha256')):
        bad['source_payload_identity']=payload
    rows=snapshot.get('stable_database_rows',{})
    if len(rows.get('stage_registry',[]))!=6 or len(rows.get('validation',[]))!=115 or len(rows.get('downstream',[]))!=9:
        bad['stable_database_rows']={'stage_registry':len(rows.get('stage_registry',[])),
          'validation':len(rows.get('validation',[])),'downstream':len(rows.get('downstream',[]))}
    expected_preflight=R17_SUCCESSOR_PREFLIGHT_ROWS
    actual_preflight={x.get('name'):x.get('rows') for x in snapshot.get('export_preflight',[])}
    if actual_preflight!=expected_preflight: bad['export_preflight_rows']={'expected':expected_preflight,'actual':actual_preflight}
    if snapshot.get('power_bi_export_identity',{}).get('object_count')!=6:
        bad['power_bi_export_identity']=snapshot.get('power_bi_export_identity')
    if bad: raise RuntimeError(label+' canonicalized-wave diagnostic mismatch: '+canon(bad))
    return True


def compare_r16_result_to_physical(r16_evidence,physical_snapshot):
    pairs=[
      ('stable_database_rows',r16_evidence['compiler_stable_database_rows'],physical_snapshot['stable_database_rows']),
      ('stable_database_identity',r16_evidence['compiler_database_identity'],physical_snapshot['stable_database_identity']),
      ('power_bi_view_contract',r16_evidence['compiler_power_bi_view_contract'],physical_snapshot['power_bi_view_contract']),
      ('export_preflight',r16_evidence['compiler_export_preflight'],physical_snapshot['export_preflight']),
      ('power_bi_export_identity',r16_evidence['compiler_power_bi_export_identity'],physical_snapshot['power_bi_export_identity']),
      ('source_payload_identity',r16_evidence['compiler_source_payload_identity'],physical_snapshot['source_payload_identity'])]
    failures=[name for name,a,b in pairs if a!=b]
    if failures: raise RuntimeError('Physical R16 diagnostic differs from exact R16 result evidence: '+canon(failures))
    return {'status':'PASS','exact_components':[x[0] for x in pairs],
      'database_identity':physical_snapshot['stable_database_identity'],
      'power_bi_bundle_sha256':physical_snapshot['power_bi_export_identity']['bundle_sha256'],
      'source_payload_bundle_sha256':physical_snapshot['source_payload_identity']['raw_payload_bundle_sha256']}

def compare_r13_r14_diagnostics(r13_snapshot,r14_snapshot):
    validate_successful_wave_diagnostic_snapshot(r13_snapshot,'R13')
    validate_successful_wave_diagnostic_snapshot(r14_snapshot,'R14')
    if r13_snapshot['power_bi_export_identity']!=r14_snapshot['power_bi_export_identity']:
        raise RuntimeError('R13/R14 curated Power BI identity differs')
    if r13_snapshot['power_bi_view_contract']!=r14_snapshot['power_bi_view_contract']:
        raise RuntimeError('R13/R14 Power BI view contract differs')
    if r13_snapshot['export_preflight']!=r14_snapshot['export_preflight']:
        raise RuntimeError('R13/R14 export preflight differs')
    r13_rows=r13_snapshot['stable_database_rows'];r14_rows=r14_snapshot['stable_database_rows']
    r13_stage={x['stage_code']:x for x in r13_rows['stage_registry']}
    r14_stage={x['stage_code']:x for x in r14_rows['stage_registry']}
    if set(r13_stage)!=set(r14_stage): raise RuntimeError('R13/R14 stage-registry domain differs')
    if r13_stage['M2.5']!=r14_stage['M2.5'] or r13_stage['M2.6']!=r14_stage['M2.6']:
        raise RuntimeError('R13/R14 identity diverges before M2.7')

    a=r13_stage['M2.7'];b=r14_stage['M2.7']
    must_match=list(M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT['must_match'])
    must_differ=list(M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT['must_differ'])
    expected_domain=set(must_match)|set(must_differ)
    domain_observed={'r13':sorted(a),'r14':sorted(b),'expected':sorted(expected_domain)}
    if set(a)!=expected_domain or set(b)!=expected_domain:
        raise RuntimeError('R13/R14 M2.7 comparator field domain mismatch: '+canon(domain_observed))
    match_failures={k:{'r13':a.get(k),'r14':b.get(k)} for k in must_match if a.get(k)!=b.get(k)}
    if match_failures:
        raise RuntimeError('R13/R14 M2.7 must-match fields unexpectedly differ: '+canon(match_failures))
    differ_failures={k:{'r13':a.get(k),'r14':b.get(k)} for k in must_differ if a.get(k)==b.get(k)}
    if differ_failures:
        raise RuntimeError('R13/R14 M2.7 must-differ fields unexpectedly match: '+canon(differ_failures))
    actual_diffs=sorted(k for k in a if a.get(k)!=b.get(k))
    if actual_diffs!=sorted(must_differ):
        raise RuntimeError('R13/R14 M2.7 first-divergence field set mismatch: '+canon(actual_diffs))
    if a['legacy_policy_configuration_hash']!=b['legacy_policy_configuration_hash']:
        raise RuntimeError('R13/R14 M2.7 legacy policy configuration hash unexpectedly differs')
    if a['legacy_policy_configuration_hash']!=R16_M2_7_LEGACY_POLICY_CONFIGURATION_HASH:
        raise RuntimeError('R13/R14 M2.7 legacy policy configuration hash exact value mismatch')

    if r13_rows['downstream']!=r14_rows['downstream']:
        raise RuntimeError('R13/R14 downstream status rows differ')
    r13_val={(x['stage_code'],x['control_id']):x for x in r13_rows['validation']}
    r14_val={(x['stage_code'],x['control_id']):x for x in r14_rows['validation']}
    if set(r13_val)!=set(r14_val): raise RuntimeError('R13/R14 validation control domain differs')
    if any(x['status']!='PASS' for x in r13_val.values()) or any(x['status']!='PASS' for x in r14_val.values()):
        raise RuntimeError('R13/R14 diagnostic contains a non-PASS control')
    validation_diffs=[]
    for key in sorted(r13_val):
        if r13_val[key]!=r14_val[key]: validation_diffs.append({'stage':key[0],'control_id':key[1],
          'r13_observed':r13_val[key]['observed'],'r14_observed':r14_val[key]['observed']})
    expected_validation_diff_keys={('M2.8','SOURCE_HASH_LINEAGE'),('M2.9','SOURCE_HASH_LINEAGE'),('M2.10','SOURCE_HASH_LINEAGE')}
    if {(x['stage'],x['control_id']) for x in validation_diffs}!=expected_validation_diff_keys:
        raise RuntimeError('R13/R14 validation difference class mismatch: '+canon(validation_diffs))
    r13_payload=r13_snapshot['source_payload_identity'];r14_payload=r14_snapshot['source_payload_identity']
    business_diffs=[]
    for code in sorted(SOURCE_PAYLOAD_SPECS):
        left=r13_payload['objects'][code];right=r14_payload['objects'][code]
        if left['business_identity']!=right['business_identity']: business_diffs.append(code)
    if business_diffs: raise RuntimeError('R13/R14 source business projections differ: '+canon(business_diffs))
    a27=r13_payload['objects']['M2.7'];b27=r14_payload['objects']['M2.7']
    if a27['raw_payload_sha256']==b27['raw_payload_sha256']:
        raise RuntimeError('R13/R14 M2.7 raw source payload unexpectedly matches')
    if a27['canonical_payload_sha256']!=b27['canonical_payload_sha256']:
        raise RuntimeError('R13/R14 M2.7 canonical source payload differs after timestamp exclusion')
    for label,obj in [('R13',a27),('R14',b27)]:
        if obj['source_rows']!=130 or obj['created_at_key_rows']!=130 or obj['volatile_time_key_rows']!=130:
            raise RuntimeError(label+' M2.7 volatile source-payload population is not exactly 130')
        if obj['raw_predecessor_mismatch_rows']!=0 or obj['canonical_predecessor_mismatch_rows']!=0 or obj['active_canonical_predecessor_mismatch_rows']!=130:
            raise RuntimeError(label+' M2.7 predecessor-payload relationship is not exact: '+canon(obj))
    stage_diffs={}
    for stage in sorted(r13_stage):
        stage_diffs[stage]=sorted(k for k in r13_stage[stage] if r13_stage[stage].get(k)!=r14_stage[stage].get(k))
    comparator_controls=[
      {'control_id':'R16_R13_R14_M2_7_FIELD_DOMAIN_EXACT','status':'PASS','observed':domain_observed},
      {'control_id':'R16_R13_R14_M2_7_MUST_MATCH_FIELDS_EXACT','status':'PASS','observed':must_match},
      {'control_id':'R16_R13_R14_M2_7_MUST_DIFFER_FIELDS_EXACT','status':'PASS','observed':must_differ},
      {'control_id':'R16_R13_R14_M2_7_LEGACY_POLICY_HASH_STABLE','status':'PASS',
       'observed':a['legacy_policy_configuration_hash']}
    ]
    return {
      'status':'PASS','failure_class':'RUN_GENERATED_CREATED_AT_EMBEDDED_IN_NESTED_SOURCE_PAYLOAD',
      'r16_comparator_correction_class':'OVER_SPECIFIED_FIRST_DIVERGENCE_FIELD_SET',
      'first_divergent_stage':'M2.7','first_divergent_source_rows':130,
      'm2_7_transformed_sql_match':True,'m2_7_raw_payload_identity_match':False,
      'm2_7_canonical_payload_identity_match':True,'curated_power_bi_identity_match':True,
      'source_business_identity_match':True,'downstream_status_identity_match':True,
      'm2_7_comparator_field_contract':M2_7_FIRST_DIVERGENCE_FIELD_CONTRACT,
      'm2_7_actual_different_fields':actual_diffs,'diagnostic_comparator_controls':comparator_controls,
      'stage_field_differences':stage_diffs,'validation_observed_differences':validation_diffs,
      'r13_database_identity':r13_snapshot['stable_database_identity'],
      'r14_database_identity':r14_snapshot['stable_database_identity'],
      'r13_power_bi_bundle_sha256':r13_snapshot['power_bi_export_identity']['bundle_sha256'],
      'r14_power_bi_bundle_sha256':r14_snapshot['power_bi_export_identity']['bundle_sha256'],
      'r13_business_bundle_sha256':r13_payload['business_bundle_sha256'],
      'r14_business_bundle_sha256':r14_payload['business_bundle_sha256']}



def r13_rounding_recurrence_controls(psql,conn,db,env,log,stage):
    checks=[]
    if stage=='8':
        retry_rows=int(scalar(psql,conn,db,env,log,
          "SELECT count(*) FROM msbf_m2.synthetic_payment_processing_event WHERE payment_status_code='SIMULATED_RETRY_SETTLED';"))
        checks.append(check_row(stage,'R13_KNOWN_RETRY_EVENT_POPULATION',retry_rows==1,retry_rows))
        retry_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*)
          FROM msbf_m2.synthetic_payment_processing_event
          WHERE payment_status_code='SIMULATED_RETRY_SETTLED'
            AND processed_payment_amount<>round(scheduled_payment_amount+retry_payment_amount,2);"""))
        checks.append(check_row(stage,'R13_RETRY_EVENT_CENT_ROUNDING_ALIGNMENT',retry_mismatch==0,retry_mismatch))
        ledger_mismatch=int(scalar(psql,conn,db,env,log,"""WITH e AS(
          SELECT module1_run_id,scenario_id,merchant_application_id,
           round(sum(scheduled_payment_amount),2) scheduled,
           round(sum(processed_payment_amount),2) processed,
           round(sum(returned_payment_amount),2) returned,
           round(sum(retry_payment_amount),2) retry
          FROM msbf_m2.synthetic_payment_processing_event GROUP BY 1,2,3)
          SELECT count(*) FROM msbf_m2.application_servicing_execution_latest l
          JOIN e USING(module1_run_id,scenario_id,merchant_application_id)
          WHERE l.processing_authorized_flag AND (
            e.processed<>round(e.scheduled-e.returned+e.retry,2)
            OR l.scheduled_payment_amount<>e.scheduled
            OR l.processed_payment_amount<>e.processed
            OR l.returned_payment_amount<>e.returned
            OR l.retry_payment_amount<>e.retry
            OR l.ending_simulated_exposure_amount<>greatest(l.source_exposure_amount-e.processed,0)
          );"""))
        checks.append(check_row(stage,'R13_M2_8_ACCOUNT_LEDGER_EXACT_RECONCILIATION',ledger_mismatch==0,ledger_mismatch))
    elif stage=='9':
        variance_rows=int(scalar(psql,conn,db,env,log,"SELECT count(*) FROM msbf_m2.account_payment_reconciliation_snapshot WHERE reconciliation_variance_amount<>0 OR exposure_variance_amount<>0;"))
        checks.append(check_row(stage,'R13_M2_9_ZERO_VARIANCE_ROW_POPULATION',variance_rows==0,variance_rows))
        retry_cert_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*)
          FROM msbf_m2.application_payment_reconciliation_certification_latest c
          WHERE c.retry_event_count>0 AND NOT (
            c.reconciliation_outcome_code='PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY'
            AND c.certified_state_code='CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY'
            AND c.state_certified_flag AND c.active_state_flag
            AND NOT c.closed_state_flag AND NOT c.review_hold_state_flag
            AND c.exception_resolved_flag AND c.unresolved_exception_count=0
            AND c.processed_payment_amount=c.scheduled_payment_amount
            AND c.returned_payment_amount=c.retry_payment_amount
            AND c.reconciliation_variance_amount=0 AND c.exposure_variance_amount=0
          );"""))
        checks.append(check_row(stage,'R13_M2_9_RETRY_PATH_CERTIFIED_ACTIVE',retry_cert_mismatch==0,retry_cert_mismatch))
    elif stage=='10':
        retry_mapping_mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*)
          FROM msbf_m2.application_payment_reconciliation_certification_latest c
          JOIN msbf_m2.application_portfolio_performance_latest p
            USING(module1_run_id,scenario_id,merchant_application_id)
          WHERE c.retry_event_count>0 AND NOT (
            p.performance_tier_code='ACTIVE_RECONCILED'
            AND p.servicing_queue_code='ACTIVE_REASSESSMENT'
            AND p.primary_portfolio_reason_code='M2_10_REASON_ACTIVE_RECONCILED'
            AND p.state_certified_flag AND p.exception_resolved_flag
            AND p.processed_payment_amount=p.scheduled_payment_amount
            AND p.returned_payment_amount=p.retry_payment_amount
            AND p.reconciliation_variance_amount=0 AND p.exposure_variance_amount=0
          );"""))
        checks.append(check_row(stage,'R13_M2_10_RETRY_PATH_ACTIVE_RECONCILED',retry_mapping_mismatch==0,retry_mapping_mismatch))
    return checks

def source_payload_object_controls(psql,conn,db,env,log,stage,code,control_prefix):
    spec=SOURCE_PAYLOAD_SPECS[code]
    source=spec['source_table'];predecessor=spec['predecessor_table'];keys=spec['keys']
    join=' AND '.join('s.'+qident(k)+'=p.'+qident(k) for k in keys)
    volatile=int(scalar(psql,conn,db,env,log,
      'SELECT count(*) FROM '+source+' WHERE source_payload ?| ARRAY['+
      ','.join("'"+k.replace("'","''")+"'" for k in VOLATILE_PAYLOAD_KEYS)+'];'))
    mismatch=int(scalar(psql,conn,db,env,log,
      'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+
      " WHERE s.source_payload IS DISTINCT FROM (to_jsonb(p)-'created_at');"))
    source_rows=int(scalar(psql,conn,db,env,log,'SELECT count(*) FROM '+source+';'))
    predecessor_rows=int(scalar(psql,conn,db,env,log,'SELECT count(*) FROM '+predecessor+';'))
    joined_rows=int(scalar(psql,conn,db,env,log,
      'SELECT count(*) FROM '+source+' s JOIN '+predecessor+' p ON '+join+';'))
    complete=(source_rows==predecessor_rows==joined_rows)
    return [
      check_row(stage,control_prefix+'_VOLATILE_TIME_KEYS_ABSENT',volatile==0,
        {'volatile_rows':volatile,'source_rows':source_rows,'volatile_keys':VOLATILE_PAYLOAD_KEYS}),
      check_row(stage,control_prefix+'_PREDECESSOR_EXACT',mismatch==0 and complete,
        {'mismatch_rows':mismatch,'source_rows':source_rows,'predecessor_rows':predecessor_rows,
         'joined_rows':joined_rows})]


def r15_source_payload_controls(psql,conn,db,env,log,stage):
    checks=[]
    if stage=='7':
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.7','R15_M2_7_SOURCE_PAYLOAD'))
    elif stage=='8':
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.8','R15_M2_8_SOURCE_PAYLOAD'))
    elif stage=='9':
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.9_ACCOUNT','R15_M2_9_ACCOUNT_SOURCE_PAYLOAD'))
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.9_PAYMENT','R15_M2_9_PAYMENT_SOURCE_PAYLOAD'))
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.9_TRANSITION','R15_M2_9_TRANSITION_SOURCE_PAYLOAD'))
    elif stage=='10':
        checks.extend(source_payload_object_controls(psql,conn,db,env,log,stage,'M2.10','R15_M2_10_SOURCE_PAYLOAD'))
    return checks


def comparison_view_column_contract(psql,conn,db,env,log,stage):
    if stage not in strategy.VIEW_COLUMN_CONTRACT:
        return {'status':'NOT_APPLICABLE','expected_columns':[],'actual_columns':[]}
    schema_name,object_name=strategy.STAGE_ALIGNMENT[stage]['comparison_view'].split('.',1)
    sql=f"SELECT column_name FROM information_schema.columns WHERE table_schema='{schema_name}' AND table_name='{object_name}' ORDER BY ordinal_position;"
    cp=run([psql,*conn,'-d',db,'-X','-At','-v','ON_ERROR_STOP=1','-c',sql],env,log)
    actual=[x.strip() for x in cp.stdout.splitlines() if x.strip()]
    expected=strategy.VIEW_COLUMN_CONTRACT[stage]
    return {'status':'PASS' if actual==expected else 'FAIL','expected_columns':expected,'actual_columns':actual}

def r9_terminal_state_comparison_controls(psql,conn,db,env,log,stage):
    checks=[]
    if stage=='5':
        mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.v_m2_5_matched_monitoring_comparison v
          WHERE v.stress_status_improvement_flag IS DISTINCT FROM
            (NOT v.baseline_paid_off_flag AND NOT v.stress_paid_off_flag
             AND v.stress_monitoring_status_rank<v.baseline_monitoring_status_rank);"""))
        checks.append(check_row(stage,'R9_M2_5_ACCEPTED_TERMINAL_REFERENCE_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
    elif stage=='6':
        mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.v_m2_6_matched_scenario_comparison v
          JOIN msbf_m2.advance_intervention_source_snapshot b ON b.module1_run_id=v.module1_run_id AND b.merchant_application_id=v.merchant_application_id AND b.scenario_code='BASELINE'
          JOIN msbf_m2.advance_intervention_source_snapshot s ON s.module1_run_id=v.module1_run_id AND s.merchant_application_id=v.merchant_application_id AND s.scenario_code='RECESSION_ENERGY'
          WHERE v.stress_strategy_improvement_flag IS DISTINCT FROM
             (NOT b.paid_off_flag AND NOT s.paid_off_flag AND v.stress_strategy_outcome_rank<v.baseline_strategy_outcome_rank)
             OR v.stress_action_improvement_flag IS DISTINCT FROM
             (NOT b.paid_off_flag AND NOT s.paid_off_flag AND v.stress_servicing_priority_rank<v.baseline_servicing_priority_rank);"""))
        summary=json.loads(scalar(psql,conn,db,env,log,"""SELECT jsonb_build_object(
          'terminal_pairs',count(*) FILTER(WHERE b.paid_off_flag OR s.paid_off_flag),
          'terminal_raw_strategy_decreases',count(*) FILTER(WHERE (b.paid_off_flag OR s.paid_off_flag) AND v.stress_strategy_outcome_rank<v.baseline_strategy_outcome_rank),
          'terminal_raw_action_decreases',count(*) FILTER(WHERE (b.paid_off_flag OR s.paid_off_flag) AND v.stress_servicing_priority_rank<v.baseline_servicing_priority_rank),
          'adverse_strategy_improvements',count(*) FILTER(WHERE NOT b.paid_off_flag AND NOT s.paid_off_flag AND v.stress_strategy_outcome_rank<v.baseline_strategy_outcome_rank),
          'adverse_action_improvements',count(*) FILTER(WHERE NOT b.paid_off_flag AND NOT s.paid_off_flag AND v.stress_servicing_priority_rank<v.baseline_servicing_priority_rank))::text
          FROM msbf_m2.v_m2_6_matched_scenario_comparison v
          JOIN msbf_m2.advance_intervention_source_snapshot b ON b.module1_run_id=v.module1_run_id AND b.merchant_application_id=v.merchant_application_id AND b.scenario_code='BASELINE'
          JOIN msbf_m2.advance_intervention_source_snapshot s ON s.module1_run_id=v.module1_run_id AND s.merchant_application_id=v.merchant_application_id AND s.scenario_code='RECESSION_ENERGY';"""))
        checks.append(check_row(stage,'R9_M2_6_TERMINAL_COMPARISON_FORMULA_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
        checks.append(check_row(stage,'R9_M2_6_ADVERSE_ONLY_NONIMPROVEMENT',summary['adverse_strategy_improvements']==0 and summary['adverse_action_improvements']==0,summary))
    elif stage=='7':
        mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.v_m2_7_matched_scenario_comparison v
          JOIN msbf_m2.application_operational_activation_latest b ON b.module1_run_id=v.module1_run_id AND b.merchant_application_id=v.merchant_application_id AND b.scenario_code='BASELINE'
          JOIN msbf_m2.application_operational_activation_latest s ON s.module1_run_id=v.module1_run_id AND s.merchant_application_id=v.merchant_application_id AND s.scenario_code='RECESSION_ENERGY'
          WHERE v.stress_setup_permission_improvement_flag IS DISTINCT FROM
             (NOT b.no_setup_required_flag AND NOT s.no_setup_required_flag AND s.setup_authorized_flag AND NOT b.setup_authorized_flag)
             OR v.stress_priority_improvement_flag IS DISTINCT FROM
             (NOT b.no_setup_required_flag AND NOT s.no_setup_required_flag AND s.operational_setup_priority_rank<b.operational_setup_priority_rank);"""))
        checks.append(check_row(stage,'R9_M2_7_TERMINAL_COMPARISON_FORMULA_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
    elif stage=='8':
        mismatch=int(scalar(psql,conn,db,env,log,"""WITH p AS(
          SELECT module1_run_id,merchant_application_id,
           bool_or(no_processing_required_flag) FILTER(WHERE scenario_code='BASELINE') bterm,
           bool_or(no_processing_required_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') sterm,
           bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='BASELINE') bauth,
           bool_or(processing_authorized_flag) FILTER(WHERE scenario_code='RECESSION_ENERGY') sauth,
           max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='BASELINE') brank,
           max(servicing_execution_priority_rank) FILTER(WHERE scenario_code='RECESSION_ENERGY') srank,
           max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='BASELINE') bexp,
           max(ending_simulated_exposure_amount) FILTER(WHERE scenario_code='RECESSION_ENERGY') sexp
          FROM msbf_m2.application_servicing_execution_latest GROUP BY 1,2)
          SELECT count(*) FROM p JOIN msbf_m2.v_m2_8_matched_scenario_comparison v USING(module1_run_id,merchant_application_id)
          WHERE v.stress_processing_permission_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND sauth AND NOT bauth)
             OR v.stress_priority_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND srank<brank)
             OR v.stress_exposure_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND sexp<bexp);"""))
        checks.append(check_row(stage,'R9_M2_8_TERMINAL_COMPARISON_FORMULA_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
    elif stage=='9':
        mismatch=int(scalar(psql,conn,db,env,log,"""WITH p AS(
          SELECT l.module1_run_id,l.merchant_application_id,
           bool_or(l.closed_state_flag) FILTER(WHERE l.scenario_code='BASELINE') bterm,
           bool_or(l.closed_state_flag) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') sterm,
           bool_or(l.state_certified_flag) FILTER(WHERE l.scenario_code='BASELINE') bcert,
           bool_or(l.state_certified_flag) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') scert,
           max(d.certification_state_rank) FILTER(WHERE l.scenario_code='BASELINE') brank,
           max(d.certification_state_rank) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') srank,
           max(l.certified_exposure_amount) FILTER(WHERE l.scenario_code='BASELINE') bexp,
           max(l.certified_exposure_amount) FILTER(WHERE l.scenario_code='RECESSION_ENERGY') sexp
          FROM msbf_m2.application_payment_reconciliation_certification_latest l
          JOIN msbf_m2.account_state_certification_definition d ON d.module1_run_id=l.module1_run_id AND d.certification_state_code=l.certified_state_code GROUP BY 1,2)
          SELECT count(*) FROM p JOIN msbf_m2.v_m2_9_matched_scenario_comparison v USING(module1_run_id,merchant_application_id)
          WHERE v.stress_certification_permission_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND scert AND NOT bcert)
             OR v.stress_certification_rank_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND srank<brank)
             OR v.stress_exposure_improvement_flag IS DISTINCT FROM (NOT bterm AND NOT sterm AND sexp<bexp);"""))
        checks.append(check_row(stage,'R9_M2_9_TERMINAL_COMPARISON_FORMULA_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
    elif stage=='10':
        mismatch=int(scalar(psql,conn,db,env,log,"""SELECT count(*) FROM msbf_m2.v_m2_10_matched_scenario_comparison v
          WHERE v.stress_tier_improvement_flag IS DISTINCT FROM
             (v.baseline_performance_tier_code<>'CLOSED_STABLE' AND v.stress_performance_tier_code<>'CLOSED_STABLE' AND v.stress_performance_tier_rank<v.baseline_performance_tier_rank)
             OR v.stress_burden_improvement_flag IS DISTINCT FROM
             (v.baseline_performance_tier_code<>'CLOSED_STABLE' AND v.stress_performance_tier_code<>'CLOSED_STABLE' AND v.stress_servicing_burden_units<v.baseline_servicing_burden_units)
             OR v.stress_exposure_improvement_flag IS DISTINCT FROM
             (v.baseline_performance_tier_code<>'CLOSED_STABLE' AND v.stress_performance_tier_code<>'CLOSED_STABLE' AND v.stress_certified_exposure_amount<v.baseline_certified_exposure_amount);"""))
        checks.append(check_row(stage,'R9_M2_10_TERMINAL_COMPARISON_FORMULA_ALIGNED',mismatch==0,{'mismatch_rows':mismatch}))
    return checks

def stable_database_identity(psql,conn,db,env,log):
    stage_rows=run([psql,*conn,'-d',db,'-X','--csv','-v','ON_ERROR_STOP=1','-c',
      """SELECT stage_code,predecessor_stage_code,accepted_predecessor_combined_hash,
         accepted_output_combined_hash,successor_contract_hash,successor_contract_sha256,
         successor_evidence_hash,successor_evidence_sha256,accepted_schema_source_sha256,
         accepted_generation_source_sha256,transformed_schema_sha256,
         transformed_generation_sha256,policy_method_hash,legacy_policy_configuration_hash,
         contract_table_set_sha256,source_rows,baseline_rows,stress_rows,
         actual_population_payload,legacy_registry_status,validation_status
         FROM msbf_m12r1e.wave_a_stage_registry ORDER BY stage_code;"""],env,log).stdout
    validation_rows=run([psql,*conn,'-d',db,'-X','--csv','-v','ON_ERROR_STOP=1','-c',
      """SELECT stage_code,control_id,status,observed
         FROM msbf_m12r1e.wave_a_validation_result ORDER BY stage_code,control_id;"""],env,log).stdout
    downstream_rows=run([psql,*conn,'-d',db,'-X','--csv','-v','ON_ERROR_STOP=1','-c',
      """SELECT stage_code,rebase_status
         FROM msbf_m12r1e.downstream_rebase_status
         WHERE stage_code IN ('M2_4','M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12')
         ORDER BY stage_code;"""],env,log).stdout
    return {
        'stage_registry_sha256':hash_text(stage_rows.replace('\\r\\n','\\n'),'sha256'),
        'validation_sha256':hash_text(validation_rows.replace('\\r\\n','\\n'),'sha256'),
        'downstream_status_sha256':hash_text(downstream_rows.replace('\\r\\n','\\n'),'sha256'),
        'stage_registry_rows':max(0,len(stage_rows.splitlines())-1),
        'validation_rows':max(0,len(validation_rows.splitlines())-1),
        'downstream_status_rows':max(0,len(downstream_rows.splitlines())-1)
    }

def execute_wave(psql,conn,db,env,log,mode,out,transformed_root,initial_prior,compiler_receipts=None,prepared=False):
    if not prepared:
        setup_wave_database(psql,conn,db,env,log)
    base=clone_base_control(psql,conn,db,env,log)
    validate_clone_base(base)
    (out/'00_CLONE_BASE_CONTROL.json').write_text(json.dumps(base,indent=2),encoding='utf-8')

    prior=initial_prior
    all_checks=[]
    stage_receipts=[]

    for stage in STAGES:
        m=META[stage]
        compiler_stage=None
        if compiler_receipts:
            compiler_stage=next(x for x in compiler_receipts if x['stage']==m['stage'])
        if compiler_stage and prior!=compiler_stage['accepted_predecessor_combined_hash']:
            raise RuntimeError(
                f"Final predecessor hash differs from compiler for {m['stage']}: "
                f"{prior} != {compiler_stage['accepted_predecessor_combined_hash']}"
            )

        trans,srcs=compile_transformed(stage,prior,transformed_root,mode,compiler_stage)

        run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-f',str(trans['SCHEMA'])],env,log)
        phys=physical_semantics_validate(psql,conn,db,env,log,m['stage'])
        support=core.support_semantics_validate(psql,conn,db,env,log,m['stage'])
        keys=core.key_semantics_validate(psql,conn,db,env,log,m['stage'])
        fks=core.foreign_key_semantics_validate(psql,conn,db,env,log,m['stage'])
        named=core.named_constraint_validate(psql,conn,db,env,log,m['stage'])
        view_contract=comparison_view_column_contract(psql,conn,db,env,log,stage)
        schema_detail={
            'column_semantics_failures':phys,
            'support_objects':support,
            'keys':keys,
            'foreign_keys':fks,
            'named_constraints':named,
            'comparison_view_column_contract':view_contract
        }
        (out/f"{m['stage'].replace('.','_')}_PHYSICAL_SCHEMA_VALIDATION.json").write_text(
            json.dumps(schema_detail,indent=2),encoding='utf-8'
        )
        schema_fail=len(phys)+sum(x['status']!='PASS' for x in support+keys+fks+named)+(1 if view_contract['status']=='FAIL' else 0)
        if schema_fail:
            raise RuntimeError(f"{m['stage']} physical schema validation failed for {schema_fail} controls")

        run([psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-f',str(trans['GEN'])],env,log)

        base_ok,checks,detail=core.validate_stage(psql,conn,db,env,log,stage,m,prior)
        successor_checks=r9_terminal_state_comparison_controls(psql,conn,db,env,log,stage)
        checks.extend(successor_checks)
        detail['r9_terminal_state_comparison_controls']=successor_checks
        r13_checks=r13_rounding_recurrence_controls(psql,conn,db,env,log,stage)
        checks.extend(r13_checks)
        detail['r13_rounding_recurrence_controls']=r13_checks
        r15_checks=r15_source_payload_controls(psql,conn,db,env,log,stage)
        checks.extend(r15_checks)
        detail['r15_source_payload_canonicalization_controls']=r15_checks
        stage_ok=(base_ok and all(x['status']=='PASS' for x in successor_checks)
                  and all(x['status']=='PASS' for x in r13_checks)
                  and all(x['status']=='PASS' for x in r15_checks))

        all_checks.extend(checks)
        (out/f"{m['stage'].replace('.','_')}_VALIDATION_DETAIL.json").write_text(
            json.dumps(detail,indent=2),encoding='utf-8'
        )
        if not stage_ok:
            raise RuntimeError(f"{m['stage']} successor checkpoint validation failed")

        legacy=core.legacy_registry_observation(psql,conn,db,env,log,m)
        if not legacy:
            raise RuntimeError(f"{m['stage']} legacy registry row missing")
        legacy_hash=legacy.get('combined_set_hash')
        legacy_status=legacy.get('contract_status')
        if legacy_status!='GENERATED':
            raise RuntimeError(f"{m['stage']} legacy registry status {legacy_status} != GENERATED")
        if not re.fullmatch(r'[0-9a-f]{32}',str(legacy_hash or '')):
            raise RuntimeError(f"{m['stage']} invalid accepted output combined hash {legacy_hash}")

        all_summary=core.table_set_summary(psql,conn,db,env,log,m['tables'])
        contract_tables=[t for t in m['tables'] if t not in (m['policy_profile'],m['legacy_registry'])]
        contract_summary=core.table_set_summary(psql,conn,db,env,log,contract_tables)
        pop=core.stage_population_payload(psql,conn,db,env,log,stage,m)
        policy=core.policy_method_configuration(psql,conn,db,env,log,m)
        overlay=strategy.overlay_payload(stage)
        effective_policy_payload={
            'accepted_policy_method':policy['payload'],
            'successor_strategy_overlay':overlay
        }
        effective_policy_method_sha=hash_text(canon(effective_policy_payload),'sha256')
        validation_hash=hash_text(canon(sorted(checks,key=lambda x:x['control_id'])),'sha256')

        payload={
            'stage':m['stage'],
            'predecessor_stage':m['prev'],
            'accepted_predecessor_combined_hash':prior,
            'accepted_output_combined_hash':legacy_hash,
            'accepted_schema_source_sha256':srcs['SCHEMA']['sha256'],
            'accepted_generation_source_sha256':srcs['GEN']['sha256'],
            'transformed_schema_sha256':sha256_file(trans['SCHEMA']),
            'transformed_generation_sha256':sha256_file(trans['GEN']),
            'policy_method_sha256':effective_policy_method_sha,
            'successor_strategy_overlay':overlay,
            'contract_table_set_sha256':contract_summary['sha256'],
            'validation_sha256':validation_hash,
            'actual_population_payload':pop
        }
        successor_contract_sha=hash_text(canon(payload),'sha256')
        successor_contract_md5=hash_text(canon(payload),'md5')

        values={
            'stage_code':m['stage'],
            'predecessor_stage_code':m['prev'],
            'accepted_predecessor_combined_hash':prior,
            'accepted_output_combined_hash':legacy_hash,
            'successor_contract_hash':successor_contract_md5,
            'successor_contract_sha256':successor_contract_sha,
            'successor_evidence_hash':all_summary['md5'],
            'successor_evidence_sha256':all_summary['sha256'],
            'accepted_schema_source_sha256':srcs['SCHEMA']['sha256'],
            'accepted_generation_source_sha256':srcs['GEN']['sha256'],
            'transformed_schema_sha256':sha256_file(trans['SCHEMA']),
            'transformed_generation_sha256':sha256_file(trans['GEN']),
            'policy_method_hash':effective_policy_method_sha,
            'policy_method_payload':canon(effective_policy_payload),
            'legacy_policy_configuration_hash':policy.get('legacy_configuration_hash'),
            'contract_table_set_sha256':contract_summary['sha256'],
            'source_rows':pop['table_counts'][m['source_table']],
            'baseline_rows':pop['baseline_source_rows'],
            'stress_rows':pop['stress_source_rows'],
            'actual_population_payload':canon(pop),
            'legacy_registry_payload':canon(legacy),
            'legacy_registry_status':legacy_status,
            'contract_authority':'SUCCESSOR_WAVE_A_R16_'+mode,
            'validation_status':'VALIDATED_CANDIDATE'
        }
        insert_registry(psql,conn,db,env,log,values)

        for control in checks:
            run([
                psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',
                "INSERT INTO msbf_m12r1e.wave_a_validation_result"
                "(stage_code,control_id,status,observed) VALUES ('"
                +control['stage']+"','"
                +control['control_id'].replace("'","''")+"','"
                +control['status']+"','"
                +control['observed'].replace("'","''")+"');"
            ],env,log)

        run([
            psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',
            f"UPDATE msbf_m12r1e.downstream_rebase_status "
            f"SET rebase_status='VALIDATED_CANDIDATE',"
            f"successor_source_code='WAVE_A_R16_{m['stage'].replace('.','_')}_{successor_contract_md5}',"
            f"updated_at=clock_timestamp() "
            f"WHERE stage_code='{m['stage'].replace('.', '_')}';"
        ],env,log)

        prefix=m['stage'].replace('.','_')
        run([
            psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',
            f"INSERT INTO msbf_m12r1e.wave_a_legacy_run_evidence_archive(stage_code,evidence_payload) "
            f"SELECT '{m['stage']}',to_jsonb(e) FROM msbf_ctl.run_evidence e "
            f"WHERE run_id=1 AND evidence_code ~ '^{prefix}_'; "
            f"DELETE FROM msbf_ctl.run_evidence WHERE run_id=1 AND evidence_code ~ '^{prefix}_';"
        ],env,log)

        stage_receipt={
            **payload,
            'stage':m['stage'],
            'accepted_predecessor_combined_hash':prior,
            'accepted_output_combined_hash':legacy_hash,
            'successor_contract_hash':successor_contract_md5,
            'successor_contract_sha256':successor_contract_sha,
            'successor_evidence_hash':all_summary['md5'],
            'successor_evidence_sha256':all_summary['sha256'],
            'transformed_schema_sha256':sha256_file(trans['SCHEMA']),
            'transformed_generation_sha256':sha256_file(trans['GEN']),
            'legacy_registry_status':legacy_status,
            'all_table_set':all_summary,
            'contract_table_set':contract_summary,
            'validation_checks':checks
        }
        stage_receipts.append(stage_receipt)
        prior=legacy_hash

    if any(c['status']!='PASS' for c in all_checks):
        raise RuntimeError('One or more Wave A R17 controls failed')
    if core.table_count(psql,conn,db,env,log,'msbf_m12r1e.wave_a_stage_registry')!=6:
        raise RuntimeError('Wave A stage registry count mismatch')
    if scalar(psql,conn,db,env,log,
              "SELECT run_status FROM msbf_ctl.run_registry WHERE run_id=1;")!='M2_10_GENERATED':
        raise RuntimeError('Final run status not M2_10_GENERATED')

    status_shape=scalar(
        psql,conn,db,env,log,
        "SELECT count(*)||'|'||"
        "count(*) FILTER(WHERE rebase_status='VALIDATED_CANDIDATE')||'|'||"
        "count(*) FILTER(WHERE rebase_status='PENDING_REBASE') "
        "FROM msbf_m12r1e.downstream_rebase_status "
        "WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12');"
    )
    if status_shape!='8|6|2':
        raise RuntimeError('Downstream rebase status shape mismatch '+status_shape)

    export_specs=build_export_specs()
    view_contract=power_bi_view_contract_snapshot(psql,conn,db,env,log)
    (out/'89_POWER_BI_VIEW_EXPORT_CONTRACT.json').write_text(
        json.dumps(view_contract,indent=2),encoding='utf-8'
    )
    require_power_bi_view_contract(view_contract)
    export_preflight=export_query_preflight_all(psql,conn,db,env,log,export_specs)
    (out/'90_EXPORT_QUERY_PREFLIGHT.json').write_text(
        json.dumps(export_preflight,indent=2),encoding='utf-8'
    )
    export_identity=power_bi_export_identity(psql,conn,db,env,log,view_contract)
    (out/'91_POWER_BI_EXPORT_IDENTITY.json').write_text(
        json.dumps(export_identity,indent=2),encoding='utf-8'
    )
    source_payload_identity=source_payload_identity_snapshot(psql,conn,db,env,log)
    (out/'92_SOURCE_PAYLOAD_CANONICALIZATION_IDENTITY.json').write_text(
        json.dumps(source_payload_identity,indent=2),encoding='utf-8'
    )
    payload_failures=[]
    if source_payload_identity.get('object_count')!=6 or source_payload_identity.get('total_source_rows')!=665:
        payload_failures.append({'population':source_payload_identity.get('total_source_rows'),
          'object_count':source_payload_identity.get('object_count')})
    if source_payload_identity.get('total_volatile_time_key_rows')!=0:
        payload_failures.append({'volatile_time_key_rows':source_payload_identity.get('total_volatile_time_key_rows')})
    for code,obj in source_payload_identity.get('objects',{}).items():
        if obj.get('canonical_predecessor_mismatch_rows')!=0 or obj.get('active_canonical_predecessor_mismatch_rows')!=0:
            payload_failures.append({'code':code,'canonical_predecessor_mismatch_rows':obj.get('canonical_predecessor_mismatch_rows'),
              'active_canonical_predecessor_mismatch_rows':obj.get('active_canonical_predecessor_mismatch_rows')})
        if obj.get('source_rows')!=obj.get('predecessor_rows') or obj.get('source_rows')!=obj.get('joined_rows'):
            payload_failures.append({'code':code,'source_rows':obj.get('source_rows'),
              'predecessor_rows':obj.get('predecessor_rows'),'joined_rows':obj.get('joined_rows')})
    if payload_failures:
        raise RuntimeError('R15 source-payload canonicalization identity failed: '+canon(payload_failures))

    if mode=='FINAL':
        for name,query in export_specs.items():
            target=(out/f'{name}.csv').as_posix().replace("'","''")
            run([
                psql,*conn,'-d',db,'-X','-v','ON_ERROR_STOP=1','-c',
                f"\\copy ({query}) TO '{target}' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8');"
            ],env,log)
        with (out/'WAVE_A_R17_VALIDATION_RESULTS.csv').open('w',newline='',encoding='utf-8') as f:
            writer=csv.DictWriter(f,fieldnames=['stage','control_id','status','observed'])
            writer.writeheader();writer.writerows(all_checks)

    return {
        'stage_receipts':stage_receipts,'validation_checks':all_checks,
        'final_operational_hash':prior,'export_preflight':export_preflight,
        'power_bi_view_contract':view_contract,'power_bi_export_identity':export_identity,
        'source_payload_identity':source_payload_identity
    }


def compare_r14_r17_candidate(r14_snapshot,candidate,candidate_db_rows,candidate_db_identity):
    if candidate['power_bi_export_identity']!=r14_snapshot['power_bi_export_identity']:
        raise RuntimeError('R14/R17 curated Power BI export identity mismatch')
    if candidate['power_bi_view_contract']!=r14_snapshot['power_bi_view_contract']:
        raise RuntimeError('R14/R17 Power BI view contract mismatch')
    preflight_comparison=compare_r14_successor_export_preflight(
      r14_snapshot['export_preflight'],candidate['export_preflight'])
    r14_payload=r14_snapshot['source_payload_identity'];r17_payload=candidate['source_payload_identity']
    if r14_payload['business_bundle_sha256']!=r17_payload['business_bundle_sha256']:
        raise RuntimeError('R14/R17 source business projection identity mismatch')
    for code,obj in r17_payload['objects'].items():
        if obj['volatile_time_key_rows']!=0 or obj['created_at_key_rows']!=0:
            raise RuntimeError('R17 candidate retains a volatile payload key at '+code)
        if obj['raw_payload_sha256']!=obj['canonical_payload_sha256']:
            raise RuntimeError('R17 candidate raw/canonical payload identity differs at '+code)
        if obj['canonical_predecessor_mismatch_rows']!=0 or obj['active_canonical_predecessor_mismatch_rows']!=0:
            raise RuntimeError('R17 candidate canonical predecessor mismatch at '+code)
    if r14_payload['objects']['M2.7']['canonical_payload_sha256']!=r17_payload['objects']['M2.7']['canonical_payload_sha256']:
        raise RuntimeError('R14 canonical/R17 physical M2.7 source payload identity mismatch')
    expected_counts={'M2.5':16,'M2.6':14,'M2.7':16,'M2.8':22,'M2.9':27,'M2.10':20}
    observed_counts={stage:sum(x['stage']==stage for x in candidate['validation_checks']) for stage in expected_counts}
    if len(candidate['validation_checks'])!=115 or observed_counts!=expected_counts:
        raise RuntimeError('R17 validation population mismatch: '+canon({'total':len(candidate['validation_checks']),'stage_counts':observed_counts}))
    if any(x['status']!='PASS' for x in candidate['validation_checks']):
        raise RuntimeError('R17 candidate contains a failed control')
    old={(x['stage_code'],x['control_id']):x for x in r14_snapshot['stable_database_rows']['validation']}
    new={(x['stage_code'],x['control_id']):x for x in candidate_db_rows['validation']}
    missing=sorted(set(old)-set(new))
    if missing: raise RuntimeError('R17 omits R14 controls: '+canon(missing))
    added=sorted(set(new)-set(old))
    expected_added=sorted((('M2.'+re.match(r'^R15_M2_(10|[789])_',cid).group(1)),cid)
      for cid in R15_SOURCE_PAYLOAD_CONTROL_IDS)
    if added!=expected_added or len(added)!=12:
        raise RuntimeError('R14/R17 added validation-control domain mismatch: '+canon({'expected':expected_added,'actual':added}))
    allowed_observed={('M2.8','SOURCE_HASH_LINEAGE'),('M2.9','SOURCE_HASH_LINEAGE'),('M2.10','SOURCE_HASH_LINEAGE')}
    old_control_diffs=[]
    for key,row in old.items():
        candidate_row=new[key]
        if candidate_row['status']!=row['status']:
            raise RuntimeError('R17 changed prior control status '+canon({'key':key,'r14':row,'r17':candidate_row}))
        if candidate_row['observed']!=row['observed']:
            old_control_diffs.append({'stage':key[0],'control_id':key[1],
              'r14_observed':row['observed'],'r17_observed':candidate_row['observed']})
    if {(x['stage'],x['control_id']) for x in old_control_diffs}!=allowed_observed:
        raise RuntimeError('R14/R17 prior-control observed divergence class mismatch: '+canon(old_control_diffs))
    r14_stages={x['stage_code']:x for x in r14_snapshot['stable_database_rows']['stage_registry']}
    r17_stages={x['stage_code']:x for x in candidate_db_rows['stage_registry']}
    for stage in r14_stages:
        if r14_stages[stage]['actual_population_payload']!=r17_stages[stage]['actual_population_payload']:
            raise RuntimeError('R14/R17 stage population differs at '+stage)
    output_diffs=sorted(stage for stage in r14_stages
      if r14_stages[stage]['accepted_output_combined_hash']!=r17_stages[stage]['accepted_output_combined_hash'])
    if output_diffs!=['M2.10','M2.7','M2.8','M2.9']:
        raise RuntimeError('R14/R17 output-hash controlled-divergence stage set mismatch: '+canon(output_diffs))
    for stage in ['M2.5','M2.6']:
        fields=['accepted_predecessor_combined_hash','accepted_output_combined_hash','transformed_schema_sha256',
          'transformed_generation_sha256','policy_method_hash','legacy_policy_configuration_hash',
          'contract_table_set_sha256','successor_evidence_sha256','successor_contract_sha256']
        bad={f:{'r14':r14_stages[stage][f],'r17':r17_stages[stage][f]} for f in fields
             if r14_stages[stage][f]!=r17_stages[stage][f]}
        if bad: raise RuntimeError('R17 unexpectedly changes pre-defect stage '+stage+': '+canon(bad))
    return {
      'status':'PASS','prior_control_domain_preserved':True,'prior_control_status_preserved':True,
      'controlled_prior_observed_differences':old_control_diffs,
      'r15_added_control_count':12,'r15_total_control_count':115,
      'r14_r17_export_preflight_comparison':preflight_comparison,
      'r14_r17_power_bi_identity_match':True,'r14_r17_business_identity_match':True,
      'r14_canonical_r17_physical_m2_7_payload_match':True,
      'r17_raw_canonical_payload_identity_match':True,
      'r17_volatile_time_key_rows':r17_payload['total_volatile_time_key_rows'],
      'r17_total_source_payload_rows':r17_payload['total_source_rows'],
      'controlled_output_hash_divergence_stages':output_diffs,
      'r14_power_bi_bundle_sha256':r14_snapshot['power_bi_export_identity']['bundle_sha256'],
      'r17_power_bi_bundle_sha256':candidate['power_bi_export_identity']['bundle_sha256'],
      'r14_business_bundle_sha256':r14_payload['business_bundle_sha256'],
      'r17_business_bundle_sha256':r17_payload['business_bundle_sha256'],
      'r17_database_identity':candidate_db_identity}


def compare_r16_r17_candidate_exact(r16_evidence,candidate,candidate_db_rows,candidate_db_identity):
    candidate_normalized=normalized_result(candidate)
    comparisons={
      'normalized_result':candidate_normalized==r16_evidence['compiler_normalized_result'],
      'stable_database_rows':candidate_db_rows==r16_evidence['compiler_stable_database_rows'],
      'database_identity':candidate_db_identity==r16_evidence['compiler_database_identity'],
      'power_bi_view_contract':candidate['power_bi_view_contract']==r16_evidence['compiler_power_bi_view_contract'],
      'export_preflight':candidate['export_preflight']==r16_evidence['compiler_export_preflight'],
      'power_bi_export_identity':candidate['power_bi_export_identity']==r16_evidence['compiler_power_bi_export_identity'],
      'source_payload_identity':candidate['source_payload_identity']==r16_evidence['compiler_source_payload_identity']}
    failures=sorted(k for k,v in comparisons.items() if not v)
    if failures: raise RuntimeError('R16/R17 exact candidate replay mismatch: '+canon(failures))
    return {'status':'PASS','exact_components':sorted(comparisons),
      'r16_database_identity':r16_evidence['compiler_database_identity'],
      'r17_database_identity':candidate_db_identity,
      'power_bi_bundle_sha256':candidate['power_bi_export_identity']['bundle_sha256'],
      'source_payload_bundle_sha256':candidate['source_payload_identity']['raw_payload_bundle_sha256'],
      'business_bundle_sha256':candidate['source_payload_identity']['business_bundle_sha256']}

def normalized_result(result):
    return [{'stage':x['stage'],'accepted_predecessor_combined_hash':x['accepted_predecessor_combined_hash'],
      'accepted_output_combined_hash':x['accepted_output_combined_hash'],'successor_contract_hash':x['successor_contract_hash'],
      'successor_contract_sha256':x['successor_contract_sha256'],'successor_evidence_hash':x['successor_evidence_hash'],
      'successor_evidence_sha256':x['successor_evidence_sha256'],'actual_population_payload':x['actual_population_payload'],
      'validation_checks':x['validation_checks']} for x in result['stage_receipts']]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-db',default='msbf_r1_m2_4_r6_20260830_030634')
    parser.add_argument('--r12-diagnostic-db',default='msbf_r1_wave_a_r12_compile_20260830_165946')
    parser.add_argument('--r13-diagnostic-db',default='msbf_r1_wave_a_r13_compile_20260830_190007')
    parser.add_argument('--r14-diagnostic-db',default='msbf_r1_wave_a_r14_compile_20260830_195709')
    parser.add_argument('--r16-diagnostic-db',default='msbf_r1_wave_a_r16_compile_20260830_231947')
    parser.add_argument('--pg-bin',default=r'C:\Program Files\PostgreSQL\17\bin')
    parser.add_argument('--host',default='localhost');parser.add_argument('--port',default='5432')
    parser.add_argument('--user',default='postgres');args=parser.parse_args()

    pg=Path(args.pg_bin);psql=str(pg/'psql.exe');createdb=str(pg/'createdb.exe');dropdb=str(pg/'dropdb.exe')
    for executable in [psql,createdb,dropdb]:
        if not Path(executable).exists(): raise SystemExit(f'Missing {executable}')

    password=getpass.getpass('PostgreSQL password for local user postgres (not stored): ')
    env=os.environ.copy();env['PGPASSWORD']=password
    env_ro=env.copy();env_ro['PGOPTIONS']='-c default_transaction_read_only=on'
    conn=['-h',args.host,'-p',str(args.port),'-U',args.user]

    stamp=datetime.now().strftime('%Y%m%d_%H%M%S')
    compiler_db=f'msbf_r1_wave_a_r17_compile_{stamp}';final_db=f'msbf_r1_wave_a_r17_{stamp}'
    out=HERE/'results'/final_db
    for directory in ['logs','evidence/compiler','evidence/final','evidence/diagnostic','transformed_sources']:
        (out/directory).mkdir(parents=True,exist_ok=True)
    log=out/'logs/WAVE_A_R17.log'

    receipt={
      'phase':'WAVE_A_R17_EXPORT_PREFLIGHT_COMPARATOR_CORRECTION_COMPILE_THEN_EXECUTE',
      'status':'RUNNING','source_db':args.source_db,
      'r12_diagnostic_db':args.r12_diagnostic_db,'r13_diagnostic_db':args.r13_diagnostic_db,
      'r14_diagnostic_db':args.r14_diagnostic_db,'r16_diagnostic_db':args.r16_diagnostic_db,
      'compiler_db':compiler_db,'final_db':final_db,
      'started_at_utc':datetime.now(timezone.utc).isoformat(),'accepted_authority_changed':False,
      'source_modified':False,'r12_rerun_performed':False,'r13_rerun_performed':False,
      'r14_rerun_performed':False,'r15_rerun_performed':False,'r16_rerun_performed':False,
      'r12_diagnostic_read_only':True,'r13_diagnostic_read_only':True,
      'r14_diagnostic_read_only':True,'r16_diagnostic_read_only':True,'r15_failure_evidence_read_only':True,
      'r16_failure_evidence_read_only':True,'r12_diagnostic_retained':True,'r13_diagnostic_retained':True,
      'r14_diagnostic_retained':True,'r16_diagnostic_retained':True,
      'r12_diagnostic_modified':False,'r13_diagnostic_modified':False,
      'r14_diagnostic_modified':False,'r16_diagnostic_modified':False,'compiler_clone_created':False,'compiler_clone_dropped':False,
      'final_clone_created':False,'last_stage':'SOURCE_PREFLIGHT'}
    source_fingerprint=None;exit_code=1
    r12_before=None;r13_before=None;r14_before=None;r16_before=None

    try:
        receipt['package_manifest_preflight']=verify_package_manifest()
        receipt['r12_failure_evidence_preflight']=verify_r12_failure_evidence()
        receipt['r13_failure_evidence_preflight']=verify_r13_failure_evidence()
        r14_failure_preflight=verify_r14_failure_evidence()
        receipt['r14_failure_evidence_preflight']=r14_failure_preflight
        r15_failure_preflight=verify_r15_failure_evidence()
        receipt['r15_failure_evidence_preflight']=r15_failure_preflight
        receipt['r16_diagnostic_comparator_mutation_negative_tests']=r15_failure_preflight['r16_comparator_mutation_negative_tests']
        r16_failure_preflight=verify_r16_failure_evidence()
        receipt['r16_failure_evidence_preflight']=r16_failure_preflight['summary']
        receipt['r17_export_preflight_comparator_mutation_negative_tests']=r16_failure_preflight['comparator_mutation_negative_tests']
        if r15_failure_preflight['r13_database_identity']!=r14_failure_preflight['r13_database_identity']:
            raise RuntimeError('R15 evidence R13 identity differs from verified R14 result evidence')
        if r15_failure_preflight['r14_database_identity']!=r14_failure_preflight['r14_compiler_database_identity']:
            raise RuntimeError('R15 evidence R14 identity differs from verified R14 result evidence')
        if r15_failure_preflight['r14_power_bi_bundle_sha256']!=r14_failure_preflight['r14_power_bi_bundle_sha256']:
            raise RuntimeError('R15 evidence R14 Power BI identity differs from verified R14 result evidence')
        receipt['r14_r15_result_evidence_identity_binding']='PASS'
        if r16_failure_preflight['r14_snapshot']['stable_database_identity']!=r14_failure_preflight['r14_compiler_database_identity']:
            raise RuntimeError('R16 evidence embedded R14 identity differs from verified R14 result evidence')
        if r16_failure_preflight['r14_snapshot']['power_bi_export_identity']['bundle_sha256']!=r14_failure_preflight['r14_power_bi_bundle_sha256']:
            raise RuntimeError('R16 evidence embedded R14 Power BI identity differs from verified R14 result evidence')
        receipt['r14_r16_result_evidence_identity_binding']='PASS'
        receipt['strategy_configuration_preflight']=verify_strategy_configuration()

        for source in SRC_MAN:
            path=HERE/source['package_path']
            if sha256_file(path)!=source['sha256']:
                raise RuntimeError(f"Accepted source hash mismatch {source['package_path']}")
        static=static_transform_preflight()
        (out/'evidence/00_STATIC_TRANSFORM_AUDIT.json').write_text(json.dumps(static,indent=2),encoding='utf-8')

        columns=catalog_column_preflight(psql,conn,args.source_db,env_ro,log)
        with (out/'evidence/01_SOURCE_CONTROL_COLUMN_PREFLIGHT.csv').open('w',newline='',encoding='utf-8') as f:
            writer=csv.DictWriter(f,fieldnames=columns[0].keys());writer.writeheader();writer.writerows(columns)

        status_meta_sql="""SELECT jsonb_build_object(
          'relpersistence',(SELECT c.relpersistence::text FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='msbf_m12r1e' AND c.relname='downstream_rebase_status'),
          'rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status),
          'stage_codes',(SELECT jsonb_agg(stage_code ORDER BY stage_code) FROM msbf_m12r1e.downstream_rebase_status),
          'm2_4_status',(SELECT rebase_status FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code='M2_4'),
          'pending_rows',(SELECT count(*) FROM msbf_m12r1e.downstream_rebase_status WHERE stage_code IN ('M2_5','M2_6','M2_7','M2_8','M2_9','M2_10','M2_11','M2_12') AND rebase_status='PENDING_REBASE'))::text;"""
        status_meta=json.loads(scalar(psql,conn,args.source_db,env_ro,log,status_meta_sql))
        receipt['downstream_rebase_source_meta']=status_meta
        expected_codes=['M2_10','M2_11','M2_12','M2_4','M2_5','M2_6','M2_7','M2_8','M2_9']
        if (status_meta.get('relpersistence')!='p' or status_meta.get('rows')!=9 or
            status_meta.get('stage_codes')!=expected_codes or status_meta.get('m2_4_status')!='VALIDATED_CANDIDATE' or
            status_meta.get('pending_rows')!=8):
            raise RuntimeError('R6 downstream-rebase physical domain mismatch: '+canon(status_meta))

        before=source_control(psql,conn,args.source_db,env_ro,log);validate_source_control(before)
        source_fingerprint=control_fingerprint(before);receipt['source_control_before']=before
        receipt['source_fingerprint_before']=source_fingerprint

        requirements=list(csv.DictReader((HERE/'manifests/04_WAVE_A_SOURCE_PREFLIGHT_REQUIREMENTS.csv').open(encoding='utf-8')))
        object_results=[]
        for requirement in requirements:
            ok=core.object_present(psql,conn,args.source_db,env_ro,log,requirement['object_name'],requirement['object_type'])
            object_results.append({**requirement,'status':'PASS' if ok else 'FAIL'})
        with (out/'evidence/02_SOURCE_OBJECT_PREFLIGHT.csv').open('w',newline='',encoding='utf-8') as f:
            writer=csv.DictWriter(f,fieldnames=object_results[0].keys());writer.writeheader();writer.writerows(object_results)
        if any(x['status']=='FAIL' for x in object_results):
            raise RuntimeError('Wave A R17 source object preflight failed')

        data_directory=scalar(psql,conn,'postgres',env,log,'SHOW data_directory;')
        source_size=int(scalar(psql,conn,'postgres',env,log,f"SELECT pg_database_size('{args.source_db}');"))
        free_bytes=shutil.disk_usage(Path(data_directory)).free;required_bytes=int(source_size*1.35+3*1024**3)
        receipt['disk_preflight_compiler']={'data_directory':data_directory,'source_size_bytes':source_size,
          'free_bytes':free_bytes,'required_bytes':required_bytes}
        if free_bytes<required_bytes:
            raise RuntimeError(f'Insufficient disk for compiler clone: free={free_bytes} required={required_bytes}')

        diag_dir=out/'evidence/diagnostic';diag_dir.mkdir(parents=True,exist_ok=True)

        receipt['last_stage']='R12_M2_9_READ_ONLY_DIAGNOSTIC_PREFLIGHT'
        if not database_exists(psql,conn,env_ro,log,args.r12_diagnostic_db):
            raise RuntimeError('Required retained R12 M2.9 diagnostic compiler is absent')
        r12_before=r12_diagnostic_snapshot(psql,conn,args.r12_diagnostic_db,env_ro,log)
        validate_r12_diagnostic_snapshot(r12_before);receipt['r12_diagnostic_before']=r12_before
        (diag_dir/'R12_M2_9_READ_ONLY_DIAGNOSTIC.json').write_text(json.dumps(r12_before,indent=2),encoding='utf-8')
        affected=r12_before['affected_rows']
        if affected:
            with (diag_dir/'R12_M2_9_AFFECTED_ROWS.csv').open('w',newline='',encoding='utf-8') as f:
                writer=csv.DictWriter(f,fieldnames=list(affected[0].keys()));writer.writeheader();writer.writerows(affected)
        receipt['r12_diagnostic_validation']='PASS'

        receipt['last_stage']='R13_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC_PREFLIGHT'
        if not database_exists(psql,conn,env_ro,log,args.r13_diagnostic_db):
            raise RuntimeError('Required retained R13 compiler is absent')
        r13_before=r13_diagnostic_snapshot(psql,conn,args.r13_diagnostic_db,env_ro,log)
        validate_successful_wave_diagnostic_snapshot(r13_before,'R13');receipt['r13_diagnostic_before']=r13_before
        (diag_dir/'R13_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json').write_text(json.dumps(r13_before,indent=2),encoding='utf-8')
        receipt['r13_diagnostic_validation']='PASS'

        receipt['last_stage']='R14_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC_PREFLIGHT'
        if not database_exists(psql,conn,env_ro,log,args.r14_diagnostic_db):
            raise RuntimeError('Required retained R14 compiler is absent')
        r14_before=r13_diagnostic_snapshot(psql,conn,args.r14_diagnostic_db,env_ro,log)
        validate_successful_wave_diagnostic_snapshot(r14_before,'R14');receipt['r14_diagnostic_before']=r14_before
        (diag_dir/'R14_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json').write_text(json.dumps(r14_before,indent=2),encoding='utf-8')
        receipt['r14_diagnostic_validation']='PASS'

        r13_r14_comparison=compare_r13_r14_diagnostics(r13_before,r14_before)
        (diag_dir/'R13_R14_FIRST_DIVERGENCE_DIAGNOSTIC.json').write_text(
          json.dumps(r13_r14_comparison,indent=2),encoding='utf-8')
        if r13_before['stable_database_identity']!=r14_failure_preflight['r13_database_identity']:
            raise RuntimeError('Physical R13 diagnostic identity differs from verified R14 result evidence')
        if r14_before['stable_database_identity']!=r14_failure_preflight['r14_compiler_database_identity']:
            raise RuntimeError('Physical R14 diagnostic identity differs from verified R14 result evidence')
        if r14_before['power_bi_export_identity']['bundle_sha256']!=r14_failure_preflight.get('r14_power_bi_bundle_sha256',r14_before['power_bi_export_identity']['bundle_sha256']):
            raise RuntimeError('Physical R14 Power BI identity differs from verified R14 result evidence')
        if r13_before['stable_database_identity']!=r15_failure_preflight['r13_database_identity']:
            raise RuntimeError('Physical R13 diagnostic identity differs from verified R15 result evidence')
        if r14_before['stable_database_identity']!=r15_failure_preflight['r14_database_identity']:
            raise RuntimeError('Physical R14 diagnostic identity differs from verified R15 result evidence')
        if r13_before['power_bi_export_identity']['bundle_sha256']!=r15_failure_preflight['r13_power_bi_bundle_sha256']:
            raise RuntimeError('Physical R13 Power BI identity differs from verified R15 result evidence')
        if r14_before['power_bi_export_identity']['bundle_sha256']!=r15_failure_preflight['r14_power_bi_bundle_sha256']:
            raise RuntimeError('Physical R14 Power BI identity differs from verified R15 result evidence')
        receipt['r13_r14_first_divergence_diagnostic']='PASS'
        receipt['r16_diagnostic_comparator_controls']=r13_r14_comparison['diagnostic_comparator_controls']

        receipt['last_stage']='R16_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC_PREFLIGHT'
        if not database_exists(psql,conn,env_ro,log,args.r16_diagnostic_db):
            raise RuntimeError('Required retained R16 compiler is absent')
        r16_before=r16_diagnostic_snapshot(psql,conn,args.r16_diagnostic_db,env_ro,log)
        validate_canonicalized_wave_diagnostic_snapshot(r16_before,'R16');receipt['r16_diagnostic_before']=r16_before
        (diag_dir/'R16_SUCCESSFUL_WAVE_READ_ONLY_DIAGNOSTIC.json').write_text(json.dumps(r16_before,indent=2),encoding='utf-8')
        r16_physical_binding=compare_r16_result_to_physical(r16_failure_preflight,r16_before)
        (diag_dir/'R16_RESULT_PHYSICAL_IDENTITY_BINDING.json').write_text(json.dumps(r16_physical_binding,indent=2),encoding='utf-8')
        r14_r16_preflight=compare_r14_successor_export_preflight(r14_before['export_preflight'],r16_before['export_preflight'])
        (diag_dir/'R14_R16_EXPORT_PREFLIGHT_CONTROLLED_POPULATION.json').write_text(json.dumps(r14_r16_preflight,indent=2),encoding='utf-8')
        receipt['r16_diagnostic_validation']='PASS'
        receipt['r14_r16_export_preflight_controlled_population']='PASS'

        receipt['last_stage']='COMPILER_CLONE'
        run([createdb,*conn,'-T',args.source_db,compiler_db],env,log)
        receipt['compiler_clone_created']=database_exists(psql,conn,env,log,compiler_db)
        if not receipt['compiler_clone_created']:
            raise RuntimeError('Compiler createdb returned success but clone is absent')

        receipt['last_stage']='COMPILER_FULL_PATH'
        compiler=execute_wave(psql,conn,compiler_db,env,log,'COMPILER',out/'evidence/compiler',
          out/'transformed_sources',before['m2_4_combined_set_hash'],prepared=False)
        (out/'evidence/COMPILER_STAGE_RECEIPTS.json').write_text(json.dumps(compiler['stage_receipts'],indent=2),encoding='utf-8')
        compiler_normalized=normalized_result(compiler)
        (out/'evidence/COMPILER_NORMALIZED_RESULT.json').write_text(json.dumps(compiler_normalized,indent=2),encoding='utf-8')
        compiler_db_rows=stable_database_rows(psql,conn,compiler_db,env_ro,log)
        (out/'evidence/COMPILER_STABLE_DATABASE_ROWS.json').write_text(json.dumps(compiler_db_rows,indent=2),encoding='utf-8')
        compiler_db_identity=stable_database_identity(psql,conn,compiler_db,env_ro,log)
        (out/'evidence/COMPILER_DATABASE_IDENTITY.json').write_text(json.dumps(compiler_db_identity,indent=2),encoding='utf-8')
        compiler_controlled=compare_r14_r17_candidate(r14_before,compiler,compiler_db_rows,compiler_db_identity)
        (out/'evidence/93_R14_R17_COMPILER_CONTROLLED_DIVERGENCE.json').write_text(
          json.dumps(compiler_controlled,indent=2),encoding='utf-8')
        compiler_r16_exact=compare_r16_r17_candidate_exact(r16_failure_preflight,compiler,compiler_db_rows,compiler_db_identity)
        (out/'evidence/94_R16_R17_COMPILER_EXACT_REPLAY.json').write_text(
          json.dumps(compiler_r16_exact,indent=2),encoding='utf-8')
        receipt['r14_r17_compiler_controlled_divergence']='PASS'
        receipt['r16_r17_compiler_exact_replay']='PASS'
        receipt['compiler_final_operational_hash']=compiler['final_operational_hash']
        receipt['compiler_validation_control_count']=len(compiler['validation_checks'])
        receipt['compiler_source_payload_rows']=compiler['source_payload_identity']['total_source_rows']
        receipt['compiler_source_payload_volatile_rows']=compiler['source_payload_identity']['total_volatile_time_key_rows']

        receipt['last_stage']='DROP_COMPILER'
        receipt['compiler_clone_dropped']=db_drop(dropdb,conn,compiler_db,env,log)
        if database_exists(psql,conn,env,log,compiler_db):
            raise RuntimeError('Compiler clone still exists after drop')
        free_after_compiler=shutil.disk_usage(Path(data_directory)).free
        receipt['disk_preflight_final']={'data_directory':data_directory,'source_size_bytes':source_size,
          'free_bytes':free_after_compiler,'required_bytes':required_bytes}
        if free_after_compiler<required_bytes:
            raise RuntimeError(f'Insufficient disk for final clone: free={free_after_compiler} required={required_bytes}')

        receipt['last_stage']='FINAL_CLONE'
        run([createdb,*conn,'-T',args.source_db,final_db],env,log)
        receipt['final_clone_created']=database_exists(psql,conn,env,log,final_db)
        if not receipt['final_clone_created']:
            raise RuntimeError('Final createdb returned success but clone is absent')

        receipt['last_stage']='FINAL_FULL_PATH'
        final=execute_wave(psql,conn,final_db,env,log,'FINAL',out/'evidence/final',out/'transformed_sources',
          before['m2_4_combined_set_hash'],compiler_receipts=compiler['stage_receipts'],prepared=False)
        final_normalized=normalized_result(final)
        (out/'evidence/FINAL_STAGE_RECEIPTS.json').write_text(json.dumps(final['stage_receipts'],indent=2),encoding='utf-8')
        (out/'evidence/FINAL_NORMALIZED_RESULT.json').write_text(json.dumps(final_normalized,indent=2),encoding='utf-8')
        final_db_rows=stable_database_rows(psql,conn,final_db,env_ro,log)
        (out/'evidence/FINAL_STABLE_DATABASE_ROWS.json').write_text(json.dumps(final_db_rows,indent=2),encoding='utf-8')
        final_db_identity=stable_database_identity(psql,conn,final_db,env_ro,log)
        (out/'evidence/FINAL_DATABASE_IDENTITY.json').write_text(json.dumps(final_db_identity,indent=2),encoding='utf-8')

        if compiler_normalized!=final_normalized:
            raise RuntimeError('Compiler/final stage-receipt re-performance mismatch')
        if compiler_db_rows!=final_db_rows:
            raise RuntimeError('Compiler/final stable database rows mismatch')
        if compiler_db_identity!=final_db_identity:
            raise RuntimeError('Compiler/final database-derived identity mismatch')
        if compiler['power_bi_view_contract']!=final['power_bi_view_contract']:
            raise RuntimeError('Compiler/final Power BI view contract mismatch')
        if compiler['export_preflight']!=final['export_preflight']:
            raise RuntimeError('Compiler/final export preflight mismatch')
        if compiler['power_bi_export_identity']!=final['power_bi_export_identity']:
            raise RuntimeError('Compiler/final Power BI export identity mismatch')
        if compiler['source_payload_identity']!=final['source_payload_identity']:
            raise RuntimeError('Compiler/final source-payload identity mismatch')
        final_controlled=compare_r14_r17_candidate(r14_before,final,final_db_rows,final_db_identity)
        (out/'evidence/95_R14_R17_FINAL_CONTROLLED_DIVERGENCE.json').write_text(
          json.dumps(final_controlled,indent=2),encoding='utf-8')
        final_r16_exact=compare_r16_r17_candidate_exact(r16_failure_preflight,final,final_db_rows,final_db_identity)
        (out/'evidence/96_R16_R17_FINAL_EXACT_REPLAY.json').write_text(
          json.dumps(final_r16_exact,indent=2),encoding='utf-8')
        if compiler_controlled!=final_controlled:
            raise RuntimeError('Compiler/final controlled-divergence evidence mismatch')
        if compiler_r16_exact!=final_r16_exact:
            raise RuntimeError('Compiler/final R16 exact-replay evidence mismatch')

        cross_state_identity={
          'r13_r14_first_divergence_diagnostic_pass':True,
          'r14_to_r17_compiler_controlled_divergence_pass':True,
          'r16_to_r17_compiler_exact_replay_pass':True,
          'r14_to_r17_final_controlled_divergence_pass':True,
          'r16_to_r17_final_exact_replay_pass':True,
          'r15_source_payload_correction_carried_forward':True,
          'r16_diagnostic_comparator_correction_carried_forward':True,
          'r17_export_preflight_comparator_correction_pass':True,
          'compiler_to_final_normalized_result_match':True,
          'compiler_to_final_stable_database_rows_match':True,
          'compiler_to_final_database_identity_match':True,
          'compiler_to_final_power_bi_view_contract_match':True,
          'compiler_to_final_export_preflight_match':True,
          'compiler_to_final_power_bi_identity_match':True,
          'compiler_to_final_source_payload_identity_match':True,
          'r13_database_identity':r13_before['stable_database_identity'],
          'r14_database_identity':r14_before['stable_database_identity'],
          'r16_database_identity':r16_before['stable_database_identity'],
          'compiler_database_identity':compiler_db_identity,'final_database_identity':final_db_identity,
          'r13_power_bi_bundle_sha256':r13_before['power_bi_export_identity']['bundle_sha256'],
          'r14_power_bi_bundle_sha256':r14_before['power_bi_export_identity']['bundle_sha256'],
          'r16_power_bi_bundle_sha256':r16_before['power_bi_export_identity']['bundle_sha256'],
          'compiler_power_bi_bundle_sha256':compiler['power_bi_export_identity']['bundle_sha256'],
          'final_power_bi_bundle_sha256':final['power_bi_export_identity']['bundle_sha256'],
          'compiler_source_payload_bundle_sha256':compiler['source_payload_identity']['raw_payload_bundle_sha256'],
          'final_source_payload_bundle_sha256':final['source_payload_identity']['raw_payload_bundle_sha256'],
          'compiler_business_bundle_sha256':compiler['source_payload_identity']['business_bundle_sha256'],
          'final_business_bundle_sha256':final['source_payload_identity']['business_bundle_sha256']}
        (out/'evidence/97_CROSS_STATE_IDENTITY_COMPARISON.json').write_text(
          json.dumps(cross_state_identity,indent=2),encoding='utf-8')
        receipt['compiler_final_normalized_result_match']=True
        receipt['compiler_final_stable_database_rows_match']=True
        receipt['compiler_final_database_identity_match']=True
        receipt['compiler_final_power_bi_identity_match']=True
        receipt['compiler_final_source_payload_identity_match']=True

        after=source_control(psql,conn,args.source_db,env_ro,log);receipt['source_control_after']=after
        receipt['source_fingerprint_after']=control_fingerprint(after)
        receipt['source_modified']=receipt['source_fingerprint_after']!=source_fingerprint
        if receipt['source_modified']:
            raise RuntimeError('R6 source fingerprint changed')

        r12_after=r12_diagnostic_snapshot(psql,conn,args.r12_diagnostic_db,env_ro,log)
        validate_r12_diagnostic_snapshot(r12_after);receipt['r12_diagnostic_after']=r12_after
        receipt['r12_diagnostic_modified']=(r12_after['diagnostic_fingerprint_sha256']!=r12_before['diagnostic_fingerprint_sha256'])
        if receipt['r12_diagnostic_modified']:
            raise RuntimeError('R12 diagnostic compiler fingerprint changed')

        r13_after=r13_diagnostic_snapshot(psql,conn,args.r13_diagnostic_db,env_ro,log)
        validate_successful_wave_diagnostic_snapshot(r13_after,'R13');receipt['r13_diagnostic_after']=r13_after
        receipt['r13_diagnostic_modified']=(r13_after['diagnostic_fingerprint_sha256']!=r13_before['diagnostic_fingerprint_sha256'])
        if receipt['r13_diagnostic_modified']:
            raise RuntimeError('R13 diagnostic compiler fingerprint changed')

        r14_after=r13_diagnostic_snapshot(psql,conn,args.r14_diagnostic_db,env_ro,log)
        validate_successful_wave_diagnostic_snapshot(r14_after,'R14');receipt['r14_diagnostic_after']=r14_after
        receipt['r14_diagnostic_modified']=(r14_after['diagnostic_fingerprint_sha256']!=r14_before['diagnostic_fingerprint_sha256'])
        if receipt['r14_diagnostic_modified']:
            raise RuntimeError('R14 diagnostic compiler fingerprint changed')

        r16_after=r16_diagnostic_snapshot(psql,conn,args.r16_diagnostic_db,env_ro,log)
        validate_canonicalized_wave_diagnostic_snapshot(r16_after,'R16');receipt['r16_diagnostic_after']=r16_after
        receipt['r16_diagnostic_modified']=(r16_after['diagnostic_fingerprint_sha256']!=r16_before['diagnostic_fingerprint_sha256'])
        if receipt['r16_diagnostic_modified']:
            raise RuntimeError('R16 diagnostic compiler fingerprint changed')

        receipt.update({
          'status':'PASS','last_stage':'COMPLETE','final_wave_a_operational_hash':final['final_operational_hash'],
          'compiler_final_match':True,'r14_r17_controlled_divergence_pass':True,
          'r16_r17_exact_replay_pass':True,
          'r15_source_payload_correction_carried_forward':True,'r16_diagnostic_comparator_correction_carried_forward':True,
          'r17_export_preflight_comparator_correction_pass':True,
          'compiler_final_normalized_result_match':True,'compiler_final_stable_database_rows_match':True,
          'compiler_final_database_identity_match':True,'compiler_final_power_bi_identity_match':True,
          'compiler_final_source_payload_identity_match':True,
          'validation_control_count':len(final['validation_checks']),
          'source_payload_object_count':final['source_payload_identity']['object_count'],
          'source_payload_row_count':final['source_payload_identity']['total_source_rows'],
          'source_payload_volatile_time_key_rows':final['source_payload_identity']['total_volatile_time_key_rows'],
          'power_bi_export_identity_bundle_sha256':final['power_bi_export_identity']['bundle_sha256'],
          'source_payload_identity_bundle_sha256':final['source_payload_identity']['raw_payload_bundle_sha256'],
          'source_business_identity_bundle_sha256':final['source_payload_identity']['business_bundle_sha256'],
          'finished_at_utc':datetime.now(timezone.utc).isoformat()})
        exit_code=0

    except Exception as error:
        receipt.update({'status':'FAIL','error':repr(error),'finished_at_utc':datetime.now(timezone.utc).isoformat()})
        try:
            if source_fingerprint is not None:
                after=source_control(psql,conn,args.source_db,env_ro,log);receipt['source_control_after']=after
                receipt['source_fingerprint_after']=control_fingerprint(after)
                receipt['source_modified']=receipt['source_fingerprint_after']!=source_fingerprint
        except Exception as source_error:
            receipt['source_recheck_error']=repr(source_error)
        try:
            if r12_before is not None:
                r12_after=r12_diagnostic_snapshot(psql,conn,args.r12_diagnostic_db,env_ro,log);receipt['r12_diagnostic_after']=r12_after
                receipt['r12_diagnostic_modified']=(r12_after['diagnostic_fingerprint_sha256']!=r12_before['diagnostic_fingerprint_sha256'])
        except Exception as diagnostic_error:
            receipt['r12_diagnostic_recheck_error']=repr(diagnostic_error)
        try:
            if r13_before is not None:
                r13_after=r13_diagnostic_snapshot(psql,conn,args.r13_diagnostic_db,env_ro,log);receipt['r13_diagnostic_after']=r13_after
                receipt['r13_diagnostic_modified']=(r13_after['diagnostic_fingerprint_sha256']!=r13_before['diagnostic_fingerprint_sha256'])
        except Exception as diagnostic_error:
            receipt['r13_diagnostic_recheck_error']=repr(diagnostic_error)
        try:
            if r14_before is not None:
                r14_after=r13_diagnostic_snapshot(psql,conn,args.r14_diagnostic_db,env_ro,log);receipt['r14_diagnostic_after']=r14_after
                receipt['r14_diagnostic_modified']=(r14_after['diagnostic_fingerprint_sha256']!=r14_before['diagnostic_fingerprint_sha256'])
        except Exception as diagnostic_error:
            receipt['r14_diagnostic_recheck_error']=repr(diagnostic_error)
        try:
            if r16_before is not None:
                r16_after=r16_diagnostic_snapshot(psql,conn,args.r16_diagnostic_db,env_ro,log);receipt['r16_diagnostic_after']=r16_after
                receipt['r16_diagnostic_modified']=(r16_after['diagnostic_fingerprint_sha256']!=r16_before['diagnostic_fingerprint_sha256'])
        except Exception as diagnostic_error:
            receipt['r16_diagnostic_recheck_error']=repr(diagnostic_error)

    finally:
        receipt['r12_rerun_performed']=False;receipt['r13_rerun_performed']=False;receipt['r14_rerun_performed']=False;receipt['r15_rerun_performed']=False;receipt['r16_rerun_performed']=False
        probe_errors=[]
        r12_probe=safe_database_probe(psql,conn,env_ro,log,args.r12_diagnostic_db);receipt['r12_diagnostic_exit_probe']=r12_probe
        if r12_probe['status']=='PASS': receipt['r12_diagnostic_retained']=r12_probe['exists']
        else: probe_errors.append({'database_role':'R12_DIAGNOSTIC',**r12_probe})
        r13_probe=safe_database_probe(psql,conn,env_ro,log,args.r13_diagnostic_db);receipt['r13_diagnostic_exit_probe']=r13_probe
        if r13_probe['status']=='PASS': receipt['r13_diagnostic_retained']=r13_probe['exists']
        else: probe_errors.append({'database_role':'R13_DIAGNOSTIC',**r13_probe})
        r14_probe=safe_database_probe(psql,conn,env_ro,log,args.r14_diagnostic_db);receipt['r14_diagnostic_exit_probe']=r14_probe
        if r14_probe['status']=='PASS': receipt['r14_diagnostic_retained']=r14_probe['exists']
        else: probe_errors.append({'database_role':'R14_DIAGNOSTIC',**r14_probe})
        r16_probe=safe_database_probe(psql,conn,env_ro,log,args.r16_diagnostic_db);receipt['r16_diagnostic_exit_probe']=r16_probe
        if r16_probe['status']=='PASS': receipt['r16_diagnostic_retained']=r16_probe['exists']
        else: probe_errors.append({'database_role':'R16_DIAGNOSTIC',**r16_probe})
        if receipt.get('compiler_clone_created') and not receipt.get('compiler_clone_dropped'):
            compiler_probe=safe_database_probe(psql,conn,env_ro,log,compiler_db)
        else:
            compiler_probe={'status':'NOT_REQUIRED','exists':False,'error':None}
        receipt['compiler_clone_exit_probe']=compiler_probe;receipt['compiler_clone_exists_at_exit']=compiler_probe['exists']
        if compiler_probe['status']=='UNAVAILABLE': probe_errors.append({'database_role':'R17_COMPILER',**compiler_probe})
        if receipt.get('final_clone_created'):
            final_probe=safe_database_probe(psql,conn,env_ro,log,final_db)
        else:
            final_probe={'status':'NOT_REQUIRED','exists':False,'error':None}
        receipt['final_clone_exit_probe']=final_probe;receipt['final_clone_exists_at_exit']=final_probe['exists']
        if final_probe['status']=='UNAVAILABLE': probe_errors.append({'database_role':'R17_FINAL',**final_probe})
        if probe_errors:
            receipt['finalization_probe_errors']=probe_errors
            if receipt.get('status')=='PASS':
                receipt.update({'status':'FAIL','last_stage':'FINALIZATION_DATABASE_PROBES',
                  'error':"RuntimeError('Final database-retention probes were unavailable')",
                  'finished_at_utc':datetime.now(timezone.utc).isoformat()});exit_code=1

        result_zip=HERE/'results'/f'{final_db}_WAVE_A_R17_RESULTS.zip';result_hash=None
        try:
            receipt_path=out/'WAVE_A_R17_RECEIPT.json';receipt_path.write_text(json.dumps(receipt,indent=2),encoding='utf-8')
            result_zip.parent.mkdir(exist_ok=True)
            with zipfile.ZipFile(result_zip,'w',zipfile.ZIP_DEFLATED) as archive:
                for path in out.rglob('*'):
                    if path.is_file(): archive.write(path,path.relative_to(out))
            result_hash=sha256_file(result_zip)
            Path(str(result_zip)+'.sha256').write_text(f'{result_hash}  {result_zip.name}\n',encoding='utf-8')
        except Exception as finalization_error:
            exit_code=1;controlling_error=receipt.get('error')
            receipt.update({'status':'FAIL','last_stage':'RESULT_PACKAGING','result_packaging_error':repr(finalization_error),
              'controlling_runtime_error_before_packaging':controlling_error,
              'finished_at_utc':datetime.now(timezone.utc).isoformat()})
            try: (out/'WAVE_A_R17_RECEIPT.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
            except Exception: pass
        finally:
            env.pop('PGPASSWORD',None);env_ro.pop('PGPASSWORD',None);password=None

        print('\nWave A R17 M2.5-M2.10 finished:',receipt['status'])
        print('R6 source modified:',receipt.get('source_modified'))
        print('R12 diagnostic retained:',receipt.get('r12_diagnostic_retained'))
        print('R13 diagnostic retained:',receipt.get('r13_diagnostic_retained'))
        print('R14 diagnostic retained:',receipt.get('r14_diagnostic_retained'))
        print('R16 diagnostic retained:',receipt.get('r16_diagnostic_retained'))
        print('Compiler clone retained:',compiler_db if receipt.get('compiler_clone_exists_at_exit') else 'NO')
        print('Final clone retained:',final_db if receipt.get('final_clone_exists_at_exit') else 'NO')
        print('Last stage:',receipt.get('last_stage'))
        if result_hash is not None:
            print('Results:',result_zip);print('SHA-256:',result_hash)
        else:
            print('Results: NOT CREATED')
        if receipt['status']!='PASS':
            print('Failure:',receipt.get('error') or receipt.get('result_packaging_error'))
        print('Do not rerun R12, R13, R14, R15, or R16. Return the generated R17 result ZIP and sidecar.')
    return exit_code

if __name__=='__main__':raise SystemExit(main())
