"""Check the published repayment exhibit, or rebuild it from the original return."""
import argparse
import csv
import hashlib
import io
import json
import re
from collections import Counter, defaultdict
from datetime import date, timedelta
from decimal import Decimal as D, ROUND_HALF_UP
from pathlib import Path
from zipfile import ZipFile

SOURCE_SHA = "a9f66ac2b963fbb56a590a08e51d13fa608f0ab8c066f26f886897bd6e9ca6f7"
PREFIX = "module2/20261123T055129Z_84dd8843/"
CASE = "MSBF_POP_F6FE23D2EDFA6B2AC397AFE5F_M000462_A01"
CASE_FILE = "merchant_000462.csv"
GROUP_FILE = "paired_payoffs.csv"
FUNDING_FILE = "funding_pairs.csv"
MATCH_FILE = "jointly_funded_terms_and_payoff.csv"
SCENARIOS = ("BASELINE", "RECESSION_ENERGY")
MATCH_TERMS = ("contractual_repayment_usd", "remittance_rate_pct", "payback_multiple", "collection_horizon_days")
GROUPS = ("All jointly funded", "All five terms match", "One or more terms differ")
OUTCOMES = ("Same day", "Later in Recession Energy", "Earlier in Recession Energy",
            "Recession Energy open on day 120")
FIRST_DAY = date(2026, 7, 26)
FIRST_SOURCE = date(2026, 3, 26)
CENT = D(".01")


def check(condition, message):
    if not condition:
        raise ValueError(message)


def csv_bytes(header, rows):
    stream = io.StringIO(newline="")
    writer = csv.writer(stream, lineterminator="\n")
    writer.writerow(header)
    writer.writerows(rows)
    return stream.getvalue().encode("utf-8")


def read_table(archive, proof, table):
    member = "continuation/relational/msbf_m2." + table + ".csv"
    data = archive.read(PREFIX + member)
    expected = proof[member]
    check(len(data) == expected["bytes"] and hashlib.sha256(data).hexdigest() == expected["sha256"],
          f"Source table differs: {table}")
    for row in csv.DictReader(io.StringIO(data.decode("utf-8-sig"))):
        yield json.loads(row["payload"], parse_float=D)


def path_key(row):
    return row["module1_run_id"], row["scenario_code"], row["merchant_application_id"]


def funding_table(bookings, advances):
    pairs = defaultdict(dict)
    funded_keys = set()
    for booking in bookings:
        key = path_key(booking)
        run, scenario, app = key
        match = re.fullmatch(r"MSBF_POP_F6FE23D2EDFA6B2AC397AFE5F_(M[0-9]{6})_A01", app)
        check(run == 1 and scenario in SCENARIOS and match, "Funding pair cohort differs")
        pair = pairs[match[1]]
        check(scenario not in pair, "Duplicate application-scenario booking")
        funded = booking["funding_completed_flag"]
        check(booking["real_funds_movement_flag"] is False and type(funded) is bool, "Synthetic booking flag differs")
        amount = booking["funded_amount"]
        if funded:
            advance = advances[key]
            check(amount == advance["funded_amount"] > 0 and
                  advance["source_activation_row_hash"] == booking["row_hash"] and
                  all(advance[f] == booking[f] for f in ("synthetic_account_id", "synthetic_advance_id")),
                  "Funding pair differs from advance")
            funded_keys.add(key)
        else:
            check(amount is None and key not in advances, "Unfunded booking has principal or advance")
        pair[scenario] = (int(funded), f"{amount or 0:.2f}")
    check(funded_keys == advances.keys(), "Funding pair membership differs")
    rows = []
    for merchant, pair in sorted(pairs.items()):
        check(set(pair) == set(SCENARIOS), "Scenario missing from funding pair")
        rows.append((merchant, *pair["BASELINE"], *pair["RECESSION_ENERGY"]))
    return csv_bytes(["merchant_key", "baseline_funded", "baseline_principal_usd", "recession_energy_funded",
                      "recession_energy_principal_usd"], rows)


def check_public_funding(data):
    rows = list(csv.DictReader(io.StringIO(data.decode("utf-8-sig"))))
    check([r["merchant_key"] for r in rows] == [f"M{i:06}" for i in range(1, 751)],
          "Funding pair keys differ")
    counts, changes = Counter(), Counter()
    basetotal, stresstotal = D(0), D(0)
    for row in rows:
        sides = []
        for prefix in ("baseline", "recession_energy"):
            flag = row[prefix + "_funded"]
            principal = D(row[prefix + "_principal_usd"])
            check(flag in {"0", "1"} and principal >= 0 and (flag == "1") == (principal > 0),
                  "Funding flag and principal disagree")
            sides.append((int(flag), principal))
        (base, base_amount), (stress, stress_amount) = sides
        counts[base, stress] += 1
        changes[base, stress] += base_amount - stress_amount
        basetotal += base_amount
        stresstotal += stress_amount
    check(counts == {(1, 1): 35, (1, 0): 80, (0, 0): 635}, "Funding pair counts differ")
    check((counts[1, 1] + counts[1, 0], counts[1, 1] + counts[0, 1]) == (115, 35), "Funded counts differ")
    check((basetotal, stresstotal) == (D("1740100.00"), D("452400.00")), "Scenario principal sums differ")
    check((changes[1, 0], changes[1, 1], basetotal - stresstotal) ==
          (D("1287600.00"), D("100.00"), D("1287700.00")), "Principal decomposition differs")


def source_exhibits(source):
    with source.open("rb") as handle:
        check(hashlib.file_digest(handle, "sha256").hexdigest() == SOURCE_SHA, "Wrong return archive")
    with ZipFile(source) as archive:
        proof = json.loads(archive.read(PREFIX + "FINAL_EXECUTION_PROOF.json"))
        by_key = {}
        for table in ("synthetic_advance_funding", "initial_portfolio_activation"):
            records = list(read_table(archive, proof, table))
            by_key[table] = {path_key(row): row for row in records}
            check(len(records) == len(by_key[table]) == 150, f"Funded path count differs: {table}")
        advances = by_key["synthetic_advance_funding"]
        openings = by_key["initial_portfolio_activation"]
        funding_csv = funding_table(read_table(archive, proof, "application_booking_funding_activation_snapshot"), advances)
        paths = defaultdict(dict)
        for row in read_table(archive, proof, "advance_daily_remittance_monitoring"):
            path = paths[path_key(row)]
            day = row["monitoring_day_index"]
            check(day not in path, "Duplicate daily observation")
            path[day] = row
    check(advances.keys() == openings.keys() == paths.keys(), "Funding-to-monitoring join differs")
    payoff = {}
    for key, days in paths.items():
        advance, opening = advances[key], openings[key]
        check(set(days) == set(range(1, 121)), "Missing monitoring day")
        balance = opening["initial_expected_collection_amount"]
        starting_balance = balance
        check(balance == advance["total_repayment_amount"] and opening["source_advance_row_hash"] == advance["row_hash"],
              "Opening portfolio and funding disagree")
        payoff[key] = None
        for i in range(1, 121):
            row = days[i]
            check(row["source_portfolio_row_hash"] == opening["row_hash"] and
                  row["source_advance_row_hash"] == advance["row_hash"] and
                  all(row[f] == opening[f] == advance[f] for f in ("synthetic_account_id", "synthetic_advance_id")),
                  "Daily source binding differs")
            check(row["monitoring_date"] == (FIRST_DAY + timedelta(days=i - 1)).isoformat() and
                  row["source_observation_date"] == (FIRST_SOURCE + timedelta(days=i - 1)).isoformat(),
                  "Daily dates differ")
            raw = (row["source_eligible_pos_sales"] * advance["remittance_rate"]).quantize(CENT, rounding=ROUND_HALF_UP)
            remitted = min(raw, balance)
            check(row["contracted_remittance_rate"] == advance["remittance_rate"] and
                  row["raw_remittance_amount"] == raw and row["actual_remittance_amount"] == remitted and
                  row["receivable_balance_before"] == balance, "Cash collection replay differs")
            balance -= remitted
            check(balance == row["receivable_balance_after"] and
                  starting_balance - balance == row["cumulative_remittance_amount"] and
                  (balance == 0) == row["paid_off_flag"], "Balance or cumulative remittance differs")
            if balance == 0 and payoff[key] is None:
                payoff[key] = i

    case_keys = [(1, scenario, CASE) for scenario in SCENARIOS]
    activation_date = openings[case_keys[0]]["portfolio_activation_date"]
    check(activation_date == openings[case_keys[1]]["portfolio_activation_date"] == "2026-07-25",
          "Opening date differs")
    day_zero = [0, activation_date, ""]
    for key in case_keys:
        day_zero.extend(("", "", f'{openings[key]["initial_expected_collection_amount"]:.2f}'))
    case_rows = [day_zero]
    for i in range(1, 121):
        base = paths[case_keys[0]][i]
        out = [i, base["monitoring_date"], base["source_observation_date"]]
        for key in case_keys:
            row = paths[key][i]
            out.extend(f"{row[field]:.2f}" for field in
                       ("source_eligible_pos_sales", "actual_remittance_amount", "receivable_balance_after"))
        case_rows.append(out)
    header = ["day", "date", "source_sales_date"]
    for scenario in SCENARIOS:
        header.extend(scenario.lower() + "_" + suffix for suffix in
                      ("eligible_sales_usd", "remittance_usd", "receivable_usd"))

    funded = [{app for run, sc, app in advances if run == 1 and sc == name} for name in SCENARIOS]
    paired = funded[0] & funded[1]
    check((len(funded[0]), len(funded[1]), len(paired)) == (115, 35, 35), "Jointly funded population differs")
    columns = ["merchant_key"]
    for scenario in SCENARIOS:
        columns.extend(f"{scenario.lower()}_{field}" for field in (*MATCH_TERMS, "first_zero_day"))
    matched_rows = []
    for app in sorted(paired):
        merchant_key = app.split("_")[-2]
        record = [merchant_key]
        for scenario in SCENARIOS:
            key = (1, scenario, app)
            advance = advances[key]
            record.extend([f'{advance["total_repayment_amount"]:.2f}', format(100 * advance["remittance_rate"], "f"),
                           format(advance["payback_multiple"], "f"), advance["collection_horizon_days"],
                           payoff[key] if payoff[key] is not None else ""])
        matched_rows.append(record)
    matched = csv_bytes(columns, matched_rows)
    return {FUNDING_FILE: funding_csv, MATCH_FILE: matched, CASE_FILE: csv_bytes(header, case_rows),
            GROUP_FILE: summarize_payoffs(funding_csv, matched)}


def summarize_payoffs(funding_csv, matched_csv):
    funding = csv.DictReader(io.StringIO(funding_csv.decode("utf-8")))
    joint = {r["merchant_key"]: r for r in funding
             if r["baseline_funded"] == r["recession_energy_funded"] == "1"}
    rows = list(csv.DictReader(io.StringIO(matched_csv.decode("utf-8"))))
    check([r["merchant_key"] for r in rows] == sorted(joint), "Joint funding and payoff membership differ")
    counts = defaultdict(Counter)
    for row in rows:
        funded = joint[row["merchant_key"]]
        terms = []
        days = []
        for scenario in SCENARIOS:
            prefix = scenario.lower() + "_"
            terms.append((D(funded[prefix + "principal_usd"]), *(D(row[prefix + f]) for f in MATCH_TERMS)))
            value = row[prefix + "first_zero_day"]
            day = None if value == "" else int(value)
            check(day is None or 1 <= day <= 120, "Payoff day outside observed window")
            days.append(day)
        base, stress = days
        check(base is not None, "Baseline unfinished within observed paired cohort")
        if stress is None:
            outcome = OUTCOMES[3]
        elif base == stress:
            outcome = OUTCOMES[0]
        elif stress > base:
            outcome = OUTCOMES[1]
        else:
            outcome = OUTCOMES[2]
        group = GROUPS[1] if terms[0] == terms[1] else GROUPS[2]
        counts[GROUPS[0]][outcome] += 1
        counts[group][outcome] += 1
    groups = []
    for group in GROUPS:
        total = sum(counts[group].values())
        for outcome in OUTCOMES:
            count = counts[group][outcome]
            share = f"{100 * D(count) / total:.2f}" if total else ""
            groups.append((group, outcome, count, total, share))
    return csv_bytes(["funding_terms_group", "observed_payoff", "merchants", "group_denominator",
                      "share_of_group_pct"], groups)


def check_public_case(data, matched_csv):
    matches = [r for r in csv.DictReader(io.StringIO(matched_csv.decode("utf-8")))
               if r["merchant_key"] == "M000462"]
    check(len(matches) == 1, "Daily case has no unique terms record")
    contract = matches[0]
    rows = list(csv.DictReader(io.StringIO(data.decode("utf-8-sig"))))
    check([int(r["day"]) for r in rows] == list(range(121)), "Day sequence differs")
    for scenario in SCENARIOS:
        prefix = scenario.lower() + "_"
        rate = D(contract[prefix + "remittance_rate_pct"]) / 100
        previous = D(rows[0][prefix + "receivable_usd"])
        check(previous == D(contract[prefix + "contractual_repayment_usd"]) == D("184463.41") and rows[0]["date"] == "2026-07-25" and
              all(rows[0][f] == "" for f in ("source_sales_date", prefix + "eligible_sales_usd",
                                              prefix + "remittance_usd")), "Opening row differs")
        total, first_zero = D(0), None
        for i, row in enumerate(rows[1:], 1):
            check(row["date"] == str(FIRST_DAY + timedelta(days=i-1)) and
                  row["source_sales_date"] == str(FIRST_SOURCE + timedelta(days=i-1)), "Daily dates differ")
            sales, remitted, closing = [D(row[prefix + field]) for field in
                                        ("eligible_sales_usd", "remittance_usd", "receivable_usd")]
            check(sales >= 0, "Negative eligible sales")
            check(remitted == min((sales * rate).quantize(CENT, rounding=ROUND_HALF_UP), previous),
                  "Capped remittance differs")
            check(closing == previous - remitted, "Closing balance differs")
            previous = closing
            total += remitted
            if closing == 0 and first_zero is None:
                first_zero = i
        first_zero_text = "" if first_zero is None else str(first_zero)
        check(first_zero_text == contract[prefix + "first_zero_day"], "Public daily case and paired payoff day differ")
        expected = (111, D("184463.41"), D(0)) if scenario == "BASELINE" else (None, D("180719.97"), D("3743.44"))
        check((first_zero, total, previous) == expected, "Payoff, total, or closing balance differs")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="Verify against the original Local Take 4 RETURN.zip")
    parser.add_argument("--write-to", type=Path, help="Create a new directory with reconstructed CSVs")
    opts = parser.parse_args()
    if opts.write_to and not opts.source:
        parser.error("--write-to needs --source")
    folder = Path(__file__).resolve().parent
    if opts.source:
        rebuilt = source_exhibits(opts.source)
        check_public_case(rebuilt[CASE_FILE], rebuilt[MATCH_FILE])
        check_public_funding(rebuilt[FUNDING_FILE])
        if opts.write_to:
            opts.write_to.mkdir(parents=True, exist_ok=False)
            for name, data in rebuilt.items():
                (opts.write_to / name).write_bytes(data)
            print("Reconstructed four CSVs from the checksum-verified return.")
            return
        for name, data in rebuilt.items():
            check((folder / name).read_bytes() == data, "Public extract differs from source: " + name)
        print("Matched four public CSVs to the original return. Reconciled 750 funding pairs and 18,000 daily rows.")
    else:
        funding_data = (folder / FUNDING_FILE).read_bytes()
        check_public_funding(funding_data)
        check(hashlib.sha256(funding_data).hexdigest() == "4fd76ad41c812661086e103beeb5eb96d96633013e9e9b59a1225e2c661f2a37", "Funding pair bytes differ")
        matched_data = (folder / MATCH_FILE).read_bytes()
        check_public_case((folder / CASE_FILE).read_bytes(), matched_data)
        group_data = (folder / GROUP_FILE).read_bytes()
        check(summarize_payoffs(funding_data, matched_data) == group_data, "Payoff summary differs from public pairs")
        check(hashlib.sha256(matched_data).hexdigest() == "bd7379fee002350ff38b88f2633ba919cf0b2c62cf9e264bd16740279c64cf4f", "Joint funding evidence bytes differ")
        check(hashlib.sha256(group_data).hexdigest() == "af232401829d78d03a6f6f365dec3d60c33e1d01a0660521a313f1d19de60d2d", "Paired payoff table differs")
        check(hashlib.sha256((folder / CASE_FILE).read_bytes()).hexdigest() == "c749bb0551ad535f169b557839c1bc1e4c77663994ebfad37c3e4e8245dd7ec9", "Daily data bytes differ")
        print("Checked four CSV hashes, reconciled 750 funding pairs, reproduced all 12 payoff rows from 35 pairs, and replayed both 120-day paths for merchant 000462.")


if __name__ == "__main__":
    main()
