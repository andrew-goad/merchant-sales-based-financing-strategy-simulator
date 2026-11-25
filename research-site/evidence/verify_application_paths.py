"""Recount Local Take 4 decision paths and day-120 receivables using Python 3."""
import argparse
import csv
import hashlib
import io
import json
import re
from collections import Counter
from decimal import Decimal
from pathlib import Path
from zipfile import ZipFile

RUN = "20261123T055129Z_84dd8843"
COHORT = "MSBF_POP_F6FE23D2EDFA6B2AC397AFE5F"
RETURN_SHA = "a9f66ac2b963fbb56a590a08e51d13fa608f0ab8c066f26f886897bd6e9ca6f7"
EXHIBIT_SHA = "78914df09810c771c20afca5ff89d715374c5495ae38fcfecd39fe8cb06204de"
SCENARIOS = ("BASELINE", "RECESSION_ENERGY")
AUTHORIZED = {"APPROVE_AS_REQUESTED_AUTHORIZED", "COUNTEROFFER_AUTHORIZED"}
REVIEWABLE = {"COUNTEROFFER_REVIEW_REQUIRED", "MANUAL_UNDERWRITING_REVIEW_REQUIRED"}
DECLINED = {"DECLINE_INSUFFICIENT_EVIDENCE", "DECLINE_NO_FEASIBLE_STRUCTURE", "DECLINE_POLICY_HARD_STOP"}
DECISIONS = f"module2/{RUN}/strategy/04_GOVERNED_FINAL_DECISION.csv"
DAILY = f"module2/{RUN}/continuation/relational/msbf_m2.advance_daily_remittance_monitoring.csv"
FIELDS = ["merchant_key", "baseline_decision", "baseline_day_120_balance_usd",
          "recession_energy_decision", "recession_energy_day_120_balance_usd"]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def application(row):
    match = re.fullmatch(re.escape(COHORT) + r"_(M\d{6})_A01", row["merchant_application_id"])
    require(match and row["scenario_code"] in SCENARIOS and str(row["module1_run_id"]) == "1",
            "Unexpected cohort, scenario, or run")
    return match[1], row["scenario_code"]


def reproduce(source):
    with source.open("rb") as f:
        digest = hashlib.sha256()
        for block in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(block)
    require(digest.hexdigest() == RETURN_SHA, "Return archive identity differs")
    decisions, days, balances = {}, set(), {}
    with ZipFile(source) as archive:
        with archive.open(DECISIONS) as f:
            for row in csv.DictReader(io.TextIOWrapper(f, encoding="utf-8-sig", newline="")):
                key = application(row)
                require(key not in decisions, "Duplicate decision")
                decisions[key] = row["governed_final_outcome_code"]
        with archive.open(DAILY) as f:
            for record in csv.DictReader(io.TextIOWrapper(f, encoding="utf-8-sig", newline="")):
                row = json.loads(record["payload"], parse_float=Decimal)
                key, day = application(row), int(row["monitoring_day_index"])
                require(decisions.get(key) in AUTHORIZED and 1 <= day <= 120 and
                        (key, day) not in days, "Unexpected daily monitoring key")
                days.add((key, day))
                if day == 120:
                    balances[key] = format(Decimal(row["receivable_balance_after"]), ".2f")
    require(len(days) == 18000 and len(decisions) == 1500 and len(balances) == 150,
            "Unexpected source counts")
    result = []
    for merchant in sorted({key[0] for key in decisions}):
        row = [merchant]
        for scenario in SCENARIOS:
            key = (merchant, scenario)
            row.extend([decisions[key], balances.get(key, "")])
        result.append(dict(zip(FIELDS, row)))
    return result


def recount(rows):
    require(len(rows) == 750 and len({r["merchant_key"] for r in rows}) == 750, "Expected 750 paired merchants")
    totals = {scenario: Counter() for scenario in SCENARIOS}
    paired = Counter()
    pairs_open = []
    for row in rows:
        funded, opened = [], []
        for scenario in SCENARIOS:
            prefix = scenario.lower()
            decision = row[prefix + "_decision"]
            balance = row[prefix + "_day_120_balance_usd"]
            require(decision in AUTHORIZED | REVIEWABLE | DECLINED, "Unknown decision")
            issued = bool(balance)
            require(issued == (decision in AUTHORIZED), "Decision and monitoring presence differ")
            if issued:
                require(Decimal(balance) >= 0, "Negative receivable")
            remains = issued and Decimal(balance) > 0
            counts = totals[scenario]
            counts["funded"] += issued
            counts["review"] += decision in REVIEWABLE
            counts["supportable"] += decision in AUTHORIZED | REVIEWABLE
            counts["declined"] += decision in DECLINED
            counts["open"] += remains
            funded.append(issued)
            opened.append(remains)
        if all(funded):
            paired["funded"] += 1
            paired["baseline_open"] += opened[0]
            paired["stress_open"] += opened[1]
            if opened[1]:
                pairs_open.append((row["merchant_key"], row["recession_energy_day_120_balance_usd"]))
    expected = [(115, 206, 321, 429, 5), (35, 59, 94, 656, 1)]
    for scenario, values in zip(SCENARIOS, expected):
        ordered = [totals[scenario][key] for key in ("funded", "review", "supportable", "declined", "open")]
        require(tuple(ordered) == values, "Unexpected totals for " + scenario)
    require(paired == {"funded": 35, "baseline_open": 0, "stress_open": 1} and
            pairs_open == [("M000462", "3743.44")], "Paired endpoint differs")
    return {"application_pairs": len(rows), **totals, "funded_in_both": paired}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--return-archive", type=Path, help="Rebuild and compare against the Local Take 4 return")
    args = parser.parse_args()
    source = Path(__file__).with_name("application_paths.csv")
    require(hashlib.sha256(source.read_bytes()).hexdigest() == EXHIBIT_SHA, "Public extract identity differs")
    with source.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        require(reader.fieldnames == FIELDS, "Public extract fields differ")
        rows = list(reader)
    report = recount(rows)
    if args.return_archive:
        require(reproduce(args.return_archive) == rows, "Source and published application paths differ")
        report["original_return_reconciliation"] = "PASS"
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
