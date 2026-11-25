"""Recalculate the published three-study comparisons from the companion extracts."""
import csv
import hashlib
import json
import subprocess
import sys
from collections import Counter
from datetime import date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent
# supportable, funded, principal, open across all fundings, open among jointly funded
EXPECTED = {
    750: ((321, 115, 1740100, 5, 0), (94, 35, 452400, 1, 1)),
    2500: ((1055, 329, 4760000, 22, 7), (269, 100, 1412700, 7, 7)),
    25000: ((10564, 3337, 52077600, 176, 36), (2836, 1005, 14412300, 43, 43)),
}
CASES = {750: ('000462', '0.097672', '0.00', '3743.44'),
         2500: ('002411', '0.095689', '13778.02', '20300.32'),
         25000: ('009886', '0.096943', '0.00', '10736.08')}
ZERO = Decimal(0)

def require(ok, message):
    if not ok:
        raise ValueError(message)

def rows(filename):
    with (ROOT / filename).open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))

def stress_draw(source_date, stream):
    # The simulator's stable MD5-based draws are keyed to merchant, date, scenario and stream.
    merchant = 'MSBF_POP_F6FE23D2EDFA6B2AC397AFE5F_M000499'
    key = f'{merchant}|{source_date}|RECESSION_ENERGY|DET_HASH_V1:M1_6:{stream}'
    prefix = hashlib.md5(key.encode()).hexdigest()[:15]
    return Decimal(int(prefix, 16)) / (2 ** 60)

def verify_merchant_499():
    series = rows('merchant_000499_stress_sales.csv')
    require([int(r['day']) for r in series] == list(range(1, 121)), '000499: monitoring days')
    payoff = [r for r in rows('earlier_payoff.csv') if r['merchant_key'] == 'M000499']
    scenarios = {'baseline': 'BASELINE', 'stress': 'RECESSION_ENERGY'}
    require(Counter((r['scenario'], int(r['monitoring_day'])) for r in payoff) ==
            Counter((scenario, day) for scenario in scenarios.values() for day in range(60, 64)),
            '000499: payoff excerpt dates')
    for record in payoff:
        side = next(k for k, v in scenarios.items() if v == record['scenario'])
        trace = series[int(record['monitoring_day']) - 1]
        for measure, exported in [('eligible', 'eligible_sales_usd'), ('opening', 'opening_receivable_usd'),
                                  ('paid', 'actual_remittance_usd'), ('closing', 'closing_receivable_usd')]:
            require(Decimal(trace[f'{side}_{measure}']) == Decimal(record[exported]),
                    f'000499: day {trace["day"]} {side} {measure} in payoff excerpt')
    terms = [r for r in rows('jointly_funded_terms_and_payoff.csv') if r['merchant_key'] == 'M000499']
    require(len(terms) == 1, '000499: funded terms')
    balances = {}
    rates = {}
    payoff_days = {}
    for side, scenario in scenarios.items():
        prefix = scenario.lower()
        balances[side] = Decimal(terms[0][f'{prefix}_contractual_repayment_usd'])
        rates[side] = Decimal(terms[0][f'{prefix}_remittance_rate_pct']) / 100
        require((balances[side], rates[side]) == (Decimal('13391.01'), Decimal('.133511')),
                '000499: terms')
    cent = Decimal('.01')
    for r in series:
        day = int(r['day'])
        source_date = date(2026, 3, 26) + timedelta(days=day - 1)
        require(source_date.isoformat() == r['source_date'], f'000499: source date on day {day}')
        direct = propagation = volatility = Decimal(1)
        closed = False
        if source_date >= date(2026, 5, 25):
            direct = 1 - Decimal('.18') * Decimal('.10')
            volatility += Decimal('.35') * (2 * stress_draw(source_date, 'VOLATILITY') - 1)
            closed = (stress_draw(source_date, 'OUTAGE') < Decimal('.02') or
                      stress_draw(source_date, 'ZERO') < Decimal('.072'))
        if source_date >= date(2026, 6, 1):
            propagation = 1 - Decimal('.18') * Decimal('.15') * Decimal('.65')
        actual = tuple(Decimal(r[k]) for k in ('direct_factor', 'propagation_factor', 'volatility_factor'))
        require(actual == (direct, propagation, volatility.quantize(Decimal('.00000001'))),
                f'000499: sales factors on day {day}')
        gross = ZERO if closed else Decimal(r['baseline_gross']) * direct * propagation * volatility
        require(gross.quantize(cent, rounding=ROUND_HALF_UP) == Decimal(r['stress_gross']),
                f'000499: reproducible gross sales on day {day}')
        for side in scenarios:
            opening = balances[side]
            eligible = Decimal(r[f'{side}_eligible'])
            paid = min(opening, (eligible * rates[side]).quantize(cent, rounding=ROUND_HALF_UP))
            balances[side] = opening - paid
            actual = tuple(Decimal(r[f'{side}_{k}']) for k in ('opening', 'paid', 'closing'))
            require(actual == (opening, paid, balances[side]), f'000499: {side} remittance on day {day}')
            if opening > 0 and balances[side] == 0:
                payoff_days[side] = day
    require(payoff_days == {'baseline': 63, 'stress': 62} and
            all(payoff_days[k] == int(terms[0][f'{v.lower()}_first_zero_day']) for k, v in scenarios.items()),
            '000499: payoff days')
    for day, base, stress in [(61, '839.21', '918.27'), (62, '1896.01', '2254.62')]:
        record = series[day - 1]
        require((Decimal(record['baseline_gross']), Decimal(record['stress_gross'])) ==
                (Decimal(base), Decimal(stress)), f'000499: key gross sales on day {day}')
    pairs = [(Decimal(r['baseline_eligible']), Decimal(r['stress_eligible'])) for r in series[60:]]
    totals = tuple(sum(values) for values in zip(*pairs))
    require(totals == (Decimal('81473.30'), Decimal('71736.73')), '000499: shock-period eligible sales')
    require(Counter(b.compare(a) for a, b in pairs) == {-1: 33, 0: 10, 1: 17}, '000499: daily comparisons')
    print('PASS 000499: 120 daily gross sales replayed, 240 remittances, payoff excerpt and shock-period totals')

def verify_counteroffer_floor(counts):
    # Historical outcomes below the proposed floor, split by authorization and review, then exactly at 60%.
    expected = {(750, 'BASELINE'): (6, 39, 0), (750, 'RECESSION_ENERGY'): (3, 7, 0),
                (2500, 'BASELINE'): (15, 107, 2), (2500, 'RECESSION_ENERGY'): (6, 23, 0),
                (25000, 'BASELINE'): (190, 1039, 36), (25000, 'RECESSION_ENERGY'): (101, 225, 2)}
    records = rows('counteroffer_floor_sensitivity.csv')
    require(Counter((int(r['merchants']), r['scenario']) for r in records) == Counter(expected.keys()),
            'counteroffer floor: cohort/scenario coverage')
    decisions = {(int(r['merchants']), r['scenario'], r['governed_outcome']): int(r['applications'])
                 for r in counts}
    for r in records:
        key = (int(r['merchants']), r['scenario'])
        authorized = decisions[(*key, 'COUNTEROFFER_AUTHORIZED')]
        review = decisions[(*key, 'COUNTEROFFER_REVIEW_REQUIRED')]
        columns = ('selected_authorized_counteroffers', 'selected_review_counteroffers', 'all_selected_counteroffers')
        require(tuple(int(r[k]) for k in columns) == (authorized, review, authorized + review),
                f'counteroffer floor: selected counteroffers {key}')
        below_authorized, below_review, exact = expected[key]
        columns = ('authorized_below_60pct', 'review_below_60pct', 'all_below_60pct', 'exactly_at_60pct')
        require(tuple(int(r[k]) for k in columns) ==
                (below_authorized, below_review, below_authorized + below_review, exact),
                f'counteroffer floor: historical counts {key}')
    print('PASS 60% floor: six historical cohort/scenario counts reconciled to selected counteroffer totals')

def verify_official_750():
    records = rows('official_750_r26_summary.csv')
    expected = {
        'BASELINE': (174, 23, 103, Decimal('1385300.00'), 99, Decimal('6061.03')),
        'RECESSION_ENERGY': (38, 15, 27, Decimal('344200.00'), 27, Decimal('0.00')),
    }
    require(Counter(r['scenario'] for r in records) == Counter(expected.keys()), 'R26: scenarios')
    for r in records:
        counter, manual, funded, principal, paid, balance = expected[r['scenario']]
        require(r['study'] == 'HISTORICAL_750_R26' and int(r['applications']) == 750, 'R26: identity')
        require((int(r['counteroffer_review']), int(r['underwriting_review']), int(r['funded']),
                 Decimal(r['funded_principal_usd']), int(r['paid_off']), Decimal(r['ending_balance_usd']))
                == (counter, manual, funded, principal, paid, balance), 'R26: published scenario figures')
        reviews = counter + manual
        require((int(r['review_only']), int(r['supportable']), int(r['declined']), int(r['open_accounts']))
                == (reviews, funded + reviews, 750 - funded - reviews, funded - paid),
                'R26: decision and payoff reconciliation')
        require(int(r['monitoring_days']) == 120 and int(r['daily_monitoring_rows']) == funded * 120,
                'R26: monitoring duration and volume')
    require(sum(int(r['daily_monitoring_rows']) for r in records) == 15600, 'R26: monitoring total')
    print('PASS historical 750 R26: published decision and payoff totals, funded principal and 15,600 daily records')

def verify_aws_750():
    records = rows('aws_750_take1_summary.csv')
    expected = {
        'BASELINE': ((94, 16, 166, 42, 41, 293, 98), Decimal('1570500.00'), 13200),
        'RECESSION_ENERGY': ((23, 3, 35, 11, 201, 379, 98), Decimal('491300.00'), 3120),
    }
    fields = ('approved_as_requested', 'counteroffer_authorized', 'counteroffer_review', 'underwriting_review',
              'evidence_decline', 'no_feasible_structure', 'policy_hard_stop')
    require(Counter(r['scenario'] for r in records) == Counter(expected.keys()), 'AWS 750: scenarios')
    for r in records:
        outcomes, principal, daily = expected[r['scenario']]
        require(r['study'] == '750C_AWS_TAKE_1' and r['native_run'] == '20261123T182238Z_35ed811a',
                'AWS 750: campaign identity')
        require(tuple(int(r[k]) for k in fields) == outcomes and sum(outcomes) == int(r['applications']) == 750,
                'AWS 750: reported decision codes')
        funded, review, declined = sum(outcomes[:2]), sum(outcomes[2:4]), sum(outcomes[4:])
        require(tuple(int(r[k]) for k in ('funded','review_only','declined','supportable')) ==
                (funded, review, declined, funded + review), 'AWS 750: grouped decisions')
        require(Decimal(r['funded_principal_usd']) == principal and int(r['daily_monitoring_rows']) == daily,
                'AWS 750: reported dollars and daily records')
        require((r['monitoring_start'], r['monitoring_end']) == ('2026-07-26', '2026-11-22') and
                (date.fromisoformat(r['monitoring_end']) - date.fromisoformat(r['monitoring_start'])).days + 1
                == daily // funded and daily == funded * 120, 'AWS 750: monitoring interval')
        require(int(r['cohort_matched_applications_with_changed_decision']) == 254,
                'AWS 750: reported cohort-wide count of changed decisions')
    print('PASS 750C AWS Take 1: 1,500 decisions, both scenario portfolios and 16,320 daily records')

def verify_decision_transitions(counts):
    groups = ('Authorized', 'Review only', 'Declined')
    decision_group = {
        'APPROVE_AS_REQUESTED_AUTHORIZED': 'Authorized',
        'COUNTEROFFER_AUTHORIZED': 'Authorized',
        'COUNTEROFFER_REVIEW_REQUIRED': 'Review only',
        'MANUAL_UNDERWRITING_REVIEW_REQUIRED': 'Review only',
        'DECLINE_INSUFFICIENT_EVIDENCE': 'Declined',
        'DECLINE_NO_FEASIBLE_STRUCTURE': 'Declined',
        'DECLINE_POLICY_HARD_STOP': 'Declined',
    }
    cells = {}
    changes = {}
    for row in rows('governed_decision_transitions.csv'):
        n = int(row['cohort_merchants'])
        baseline, stress = row['baseline_disposition'], row['recession_energy_disposition']
        key = (n, baseline, stress)
        require(key not in cells, f'duplicate decision transition {key}')
        cells[key] = int(row['matched_applications'])
        changes[key] = int(row['changed_seven_category_outcome'])
        require(0 <= changes[key] <= cells[key], f'invalid decision change count {key}')
        if baseline != stress:
            require(changes[key] == cells[key], f'cross-disposition changes {key}')
    require(set(cells) == {(n, a, b) for n in EXPECTED for a in groups for b in groups},
            'decision transition cohort/disposition coverage')

    margins = Counter()
    for row in counts:
        key = (int(row['merchants']), row['scenario'], decision_group[row['governed_outcome']])
        margins[key] += int(row['applications'])
    for n, changed_total in [(750, 241), (2500, 822), (25000, 8163)]:
        require(sum(changes[n, a, b] for a in groups for b in groups) == changed_total,
                f'{n}: changed seven-category outcomes')
        for group in groups:
            require(sum(cells[n, group, b] for b in groups) == margins[n, 'BASELINE', group],
                    f'{n}: Baseline {group} margin')
            require(sum(cells[n, a, group] for a in groups) == margins[n, 'RECESSION_ENERGY', group],
                    f'{n}: Recession Energy {group} margin')

    local_cells, local_changes = Counter(), Counter()
    for row in rows('application_paths.csv'):
        a, b = row['baseline_decision'], row['recession_energy_decision']
        key = (750, decision_group[a], decision_group[b])
        local_cells[key] += 1
        local_changes[key] += a != b
    for a in groups:
        for b in groups:
            key = (750, a, b)
            require((cells[key], changes[key]) == (local_cells[key], local_changes[key]),
                    f'Local Take 4 application pairs {key}')
    print('PASS 27 matched decision cells, both scenario margins, three seven-category change totals and Local 750 pairs')

def verify():
    digests = json.loads((ROOT / 'study_extract_sha256.json').read_text())
    for filename, expected in digests.items():
        require(hashlib.sha256((ROOT / filename).read_bytes()).hexdigest() == expected, filename)
    for script in ['verify_exhibit.py', 'verify_application_paths.py']:
        subprocess.run([sys.executable, '-B', str(ROOT / script)], check=True)
    verify_official_750()
    verify_aws_750()
    counts = rows('decision_counts.csv')
    for n, values in EXPECTED.items():
        merchant, share, final_b, final_r = CASES[n]
        series = rows(f'merchant_{merchant}.csv')
        require([int(r['day']) for r in series] == list(range(121)), f'{n}: dates')
        sales_field = 'eligible_sales_usd' if n == 750 else 'sales_usd'
        for field in (sales_field, 'remittance_usd', 'receivable_usd'):
            first_difference = next((int(r['day']) for r in series[1:]
                                     if Decimal(r['baseline_' + field]) != Decimal(r['recession_energy_' + field])), None)
            require(first_difference == 61, f'{n} merchant {merchant}: first difference in {field}')
        for i, side in enumerate(('baseline', 'recession_energy')):
            target = values[i]
            decisions = {r['governed_outcome']: int(r['applications']) for r in counts
                         if int(r['merchants']) == n and r['scenario'] == side.upper()}
            funded = sum(v for k, v in decisions.items() if k.endswith('_AUTHORIZED'))
            review = sum(v for k, v in decisions.items() if k.endswith('_REVIEW_REQUIRED'))
            require(len(decisions) == 7 and sum(decisions.values()) == n, f'{n}: total decisions')
            require((funded + review, funded) == target[:2], f'{n}: supportable/funded')
            if n > 750:
                paths = rows(f'funded_paths_{n}.csv')
                require(len(set(p['merchant_key'] for p in paths)) == len(paths), 'duplicate merchant')
                active = [p for p in paths if p[f'{side}_principal_usd']]
                both = [p for p in paths if p['baseline_principal_usd'] and p['recession_energy_principal_usd']]
                require(len(both) == values[1][1], 'jointly funded denominator')
                def opened(subset):
                    return sum(Decimal(p[f'{side}_day120_receivable_usd']) > 0 for p in subset)
                totals = (len(active), sum(Decimal(p[f'{side}_principal_usd']) for p in active),
                          opened(active), opened(both))
                require(totals == target[1:], f'{n} {side}: portfolio reconciliation')
            balance = Decimal(series[0][f'{side}_receivable_usd'])
            sales_key = f'{side}_eligible_sales_usd' if n == 750 else f'{side}_sales_usd'
            for row in series[1:]:
                paid = Decimal(row[f'{side}_remittance_usd'])
                calculated = (Decimal(row[sales_key]) * Decimal(share)).quantize(Decimal('.01'), rounding=ROUND_HALF_UP)
                require(min(calculated, balance) == paid, f'{n}: remittance day {row["day"]}')
                balance -= paid
                require(balance == Decimal(row[f'{side}_receivable_usd']), f'{n}: closing balance day {row["day"]}')
            require(balance == Decimal((final_b, final_r)[i]), f'{n}: case closing balance')
        label = 'Local 750 Take 4' if n == 750 else f'{n:,} study'
        print(f'PASS {label}: financing totals, matched balances, 120 daily payments per scenario, featured paths first diverge on day 61')
    verify_merchant_499()
    verify_counteroffer_floor(counts)
    verify_decision_transitions(counts)
    timing = rows('execution_records.csv')
    require(len(timing)==6, 'timing records')
    for row in timing:
        if row['start_utc'] and row['end_utc']:
            seconds = (datetime.fromisoformat(row['end_utc'])-datetime.fromisoformat(row['start_utc'])).total_seconds()
            require(abs(seconds - float(row['recorded_seconds'])) < .001, row['record'])
    require([round(float(r['recorded_seconds'])) for r in timing if r['recorded_seconds']] ==
            [7173, 3445, 5214, 55575], 'measured durations')
    print('PASS 4 measured clocks, 1 operator estimate, 1 historical elapsed time unavailable')

if __name__ == '__main__':
    verify()
