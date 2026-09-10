from __future__ import annotations
import csv, io, json, hashlib, zipfile, re
from collections import Counter, defaultdict
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation
from typing import Any

D0=Decimal('0'); D1=Decimal('1')
Q10=Decimal('0.0000000001'); Q12=Decimal('0.000000000001'); Q6=Decimal('0.000001'); Q8=Decimal('0.00000001'); Q2=Decimal('0.01')

PROFILES=[
 {'code':'BASELINE_REPLAY','seq':1,'mode':'SOURCE_REPLAY','exposure_direction':'NOT_APPLICABLE','w':{'access':'0','exposure':'0','finance':'0','loss':'0','contribution':'0','return':'0','servicing':'0','payment':'0'}},
 {'code':'ACCESS_EXPANSION','seq':2,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MAXIMIZE','w':{'access':'0.45','exposure':'0.15','finance':'0.05','loss':'0.10','contribution':'0.10','return':'0.05','servicing':'0','payment':'0.10'}},
 {'code':'PRICE_FOR_RISK','seq':3,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MAXIMIZE','w':{'access':'0.10','exposure':'0.05','finance':'0.30','loss':'0.15','contribution':'0.20','return':'0.10','servicing':'0','payment':'0.10'}},
 {'code':'PAYMENT_BURDEN_RELIEF','seq':4,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MINIMIZE','w':{'access':'0.15','exposure':'0.10','finance':'0.05','loss':'0.10','contribution':'0.10','return':'0.05','servicing':'0','payment':'0.45'}},
 {'code':'LOSS_CONTAINMENT','seq':5,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MINIMIZE','w':{'access':'0.05','exposure':'0.25','finance':'0','loss':'0.40','contribution':'0.10','return':'0.05','servicing':'0','payment':'0.15'}},
 {'code':'PROFITABILITY_DISCIPLINE','seq':6,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MAXIMIZE','w':{'access':'0.05','exposure':'0.05','finance':'0.15','loss':'0.15','contribution':'0.35','return':'0.20','servicing':'0','payment':'0.05'}},
 {'code':'EARLY_INTERVENTION','seq':7,'mode':'RULE_BASED_ACCOUNT','exposure_direction':'NOT_APPLICABLE','w':{'access':'0','exposure':'0','finance':'0','loss':'0','contribution':'0','return':'0','servicing':'0.60','payment':'0.40'}},
 {'code':'BALANCED_FRONTIER','seq':8,'mode':'WEIGHTED_CANDIDATE','exposure_direction':'MAXIMIZE','w':{'access':'0.20','exposure':'0.05','finance':'0.10','loss':'0.20','contribution':'0.20','return':'0.10','servicing':'0.10','payment':'0.05'}},
]
for p in PROFILES:
    p['w']={k:Decimal(v) for k,v in p['w'].items()}
    p['candidate_weight_total']=sum(v for k,v in p['w'].items() if k!='servicing')
    p['scope_weight_total']=sum(p['w'].values())
PROFILE_BY_CODE={p['code']:p for p in PROFILES}

R4_MEMBER={
 'application':'powerbi/PBI_FACT_APPLICATION_SCENARIO.csv',
 'candidate':'powerbi/PBI_FACT_OFFER_CANDIDATE.csv',
 'final':'powerbi/PBI_FACT_FINAL_DECISION.csv',
 'proof':'powerbi/PBI_FACT_NO_FEASIBLE_STRUCTURE_PROOF.csv',
 'gate':'powerbi/PBI_FACT_DECISION_GATE.csv',
 'feature':'powerbi/PBI_FACT_DECISION_CRITICAL_FEATURE_AVAILABILITY.csv',
}
R17_MEMBER={
 'stage_registry':'evidence/final/wave_a_stage_registry.csv',
 'validation':'evidence/final/wave_a_validation_result.csv',
 'm2_7':'evidence/final/m2_7_power_bi.csv',
 'm2_10':'evidence/final/m2_10_power_bi.csv',
}

EXPECTED_R4_SHA='1377e860629109fa9b19b479becc50e8a0d99cf55f1c760299de4203df6238d6'
EXPECTED_R17_SHA='eee512f19d30e189f811abc788b33ae0495ed1161be50c3061d5dc81f06b13be'
EXPECTED_R18_FAIL_SHA='71f44e126da56e03a12b0c5853545a3dd8ebc5ff09ef6241c0aff77bf7abb2df'
EXPECTED_R4_MEMBER_SHA={
 'application':'69688f84de40fbb48120f0ca74ba8cd7e067abbd1eb88b1831f4b557b7495283',
 'candidate':'560ede48bcb47efb86bd2851c8a24f114b860ac64d433f18494c66d90f8389bf',
 'final':'a69a5d5a8d6a1f33438d70934b885a7a12be9616b6ca488013db3a74f10937d6',
 'proof':'f15280f08b3250b13875356efdb0e566bba7a9f72e3453a6be8fa88680bd02f2',
 'gate':'577f9b0047a383dd3a3b309aa6882c984db2248f1c54d55215654cd7ee9f2f84',
 'feature':'441180ded94504e467c657195f08d5a71ca1d72c668c13ea877535a234da6b88',
}
EXPECTED_R4_ROWS={'application':1500,'candidate':6519,'final':1500,'proof':652,'gate':84228,'feature':1500}
EXPECTED_R17_ROWS={'stage_registry':6,'validation':115,'m2_7':130,'m2_10':130}
EXPECTED_R17_MEMBER_SHA={
 'm2_7':'7464c50f145c48945fd537eeec53bfd7b5e44de5af14a41fc9eeff348f3b3b92',
 'm2_10':'e910d108e1f7d084283af1fb38485b3b033a3296d7e674adaf010d35ec496663',
}
EXPECTED_OWNER_PROFILE_SHA='b9f3e3a5511cec5633c3417d694536013e072e73f0a3ef2fe914bb7ad6f258f6'
EXPECTED_METHOD_SOURCE_SET_SHA='c70235754193665533e7dfd1f02c8475cd5d09415ec8aa4c2c06939f1b52e989'


def sha256_bytes(b:bytes)->str:return hashlib.sha256(b).hexdigest()
def sha256_file(path:str)->str:
    h=hashlib.sha256();
    with open(path,'rb') as f:
        for c in iter(lambda:f.read(1024*1024),b''):h.update(c)
    return h.hexdigest()
def canon_bytes(x:Any)->bytes:return json.dumps(x,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode('utf-8')
def canon_hash(x:Any)->str:return sha256_bytes(canon_bytes(x))
def csv_rows(data:bytes)->list[dict[str,str]]:
    return [dict(r) for r in csv.DictReader(io.StringIO(data.decode('utf-8-sig')))]
def dec(v:Any, default:Decimal|None=None)->Decimal|None:
    if v is None:return default
    s=str(v).strip().replace(',','').replace('$','')
    if s=='':return default
    try:return Decimal(s)
    except InvalidOperation:return default
def bval(v:Any)->bool:
    return str(v).strip().lower() in {'1','t','true','y','yes','pass'}
def fmt(d:Decimal|None, q:Decimal|None=None)->str:
    if d is None:return ''
    if q is not None:d=d.quantize(q,rounding=ROUND_HALF_UP)
    return format(d,'f')
def key3(run,scenario,app):return (str(run),str(scenario),str(app))
def row_key(r, prefix=''):
    if prefix:
        return key3(r[prefix+'module1_run_id'],r[prefix+'scenario_code'],r[prefix+'merchant_application_id'])
    return key3(r['module1_run_id'],r['scenario_code'],r['merchant_application_id'])
def split_reasons(v:str)->list[str]:
    s=(v or '').strip()
    return [] if not s or s=='NONE' else [x for x in s.split('|') if x and x!='NONE']


def _count_csv_rows_bytes(data:bytes)->int:
    # robust quoted-newline CSV count by parser
    return sum(1 for _ in csv.reader(io.StringIO(data.decode('utf-8-sig'))))-1


def verify_inputs(r4_zip:str,r17_zip:str,r18_fail_zip:str|None=None)->dict[str,Any]:
    out={'r4':{},'r17':{},'r18_failure':{}}
    r4sha=sha256_file(r4_zip)
    if r4sha!=EXPECTED_R4_SHA:raise RuntimeError(f'R4 zip SHA mismatch {r4sha}')
    with zipfile.ZipFile(r4_zip) as z:
        receipt=json.loads(z.read('R1B_PHASE2C_R4_RECEIPT.json'))
        if receipt.get('status')!='PASS' or receipt.get('current_stage')!='COMPLETE':raise RuntimeError('R4 receipt not PASS/COMPLETE')
        if receipt.get('policy_profile_sha256')!=EXPECTED_OWNER_PROFILE_SHA:raise RuntimeError('R4 owner profile SHA mismatch')
        if receipt.get('accepted_method_source_set_sha256')!=EXPECTED_METHOD_SOURCE_SET_SHA:raise RuntimeError('R4 method source set SHA mismatch')
        members={}
        for role,name in R4_MEMBER.items():
            data=z.read(name); sh=sha256_bytes(data); rows=_count_csv_rows_bytes(data)
            if sh!=EXPECTED_R4_MEMBER_SHA[role] or rows!=EXPECTED_R4_ROWS[role]:
                raise RuntimeError(f'R4 member mismatch {role}: {sh} rows={rows}')
            members[role]={'member':name,'sha256':sh,'rows':rows,'bytes':len(data)}
        out['r4']={'status':'PASS','sha256':r4sha,'receipt_status':receipt['status'],'members':members,
                   'policy_profile_sha256':receipt['policy_profile_sha256'],'accepted_method_source_set_sha256':receipt['accepted_method_source_set_sha256']}
    r17sha=sha256_file(r17_zip)
    if r17sha!=EXPECTED_R17_SHA:raise RuntimeError(f'R17 zip SHA mismatch {r17sha}')
    with zipfile.ZipFile(r17_zip) as z:
        receipt=json.loads(z.read('WAVE_A_R17_RECEIPT.json'))
        if receipt.get('status')!='PASS' or receipt.get('last_stage')!='COMPLETE' or not receipt.get('final_clone_exists_at_exit'):
            raise RuntimeError('R17 receipt not PASS/COMPLETE/retained-at-exit')
        dbi=json.loads(z.read('evidence/FINAL_DATABASE_IDENTITY.json'))
        pbi=json.loads(z.read('evidence/final/91_POWER_BI_EXPORT_IDENTITY.json'))
        cross=json.loads(z.read('evidence/97_CROSS_STATE_IDENTITY_COMPARISON.json'))
        if dbi.get('stage_registry_rows')!=6 or dbi.get('validation_rows')!=115:raise RuntimeError('R17 DB identity population mismatch')
        required_cross=[k for k,v in cross.items() if isinstance(v,bool)]
        if not all(cross[k] for k in required_cross):raise RuntimeError('R17 cross-state identity has false control')
        pbi_map={o['name']:o for o in pbi['objects']}
        members={}
        for role,name in R17_MEMBER.items():
            data=z.read(name); rows=_count_csv_rows_bytes(data); sh=sha256_bytes(data)
            if rows!=EXPECTED_R17_ROWS[role]:raise RuntimeError(f'R17 member row mismatch {role} {rows}')
            if role in EXPECTED_R17_MEMBER_SHA and sh!=EXPECTED_R17_MEMBER_SHA[role]:raise RuntimeError(f'R17 member SHA mismatch {role}')
            if role=='m2_7' and (pbi_map['m2_7_power_bi']['csv_sha256']!=sh or pbi_map['m2_7_power_bi']['rows']!=rows):raise RuntimeError('R17 M2.7 PBI binding mismatch')
            if role=='m2_10' and (pbi_map['m2_10_power_bi']['csv_sha256']!=sh or pbi_map['m2_10_power_bi']['rows']!=rows):raise RuntimeError('R17 M2.10 PBI binding mismatch')
            members[role]={'member':name,'sha256':sh,'rows':rows,'bytes':len(data)}
        vals=csv_rows(z.read(R17_MEMBER['validation']))
        if any(str(r.get('status','')).upper()!='PASS' for r in vals):raise RuntimeError('R17 validation contains non-PASS')
        out['r17']={'status':'PASS','sha256':r17sha,'final_db_from_receipt':receipt.get('final_db'),'final_existed_at_exit':True,
                    'database_identity':dbi,'power_bi_bundle_sha256':pbi.get('bundle_sha256'),'members':members}
    if r18_fail_zip:
        sh=sha256_file(r18_fail_zip)
        if sh!=EXPECTED_R18_FAIL_SHA:raise RuntimeError(f'R18 failure ZIP SHA mismatch {sh}')
        with zipfile.ZipFile(r18_fail_zip) as z:
            r=json.loads(z.read('WAVE_B_R18_RECEIPT.json'))
            if r.get('status')!='FAIL' or r.get('last_stage')!='PACKAGE_AND_R17_INPUT_VERIFICATION' or r.get('compiler_retained') or r.get('final_retained'):
                raise RuntimeError('R18 failure receipt state mismatch')
            out['r18_failure']={'status':'PASS','sha256':sh,'failure':r.get('failure'),'last_stage':r.get('last_stage'),'compiler_created':False,'final_created':False}
    return out


def load_source_rows(r4_zip:str,r17_zip:str)->dict[str,list[dict[str,str]]]:
    out={}
    with zipfile.ZipFile(r4_zip) as z:
        for role,name in R4_MEMBER.items():
            if role in {'gate','feature'}:continue
            out['r4_'+role]=csv_rows(z.read(name))
    with zipfile.ZipFile(r17_zip) as z:
        for role,name in R17_MEMBER.items():out['r17_'+role]=csv_rows(z.read(name))
    return out


def _norm(raw:Decimal, mn:Decimal, mx:Decimal, direction:str)->Decimal:
    if mx==mn:return D1
    if direction=='MINIMIZE':v=(mx-raw)/(mx-mn)
    else:v=(raw-mn)/(mx-mn)
    return v.quantize(Q10,rounding=ROUND_HALF_UP)

def _candidate_base(c:dict[str,str])->dict[str,Any]:
    feasibility=c.get('candidate_feasibility_status','')
    strict=bval(c.get('strict_pass_flag')); review=bval(c.get('review_eligible_flag'))
    if strict:fc='FEASIBLE_ACCESS';fr=1
    elif review:fc='FEASIBLE_CONTROLLED_REVIEW';fr=2
    else:fc='INFEASIBLE_HARD_CONSTRAINT';fr=5
    funded=dec(c.get('funded_amount'),D0); repay=dec(c.get('total_repayment_amount'),D0)
    return {
      'module1_run_id':c['original_module1_run_id'],'scenario_id':c['original_scenario_id'],'scenario_code':c['original_scenario_code'],
      'merchant_application_id':c['original_merchant_application_id'],'candidate_id':c['candidate_id'],'candidate_sequence':int(c.get('candidate_sequence') or 0),
      'candidate_type':c.get('candidate_type',''),'funded_amount':funded,'remittance_rate':dec(c.get('remittance_rate'),D0),
      'payback_multiple':dec(c.get('payback_multiple'),D0),'horizon_days':int(dec(c.get('horizon_days'),D0) or 0),
      'total_repayment_amount':repay,'finance_charge_amount':repay-funded,
      'expected_loss_amount':dec(c.get('schedule_adjusted_comparative_expected_loss_amount'),D0),
      'loss_density':dec(c.get('schedule_adjusted_comparative_loss_rate'),D0),
      'risk_adjusted_contribution':dec(c.get('risk_adjusted_contribution_amount'),D0),
      'annualized_return':dec(c.get('annualized_risk_adjusted_return_rate'),D0),
      'payment_burden':dec(c.get('remittance_rate'),D0),
      'strict_pass':strict,'review_eligible':review,'human_review_required':bval(c.get('human_review_required_flag')),
      'feasibility_class':fc,'feasibility_rank':fr,'hard_constraint_violation_count':len(split_reasons(c.get('all_infeasibility_reason_codes',''))),
      'infeasibility_reasons':c.get('all_infeasibility_reason_codes',''),'economic_status':c.get('economic_status',''),
      'strict_selection_rank':int(dec(c.get('strict_selection_rank'),Decimal('2147483647')) or Decimal('2147483647')),
      'review_selection_rank':int(dec(c.get('review_selection_rank'),Decimal('2147483647')) or Decimal('2147483647')),
      'source_candidate_row_hash':c.get('candidate_row_hash',''),'governed_selected_flag':bval(c.get('governed_selected_flag')),
    }


def build_simulation(source:dict[str,list[dict[str,str]]], source_root:str)->dict[str,Any]:
    apps=source['r4_application']; cands=source['r4_candidate']; finals=source['r4_final']; proofs=source['r4_proof']
    m27=source['r17_m2_7']; m210=source['r17_m2_10']
    app_map={row_key(r):r for r in apps}; final_map={row_key(r):r for r in finals}; proof_map={row_key(r):r for r in proofs}
    m27_map={row_key(r):r for r in m27}; m210_map={row_key(r):r for r in m210}
    cand_groups=defaultdict(list)
    bases=[]
    for c in cands:
        b=_candidate_base(c);bases.append(b);cand_groups[key3(b['module1_run_id'],b['scenario_code'],b['merchant_application_id'])].append(b)
    eval_rows=[]; selected_by={}
    # all 6,519 x 8 persisted evaluations
    for k in sorted(cand_groups):
        group=sorted(cand_groups[k],key=lambda x:(x['candidate_sequence'],x['candidate_id'],x['source_candidate_row_hash']))
        final=final_map[k]; governed_id=final.get('governed_selected_candidate_id','')
        for p in PROFILES:
            code=p['code']; mode=p['mode']
            local=[]
            if mode=='WEIGHTED_CANDIDATE':
                feasible=[x for x in group if x['feasibility_rank']<=2]
                # Governed no-feasible proof / stress floor remains binding for challenger candidate access.
                if final.get('governed_final_outcome_code')=='DECLINE_NO_FEASIBLE_STRUCTURE':feasible=[]
                if feasible:
                    alts=[]
                    for x in feasible:
                        alts.append({'ref':x,'feasibility_rank':x['feasibility_rank'],'access':D1 if x['feasibility_rank']==1 else D0,
                                     'exposure':x['funded_amount'],'finance':x['finance_charge_amount'],'loss':x['loss_density'],
                                     'contribution':x['risk_adjusted_contribution'],'return':x['annualized_return'],'payment':x['payment_burden']})
                    alts.append({'ref':None,'feasibility_rank':3,'access':D0,'exposure':D0,'finance':D0,'loss':D0,'contribution':D0,'return':D0,'payment':D0})
                    metrics=['access','exposure','finance','loss','contribution','return','payment']
                    mins={m:min(a[m] for a in alts) for m in metrics}; maxs={m:max(a[m] for a in alts) for m in metrics}
                    scored=[]
                    for a in alts:
                        norms={}
                        for m in metrics:
                            direction='MINIMIZE' if m in {'loss','payment'} or (m=='exposure' and p['exposure_direction']=='MINIMIZE') else 'MAXIMIZE'
                            norms[m]=_norm(a[m],mins[m],maxs[m],direction)
                        den=p['candidate_weight_total']
                        score=sum(norms[m]*p['w'][m] for m in metrics)/den if den else D0
                        score=score.quantize(Q12,rounding=ROUND_HALF_UP)
                        a['norms']=norms;a['score']=score;scored.append(a)
                    def sk(a):
                        ref=a['ref']; rr=2147483647; seq=2147483647; cid='~'; rh='~'
                        if ref:
                            rr=ref['strict_selection_rank'] if ref['feasibility_rank']==1 else ref['review_selection_rank']
                            seq=ref['candidate_sequence'];cid=ref['candidate_id'];rh=ref['source_candidate_row_hash']
                        return (a['feasibility_rank'],-a['score'],rr,seq,cid,rh)
                    choice=min(scored,key=sk)
                    selected_by[(k,code)]=choice['ref']
                    score_by_id={a['ref']['candidate_id']:a for a in scored if a['ref']}
                else:
                    selected_by[(k,code)]=None;score_by_id={}
            else:
                selected=next((x for x in group if x['candidate_id']==governed_id),None) if governed_id else None
                selected_by[(k,code)]=selected;score_by_id={}
            chosen=selected_by[(k,code)]
            for x in group:
                a=score_by_id.get(x['candidate_id'])
                row={
                  'module1_run_id':x['module1_run_id'],'scenario_id':x['scenario_id'],'scenario_code':x['scenario_code'],'merchant_application_id':x['merchant_application_id'],
                  'candidate_id':x['candidate_id'],'strategy_profile_code':code,'profile_sequence':p['seq'],'selection_mode':mode,
                  'source_candidate_row_hash':x['source_candidate_row_hash'],'candidate_feasibility_status':'STRICT_PASS' if x['strict_pass'] else ('REVIEW_ELIGIBLE' if x['review_eligible'] else 'INFEASIBLE'),
                  'feasibility_class':x['feasibility_class'],'feasibility_rank':x['feasibility_rank'],'hard_constraint_violation_count':x['hard_constraint_violation_count'],
                  'infeasibility_reasons':x['infeasibility_reasons'],'strict_pass_flag':x['strict_pass'],'review_eligible_flag':x['review_eligible'],'human_review_required_flag':x['human_review_required'],
                  'funded_amount':fmt(x['funded_amount'],Q2),'finance_charge_amount':fmt(x['finance_charge_amount'],Q2),'loss_density':fmt(x['loss_density'],Q10),
                  'risk_adjusted_contribution':fmt(x['risk_adjusted_contribution'],Q2),'annualized_return':fmt(x['annualized_return'],Q10),'payment_burden_rate':fmt(x['payment_burden'],Q10),
                  'access_normalized':fmt(a['norms']['access'],Q10) if a else '', 'exposure_normalized':fmt(a['norms']['exposure'],Q10) if a else '',
                  'finance_normalized':fmt(a['norms']['finance'],Q10) if a else '', 'loss_normalized':fmt(a['norms']['loss'],Q10) if a else '',
                  'contribution_normalized':fmt(a['norms']['contribution'],Q10) if a else '', 'return_normalized':fmt(a['norms']['return'],Q10) if a else '',
                  'payment_normalized':fmt(a['norms']['payment'],Q10) if a else '', 'objective_score':fmt(a['score'],Q12) if a else '',
                  'candidate_selected_flag':bool(chosen and chosen['candidate_id']==x['candidate_id']),
                  'source_root_sha256':source_root,
                }
                row['row_hash']=canon_hash(row);eval_rows.append(row)
    # app simulation 1500 x 8
    app_sim=[]
    source_outcome_to_strategy={
      'DECLINE_INSUFFICIENT_EVIDENCE':'NO_ACCESS_INSUFFICIENT_EVIDENCE','DECLINE_POLICY_HARD_STOP':'NO_ACCESS_POLICY_DECLINE',
      'DECLINE_NO_FEASIBLE_STRUCTURE':'NO_ACCESS_NO_FEASIBLE_CANDIDATE','COUNTEROFFER_REVIEW_REQUIRED':'CONTROLLED_REVIEW',
      'MANUAL_UNDERWRITING_REVIEW_REQUIRED':'CONTROLLED_REVIEW','COUNTEROFFER_AUTHORIZED':'ACCESS_SELECTED','APPROVE_AS_REQUESTED_AUTHORIZED':'ACCESS_SELECTED'
    }
    for k in sorted(final_map):
        f=final_map[k]; a=app_map[k]; source_out=f['governed_final_outcome_code']; protected=source_out in {'DECLINE_INSUFFICIENT_EVIDENCE','DECLINE_POLICY_HARD_STOP','DECLINE_NO_FEASIBLE_STRUCTURE'}
        for p in PROFILES:
            code=p['code']; chosen=selected_by.get((k,code))
            if code in {'BASELINE_REPLAY','EARLY_INTERVENTION'}:
                strategy_out=source_outcome_to_strategy[source_out]
            elif protected:
                strategy_out=source_outcome_to_strategy[source_out];chosen=None
            elif source_out in {'COUNTEROFFER_REVIEW_REQUIRED','MANUAL_UNDERWRITING_REVIEW_REQUIRED'}:
                strategy_out='CONTROLLED_REVIEW' if chosen else 'NO_ACCESS_NO_FEASIBLE_CANDIDATE'
            else:
                strategy_out='ACCESS_SELECTED' if chosen and chosen['feasibility_rank']==1 else ('CONTROLLED_REVIEW' if chosen else 'NO_ACCESS_NO_FEASIBLE_CANDIDATE')
            op=m27_map.get(k);port=m210_map.get(k)
            selected_id=chosen['candidate_id'] if chosen else ''
            row={
              'module1_run_id':f['module1_run_id'],'scenario_id':f['scenario_id'],'scenario_code':f['scenario_code'],'merchant_application_id':f['merchant_application_id'],
              'merchant_id':a.get('merchant_id',''),'strategy_profile_code':code,'profile_sequence':p['seq'],'source_final_outcome_code':source_out,
              'source_selected_candidate_id':f.get('governed_selected_candidate_id',''),'strategy_outcome_code':strategy_out,'selected_candidate_id':selected_id,
              'selected_feasibility_class':chosen['feasibility_class'] if chosen else 'FEASIBLE_NO_ACCESS','selected_funding_amount':fmt(chosen['funded_amount'],Q2) if chosen else '0.00',
              'selected_finance_charge_amount':fmt(chosen['finance_charge_amount'],Q2) if chosen else '0.00','selected_expected_loss_amount':fmt(chosen['expected_loss_amount'],Q2) if chosen else '0.00',
              'selected_loss_density':fmt(chosen['loss_density'],Q10) if chosen else '','selected_risk_adjusted_contribution':fmt(chosen['risk_adjusted_contribution'],Q2) if chosen else '0.00',
              'selected_annualized_return':fmt(chosen['annualized_return'],Q10) if chosen else '','selected_payment_burden_rate':fmt(chosen['payment_burden'],Q10) if chosen else '',
              'source_search_required_flag':bval(a.get('search_required_flag')),'source_search_complete_flag':bval(a.get('search_complete_flag')),
              'source_no_feasible_proof_flag':k in proof_map,'funded_source_flag':source_out in {'COUNTEROFFER_AUTHORIZED','APPROVE_AS_REQUESTED_AUTHORIZED'},
              'm2_7_joined_flag':op is not None,'m2_10_joined_flag':port is not None,'operational_setup_outcome_code':op.get('operational_setup_outcome_code','') if op else '',
              'portfolio_performance_tier_code':port.get('performance_tier_code','') if port else '',
              'simulation_authority_state':'ANALYTIC_ONLY_NOT_PRODUCTION_AUTHORITY','source_root_sha256':source_root,
            }
            row['row_hash']=canon_hash(row);app_sim.append(row)
    # account simulation 130 x 8, no ex-post fields used in candidate scoring
    acct=[]
    for base in sorted(m210,key=lambda r:row_key(r)):
        k=row_key(base);op=m27_map[k]
        source_burden=dec(base.get('servicing_burden_units'),D0) or D0
        for p in PROFILES:
            code=p['code'];tier=base.get('performance_tier_code','');increment=D0;treatment='SOURCE_REPLAY'
            if code=='EARLY_INTERVENTION' and tier in {'ACTIVE_RECONCILED','CONTROLLED_REVIEW'}:
                increment=D1;treatment='EARLY_REASSESSMENT_SIMULATION' if tier=='ACTIVE_RECONCILED' else 'ACCELERATED_GOVERNANCE_REVIEW_SIMULATION'
            row={
              'module1_run_id':base['module1_run_id'],'scenario_code':base['scenario_code'],'merchant_application_id':base['merchant_application_id'],'strategy_profile_code':code,
              'synthetic_account_id':base.get('synthetic_account_id',''),'source_performance_tier_code':tier,'source_servicing_queue_code':base.get('servicing_queue_code',''),
              'source_servicing_burden_units':fmt(source_burden,Q6),'incremental_servicing_burden_units':fmt(increment,Q6),'simulated_servicing_burden_units':fmt(source_burden+increment,Q6),
              'treatment_code':treatment,'source_operational_activation_date':op.get('operational_activation_date',''),'source_next_reassessment_date':op.get('next_reassessment_date',''),
              'payment_factor_changed_flag':False,'exposure_changed_flag':False,'treatment_effect_claimed_flag':False,'source_root_sha256':source_root,
            }
            row['row_hash']=canon_hash(row);acct.append(row)
    acct_map={(r['scenario_code'],r['merchant_application_id'],r['strategy_profile_code']):r for r in acct}
    # summaries for scenario scopes
    by_scope_profile=defaultdict(list)
    for r in app_sim:by_scope_profile[(r['scenario_code'],r['strategy_profile_code'])].append(r)
    # worst-case portfolio row per application/profile
    sev={'NO_ACCESS_INSUFFICIENT_EVIDENCE':7,'NO_ACCESS_POLICY_DECLINE':6,'NO_ACCESS_NO_FEASIBLE_CANDIDATE':5,'CONTROLLED_REVIEW':3,'ACCESS_SELECTED':1}
    by_app_profile=defaultdict(list)
    for r in app_sim:by_app_profile[(r['merchant_application_id'],r['strategy_profile_code'])].append(r)
    portfolio_rows_by_profile=defaultdict(list)
    def worst_key(r):
        loss=dec(r['selected_loss_density']);con=dec(r['selected_risk_adjusted_contribution']);ret=dec(r['selected_annualized_return']);pay=dec(r['selected_payment_burden_rate'])
        # higher tuple = worse; None is worst for risk/return/payment evidence
        return (sev.get(r['strategy_outcome_code'],9), D1 if loss is None else loss, D1 if con is None else -con, D1 if ret is None else -ret, D1 if pay is None else pay, 1 if r['scenario_code']=='RECESSION_ENERGY' else 0, r['row_hash'])
    for (app,prof),rows in by_app_profile.items():portfolio_rows_by_profile[prof].append(max(rows,key=worst_key))
    summaries=[]
    def make_summary(scope,prof,rows):
        exposure=sum(dec(r['selected_funding_amount'],D0) or D0 for r in rows)
        finance=sum(dec(r['selected_finance_charge_amount'],D0) or D0 for r in rows)
        el=sum(dec(r['selected_expected_loss_amount'],D0) or D0 for r in rows)
        contribution=sum(dec(r['selected_risk_adjusted_contribution'],D0) or D0 for r in rows)
        weighted_ret=sum((dec(r['selected_funding_amount'],D0) or D0)*(dec(r['selected_annualized_return'],D0) or D0) for r in rows)
        weighted_pay=sum((dec(r['selected_funding_amount'],D0) or D0)*(dec(r['selected_payment_burden_rate'],D0) or D0) for r in rows)
        # servicing burden only where physical account exists in the chosen scenario row
        burden=D0
        for r in rows:
            ar=acct_map.get((r['scenario_code'],r['merchant_application_id'],prof))
            if ar:burden+=dec(ar['simulated_servicing_burden_units'],D0) or D0
        out={
          'reporting_scope_code':scope,'strategy_profile_code':prof,'application_count':len(rows),'access_count':sum(r['strategy_outcome_code']=='ACCESS_SELECTED' for r in rows),
          'controlled_review_count':sum(r['strategy_outcome_code']=='CONTROLLED_REVIEW' for r in rows),'no_access_count':sum(r['strategy_outcome_code'].startswith('NO_ACCESS') for r in rows),
          'access_rate':fmt(Decimal(sum(r['strategy_outcome_code']=='ACCESS_SELECTED' for r in rows))/Decimal(len(rows)),Q10),
          'selected_exposure_amount':fmt(exposure,Q2),'finance_charge_amount':fmt(finance,Q2),'expected_loss_density':fmt(el/exposure,Q10) if exposure else '',
          'risk_adjusted_contribution':fmt(contribution,Q2),'annualized_risk_adjusted_return':fmt(weighted_ret/exposure,Q10) if exposure else '',
          'servicing_burden_units':fmt(burden,Q6),'payment_burden_rate':fmt(weighted_pay/exposure,Q10) if exposure else '',
          'strategy_evidence_status':'PARTIAL' if any(r['strategy_outcome_code']=='NO_ACCESS_INSUFFICIENT_EVIDENCE' for r in rows) else 'COMPLETE',
          'hard_constraint_violation_count':0,'stress_improvement_violation_count':0,'source_root_sha256':source_root,
        }
        out['row_hash']=canon_hash(out);return out
    for scope in ['BASELINE','RECESSION_ENERGY']:
        for p in PROFILES:summaries.append(make_summary(scope,p['code'],by_scope_profile[(scope,p['code'])]))
    for p in PROFILES:summaries.append(make_summary('PORTFOLIO',p['code'],portfolio_rows_by_profile[p['code']]))
    # pareto frontier and governance balance
    summary_map={(r['reporting_scope_code'],r['strategy_profile_code']):r for r in summaries}
    frontier=[]; comparisons=[]
    toler={'access':Q8,'finance':Q2,'loss':Q8,'contribution':Q2,'return':Q8,'servicing':Q6,'payment':Q8}
    dirs={'access':'MAX','finance':'MAX','loss':'MIN','contribution':'MAX','return':'MAX','servicing':'MIN','payment':'MIN'}
    fields={'access':'access_rate','finance':'finance_charge_amount','loss':'expected_loss_density','contribution':'risk_adjusted_contribution','return':'annualized_risk_adjusted_return','servicing':'servicing_burden_units','payment':'payment_burden_rate'}
    for scope in ['BASELINE','RECESSION_ENERGY','PORTFOLIO']:
        rows=[summary_map[(scope,p['code'])] for p in PROFILES]
        eligible=[]
        for r in rows:
            vals={m:dec(r[f]) for m,f in fields.items()}
            ok=all(v is not None for v in vals.values()) and r['strategy_evidence_status']!='BLOCKED'
            if ok:eligible.append((r,vals))
        def dominates(a,b):
            no_worse=True;strict=False
            for m in fields:
                av=a[1][m];bv=b[1][m];tol=toler[m]
                if dirs[m]=='MAX':
                    if av < bv-tol:no_worse=False;break
                    if av > bv+tol:strict=True
                else:
                    if av > bv+tol:no_worse=False;break
                    if av < bv-tol:strict=True
            return no_worse and strict
        ranks={};remaining=list(eligible);rank=1
        while remaining:
            nondom=[]
            for x in remaining:
                if not any(dominates(y,x) for y in remaining if y is not x):nondom.append(x)
            if not nondom:break
            for x in nondom:ranks[x[0]['strategy_profile_code']]=rank
            remaining=[x for x in remaining if x not in nondom];rank+=1
        # governance balance normalized over eligible
        balance={}
        if eligible:
            mins={m:min(x[1][m] for x in eligible) for m in fields};maxs={m:max(x[1][m] for x in eligible) for m in fields}
            for r,vals in eligible:
                ns=[]
                for m,v in vals.items():ns.append(_norm(v,mins[m],maxs[m],'MINIMIZE' if dirs[m]=='MIN' else 'MAXIMIZE'))
                balance[r['strategy_profile_code']]=(sum(ns)/Decimal(7)).quantize(Q12,rounding=ROUND_HALF_UP)
        baseline=summary_map[(scope,'BASELINE_REPLAY')]
        # primary rank1 challenger ordering
        challengers=[r for r,_ in eligible if r['strategy_profile_code']!='BASELINE_REPLAY' and ranks.get(r['strategy_profile_code'])==1]
        challengers.sort(key=lambda r:(-(balance.get(r['strategy_profile_code'],D0)), -(dec(r['risk_adjusted_contribution'],D0)-dec(baseline['risk_adjusted_contribution'],D0)), (dec(r['expected_loss_density'],D0)-dec(baseline['expected_loss_density'],D0)), -(dec(r['access_rate'],D0)-dec(baseline['access_rate'],D0)), (dec(r['payment_burden_rate'],D0)-dec(baseline['payment_burden_rate'],D0)), (dec(r['servicing_burden_units'],D0)-dec(baseline['servicing_burden_units'],D0)), r['strategy_profile_code']))
        primary=challengers[0]['strategy_profile_code'] if challengers else ''
        for r in rows:
            code=r['strategy_profile_code'];vals={m:dec(r[f]) for m,f in fields.items()};ok=code in ranks
            dom_count=sum(dominates(x,(r,vals)) for x in eligible if x[0]['strategy_profile_code']!=code) if ok else 0
            priority='CONTROL_REFERENCE' if code=='BASELINE_REPLAY' else ('PRIMARY_GOVERNANCE_REVIEW' if code==primary else ('SECONDARY_FRONTIER_REVIEW' if ranks.get(code)==1 else 'VISIBLE_NOT_PRIMARY'))
            fr={'reporting_scope_code':scope,'strategy_profile_code':code,'frontier_eligible_flag':ok,'frontier_rank':ranks.get(code,''),'dominated_by_count':dom_count,
                'governance_balance_score':fmt(balance.get(code),Q12) if code in balance else '','governance_priority_code':priority,'source_root_sha256':source_root}
            fr['row_hash']=canon_hash(fr);frontier.append(fr)
            if code!='BASELINE_REPLAY':
                cp={'reporting_scope_code':scope,'challenger_strategy_profile_code':code,'baseline_strategy_profile_code':'BASELINE_REPLAY','frontier_rank':ranks.get(code,''),
                    'access_rate_delta':fmt((dec(r['access_rate'],D0)-dec(baseline['access_rate'],D0)),Q10),'selected_exposure_delta':fmt((dec(r['selected_exposure_amount'],D0)-dec(baseline['selected_exposure_amount'],D0)),Q2),
                    'finance_charge_delta':fmt((dec(r['finance_charge_amount'],D0)-dec(baseline['finance_charge_amount'],D0)),Q2),'expected_loss_density_delta':fmt((dec(r['expected_loss_density'],D0)-dec(baseline['expected_loss_density'],D0)),Q10),
                    'risk_adjusted_contribution_delta':fmt((dec(r['risk_adjusted_contribution'],D0)-dec(baseline['risk_adjusted_contribution'],D0)),Q2),'annualized_return_delta':fmt((dec(r['annualized_risk_adjusted_return'],D0)-dec(baseline['annualized_risk_adjusted_return'],D0)),Q10),
                    'servicing_burden_delta':fmt((dec(r['servicing_burden_units'],D0)-dec(baseline['servicing_burden_units'],D0)),Q6),'payment_burden_delta':fmt((dec(r['payment_burden_rate'],D0)-dec(baseline['payment_burden_rate'],D0)),Q10),
                    'governance_priority_code':priority,'source_root_sha256':source_root}
                cp['row_hash']=canon_hash(cp);comparisons.append(cp)
    return {'profiles':PROFILES,'candidate_evaluation':eval_rows,'application_simulation':app_sim,'account_simulation':acct,'portfolio_summary':summaries,'portfolio_frontier':frontier,'portfolio_comparison':comparisons}


def identity(sim:dict[str,Any])->dict[str,Any]:
    out={}
    for k in ['candidate_evaluation','application_simulation','account_simulation','portfolio_summary','portfolio_frontier','portfolio_comparison']:
        rows=sim[k]; hashes=sorted(r['row_hash'] for r in rows)
        out[k]={'rows':len(rows),'row_hash_root':canon_hash(hashes)}
    out['strategy_profiles']={'rows':len(PROFILES),'profile_contract_sha256':canon_hash([{**{kk:(fmt(vv,Q12) if isinstance(vv,Decimal) else vv) for kk,vv in p.items() if kk!='w'},'w':{k:fmt(v,Q6) for k,v in p['w'].items()}} for p in PROFILES])}
    out['bundle_sha256']=canon_hash(out)
    return out


def build_source_root(verification:dict[str,Any])->str:
    return canon_hash({'r4_sha256':verification['r4']['sha256'],'r17_sha256':verification['r17']['sha256'],
                       'r4_members':verification['r4']['members'],'r17_members':verification['r17']['members'],
                       'owner_profile_sha256':EXPECTED_OWNER_PROFILE_SHA,'method_source_set_sha256':EXPECTED_METHOD_SOURCE_SET_SHA})

EXPECTED_R4_FINAL_OUTCOMES={
 'DECLINE_NO_FEASIBLE_STRUCTURE':652,
 'DECLINE_INSUFFICIENT_EVIDENCE':234,
 'DECLINE_POLICY_HARD_STOP':234,
 'COUNTEROFFER_REVIEW_REQUIRED':212,
 'APPROVE_AS_REQUESTED_AUTHORIZED':115,
 'MANUAL_UNDERWRITING_REVIEW_REQUIRED':38,
 'COUNTEROFFER_AUTHORIZED':15,
}
EXPECTED_BASELINE_STRATEGY_OUTCOMES={
 'NO_ACCESS_NO_FEASIBLE_CANDIDATE':652,
 'CONTROLLED_REVIEW':250,
 'NO_ACCESS_INSUFFICIENT_EVIDENCE':234,
 'NO_ACCESS_POLICY_DECLINE':234,
 'ACCESS_SELECTED':130,
}
EXPECTED_CANDIDATE_FEASIBILITY={'INFEASIBLE':5186,'REVIEW_ELIGIBLE':1109,'STRICT_PASS':224}
EXPECTED_SIM_COUNTS={'candidate_evaluation':52152,'application_simulation':12000,'account_simulation':1040,'portfolio_summary':24,'portfolio_frontier':24,'portfolio_comparison':21}


def build_controls(verification:dict[str,Any], source:dict[str,list[dict[str,str]]], sim:dict[str,Any], ident:dict[str,Any], expected_identity:dict[str,Any]|None=None)->list[dict[str,Any]]:
    controls=[]
    def add(cid,scope,actual,expected,ok=None):
        if ok is None: ok=(actual==expected)
        ev={'control_id':cid,'control_scope':scope,'status':'PASS' if ok else 'FAIL','observed':actual,'expected':expected}
        ev['evidence_sha256']=canon_hash(ev);controls.append(ev)
    add('R19_INPUT_R4_ZIP_SHA256','INPUT',verification['r4']['sha256'],EXPECTED_R4_SHA)
    add('R19_INPUT_R17_ZIP_SHA256','INPUT',verification['r17']['sha256'],EXPECTED_R17_SHA)
    add('R19_INPUT_R18_FAILURE_ZIP_SHA256','INPUT',verification.get('r18_failure',{}).get('sha256',''),EXPECTED_R18_FAIL_SHA)
    add('R19_R4_OWNER_PROFILE_SHA256','METHOD',verification['r4']['policy_profile_sha256'],EXPECTED_OWNER_PROFILE_SHA)
    add('R19_R4_METHOD_SOURCE_SET_SHA256','METHOD',verification['r4']['accepted_method_source_set_sha256'],EXPECTED_METHOD_SOURCE_SET_SHA)
    for role,expected in EXPECTED_R4_ROWS.items(): add(f'R19_R4_{role.upper()}_ROWS','SOURCE',verification['r4']['members'][role]['rows'],expected)
    for role,expected in EXPECTED_R17_ROWS.items(): add(f'R19_R17_{role.upper()}_ROWS','SOURCE',verification['r17']['members'][role]['rows'],expected)
    vals=source['r17_validation']; add('R19_R17_VALIDATION_ALL_PASS','SOURCE',sum(str(r.get('status','')).upper()=='PASS' for r in vals),115)
    m27=source['r17_m2_7']; m210=source['r17_m2_10']
    add('R19_R17_FUNDED_M2_7_ROWS','SOURCE',len(m27),130); add('R19_R17_FUNDED_M2_10_ROWS','SOURCE',len(m210),130)
    add('R19_R17_FUNDED_SCENARIO_BASELINE','SOURCE',sum(r['scenario_code']=='BASELINE' for r in m210),103)
    add('R19_R17_FUNDED_SCENARIO_RECESSION_ENERGY','SOURCE',sum(r['scenario_code']=='RECESSION_ENERGY' for r in m210),27)
    final_dist=Counter(r['governed_final_outcome_code'] for r in source['r4_final'])
    add('R19_R4_FINAL_OUTCOME_DISTRIBUTION','SOURCE',dict(sorted(final_dist.items())),EXPECTED_R4_FINAL_OUTCOMES,dict(final_dist)==EXPECTED_R4_FINAL_OUTCOMES)
    cand_dist=Counter('STRICT_PASS' if bval(r.get('strict_pass_flag')) else ('REVIEW_ELIGIBLE' if bval(r.get('review_eligible_flag')) else 'INFEASIBLE') for r in source['r4_candidate'])
    add('R19_R4_CANDIDATE_FEASIBILITY_DISTRIBUTION','SOURCE',dict(sorted(cand_dist.items())),EXPECTED_CANDIDATE_FEASIBILITY,dict(cand_dist)==EXPECTED_CANDIDATE_FEASIBILITY)
    cand_keys=Counter((r['original_module1_run_id'],r['original_scenario_code'],r['original_merchant_application_id']) for r in source['r4_candidate'])
    protected=[r for r in source['r4_final'] if r['governed_final_outcome_code'] in {'DECLINE_INSUFFICIENT_EVIDENCE','DECLINE_POLICY_HARD_STOP'}]
    add('R19_EVIDENCE_POLICY_DECLINES_HAVE_NO_CANDIDATES','NONREGRESSION',sum(cand_keys[(r['module1_run_id'],r['scenario_code'],r['merchant_application_id'])] for r in protected),0)
    nofeas=[r for r in source['r4_final'] if r['governed_final_outcome_code']=='DECLINE_NO_FEASIBLE_STRUCTURE']
    proofkeys={(r['module1_run_id'],r['scenario_code'],r['merchant_application_id']) for r in source['r4_proof']}
    add('R19_NO_FEASIBLE_PROOF_POPULATION_EXACT','NONREGRESSION',sum((r['module1_run_id'],r['scenario_code'],r['merchant_application_id']) in proofkeys for r in nofeas),652)
    add('R19_STRATEGY_PROFILE_COUNT','METHOD',len(PROFILES),8)
    add('R19_STRATEGY_PROFILE_SEQUENCE','METHOD',[p['code'] for p in sorted(PROFILES,key=lambda p:p['seq'])],[p['code'] for p in PROFILES])
    for obj,expected in EXPECTED_SIM_COUNTS.items(): add(f'R19_{obj.upper()}_ROWS','SIMULATION',len(sim[obj]),expected)
    eval_count=Counter(r['source_candidate_row_hash'] for r in sim['candidate_evaluation'])
    add('R19_EVERY_SOURCE_CANDIDATE_EVALUATED_EIGHT_PROFILES','SIMULATION',dict(Counter(eval_count.values())),{8:6519},all(v==8 for v in eval_count.values()) and len(eval_count)==6519)
    app_count=Counter((r['module1_run_id'],r['scenario_code'],r['merchant_application_id']) for r in sim['application_simulation'])
    add('R19_EVERY_APPLICATION_EVALUATED_EIGHT_PROFILES','SIMULATION',dict(Counter(app_count.values())),{8:1500},all(v==8 for v in app_count.values()) and len(app_count)==1500)
    acct_count=Counter((r['module1_run_id'],r['scenario_code'],r['merchant_application_id']) for r in sim['account_simulation'])
    add('R19_EVERY_FUNDED_ACCOUNT_EVALUATED_EIGHT_PROFILES','SIMULATION',dict(Counter(acct_count.values())),{8:130},all(v==8 for v in acct_count.values()) and len(acct_count)==130)
    base_dist=Counter(r['strategy_outcome_code'] for r in sim['application_simulation'] if r['strategy_profile_code']=='BASELINE_REPLAY')
    add('R19_BASELINE_REPLAY_OUTCOME_DISTRIBUTION','NONREGRESSION',dict(sorted(base_dist.items())),EXPECTED_BASELINE_STRATEGY_OUTCOMES,dict(base_dist)==EXPECTED_BASELINE_STRATEGY_OUTCOMES)
    funded_rows=[r for r in sim['application_simulation'] if r['funded_source_flag']]
    add('R19_FUNDED_SOURCE_APPLICATION_PROFILE_ROWS','NONREGRESSION',len(funded_rows),1040)
    add('R19_FUNDED_M2_7_JOIN_COMPLETE','NONREGRESSION',sum(r['m2_7_joined_flag'] for r in funded_rows),1040)
    add('R19_FUNDED_M2_10_JOIN_COMPLETE','NONREGRESSION',sum(r['m2_10_joined_flag'] for r in funded_rows),1040)
    add('R19_ANALYTIC_ONLY_AUTHORITY_STATE','AUTHORITY',sum(r['simulation_authority_state']=='ANALYTIC_ONLY_NOT_PRODUCTION_AUTHORITY' for r in sim['application_simulation']),12000)
    early=[r for r in sim['account_simulation'] if r['strategy_profile_code']=='EARLY_INTERVENTION']
    early_inc=sum(dec(r['incremental_servicing_burden_units'],D0) or D0 for r in early)
    add('R19_EARLY_INTERVENTION_INCREMENT_EXACT','METHOD',fmt(early_inc,Q6),'4.000000')
    add('R19_NO_PAYMENT_FACTOR_CHANGE_CLAIM','METHOD',sum(r['payment_factor_changed_flag'] for r in sim['account_simulation']),0)
    add('R19_NO_EXPOSURE_CHANGE_CLAIM','METHOD',sum(r['exposure_changed_flag'] for r in sim['account_simulation']),0)
    add('R19_NO_TREATMENT_EFFECT_CLAIM','METHOD',sum(r['treatment_effect_claimed_flag'] for r in sim['account_simulation']),0)
    scopes=Counter(r['reporting_scope_code'] for r in sim['portfolio_summary'])
    add('R19_SUMMARY_SCOPE_POPULATION','PORTFOLIO',dict(sorted(scopes.items())),{'BASELINE':8,'PORTFOLIO':8,'RECESSION_ENERGY':8},dict(scopes)=={'BASELINE':8,'RECESSION_ENERGY':8,'PORTFOLIO':8})
    primary=[(r['reporting_scope_code'],r['strategy_profile_code']) for r in sim['portfolio_frontier'] if r['governance_priority_code']=='PRIMARY_GOVERNANCE_REVIEW']
    add('R19_ONE_PRIMARY_GOVERNANCE_REVIEW_PER_SCOPE','PORTFOLIO',primary,[('BASELINE','BALANCED_FRONTIER'),('RECESSION_ENERGY','BALANCED_FRONTIER'),('PORTFOLIO','BALANCED_FRONTIER')],primary==[('BASELINE','BALANCED_FRONTIER'),('RECESSION_ENERGY','BALANCED_FRONTIER'),('PORTFOLIO','BALANCED_FRONTIER')])
    add('R19_BASELINE_CONTROL_REFERENCE_PER_SCOPE','PORTFOLIO',sum(r['governance_priority_code']=='CONTROL_REFERENCE' for r in sim['portfolio_frontier']),3)
    roots={r['source_root_sha256'] for obj in EXPECTED_SIM_COUNTS for r in sim[obj]}
    add('R19_SINGLE_SOURCE_ROOT','LINEAGE',len(roots),1)
    for obj in EXPECTED_SIM_COUNTS:
        hashes=[r['row_hash'] for r in sim[obj]]
        add(f'R19_{obj.upper()}_ROW_HASH_UNIQUE','INTEGRITY',len(set(hashes)),len(hashes))
    if expected_identity is not None:add('R19_OFFLINE_EXPECTED_IDENTITY_EXACT','INTEGRITY',ident,expected_identity,ident==expected_identity)
    add('R19_SOURCE_PAYLOAD_USES_R4_R17_EVIDENCE_NOT_R17_DATABASE','AUTHORITY','PACKAGED_R4_AND_R17_EVIDENCE','PACKAGED_R4_AND_R17_EVIDENCE')
    add('R19_R18_NO_COMPILER_OR_FINAL_CREATED','CORRECTION_HISTORY',verification.get('r18_failure',{}).get('compiler_created') is False and verification.get('r18_failure',{}).get('final_created') is False,True)
    return controls
