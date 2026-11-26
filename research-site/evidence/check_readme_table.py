"""Compare the GitHub and Pages study exhibits with their companion CSV extracts."""
from dataclasses import dataclass
from decimal import Decimal
from html.parser import HTMLParser
from itertools import takewhile
from pathlib import Path

from verify_studies import CASES, rows

ROOT = Path(__file__).resolve().parents[2]
README = ROOT / "README.md"
SITE = "https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/"
SCENARIOS = ("BASELINE", "RECESSION_ENERGY")
HEADER = "| Study | Supportable | Funded | Open / funded at day 120 | Daily monitoring records |"


@dataclass(frozen=True)
class Counts:
    applications: int
    supportable: int
    funded: int
    opened: int | None
    daily: int
    principal: Decimal


def summary_counts(filename):
    by_scenario = {row["scenario"]: row for row in rows(filename)}
    scenarios = []
    for scenario in SCENARIOS:
        row = by_scenario[scenario]
        opened = int(row["open_accounts"]) if "open_accounts" in row else None
        scenarios.append(Counts(int(row["applications"]), int(row["supportable"]), int(row["funded"]),
                                opened, int(row["daily_monitoring_rows"]), Decimal(row["funded_principal_usd"])))
    return scenarios


def ledger_counts(size):
    decisions = [row for row in rows("decision_counts.csv") if int(row["merchants"]) == size]
    local = size == 750
    paths = rows("application_paths.csv" if local else f"funded_paths_{size}.csv")
    principal_rows = rows("funding_pairs.csv") if local else paths
    balance_field = "day_120_balance_usd" if local else "day120_receivable_usd"
    days = sum(int(row["day"]) > 0 for row in rows(f"merchant_{CASES[size][0]}.csv"))
    scenarios = []
    for scenario in SCENARIOS:
        outcomes = {row["governed_outcome"]: int(row["applications"]) for row in decisions
                    if row["scenario"] == scenario}
        supportable = sum(n for outcome, n in outcomes.items()
                          if outcome.endswith(("_AUTHORIZED", "_REVIEW_REQUIRED")))
        side = scenario.lower()
        balances = (row[f"{side}_{balance_field}"] for row in paths)
        funded = [Decimal(value) for value in balances if value]
        principal = sum(Decimal(row[f"{side}_principal_usd"] or "0") for row in principal_rows)
        scenarios.append(Counts(sum(outcomes.values()), supportable, len(funded),
                                sum(value > 0 for value in funded), days * len(funded), principal))
    return scenarios


def studies():
    return [
        ("750 · Local DBeaver", "750a", "750", summary_counts("official_750_r26_summary.csv")),
        ("750 · Local GUI", "750b", "take4", ledger_counts(750)),
        ("750 · AWS GUI", "750c", "aws750", summary_counts("aws_750_take1_summary.csv")),
        ("2,500 · AWS PowerShell", "2500", "2500", ledger_counts(2500)),
        ("25,000 · AWS GUI", "25000", "25000", ledger_counts(25000)),
    ]


def check(markdown, records=None):
    lines = markdown.splitlines()
    if lines.count(HEADER) != 1:
        raise ValueError("Expected exactly one study comparison table in README.md")
    start = lines.index(HEADER) + 2
    table = [line.strip("|").split("|") for line in takewhile(lambda s: s.startswith("|"), lines[start:])]
    for row, (name, route, _, pair) in zip(table, records or studies(), strict=True):
        endpoint = "Not reported" if all(c.opened is None for c in pair) else " → ".join(
            f"{c.opened:,}/{c.funded:,}" for c in pair)
        slug = name.replace(" · ", "-").replace(",", "").replace(" ", "-")
        viz = f"https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-{slug}/RiskDecisionScenarioReview"
        expected = [f"[{name}]({SITE}#{route}/repayment) · [Explore in Tableau]({viz})", " → ".join(f"{c.supportable:,}" for c in pair),
                    " → ".join(f"{c.funded:,}" for c in pair), endpoint, f"{sum(c.daily for c in pair):,}"]
        observed = [cell.strip() for cell in row]
        if observed != expected:
            raise ValueError(f"README study mismatch\nExpected {expected}\nObserved {observed}")


class StudyPage(HTMLParser):
    """Collect the policy tables, the default masthead and the captions the selector displays."""
    def __init__(self):
        super().__init__()
        self.captions = {}
        self.selector_labels = {}
        self.selected_input = None
        self.tables = {}
        self.balance_tables = {}
        self.active_table = None
        self.default_studies = []
        self.mastheads = []
        self.study = None
        self.funding = self.in_masthead = False
        self.cell = None
        self.row = []

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag == "input" and attrs.get("name") == "study" and attrs.get("type") == "radio":
            self.selected_input = attrs["value"]
            if self.selected_input in self.selector_labels:
                raise ValueError(f"Duplicate study selector {self.selected_input}")
            self.selector_labels[self.selected_input] = []
        elif tag == "article" and "data-study" in attrs:
            self.study = attrs["data-study"]
            if self.study in self.captions:
                raise ValueError(f"Duplicate Pages study {self.study}")
            self.captions[self.study] = attrs["data-caption"]
            if "hidden" not in attrs:
                self.default_studies.append(self.study)
        elif tag == "p" and attrs.get("id") == "study-summary":
            self.in_masthead = True
            self.mastheads.append("")
        elif tag == "section" and self.study:
            self.funding = attrs.get("data-place") == "funding"
        elif tag == "table" and "data-portfolio-study" in attrs:
            location = (self.study, attrs["data-portfolio-study"])
            if location in self.balance_tables:
                raise ValueError(f"Duplicate day-120 comparison for {location}")
            self.active_table = self.balance_tables[location] = []
        elif tag == "table" and self.funding and "metric-table" in attrs.get("class", "").split():
            if self.study in self.tables:
                raise ValueError(f"Duplicate policy table for {self.study}")
            self.active_table = self.tables[self.study] = []
        elif self.active_table is not None and tag == "tr":
            self.row = []
        elif self.active_table is not None and tag in ("td", "th"):
            self.cell = []

    def handle_data(self, text):
        if self.selected_input is not None and text.strip():
            self.selector_labels[self.selected_input].append(text.strip())
        if self.in_masthead:
            self.mastheads[-1] += text
        if self.cell is not None:
            self.cell.append(text)

    def handle_endtag(self, tag):
        if tag == "label":
            self.selected_input = None
        if self.active_table is not None and tag in ("td", "th"):
            self.row.append(" ".join(" ".join(self.cell).split()))
            self.cell = None
        elif self.active_table is not None and tag == "tr":
            self.active_table.append(self.row)
        elif tag == "table":
            self.active_table = None
        elif tag == "section":
            self.funding = False
        elif tag == "article":
            self.study = None
        elif tag == "p":
            self.in_masthead = False


def policy_table(pair, funded_label):
    return [
        ["Policy outcome", "Baseline", "Recession Energy"],
        ["All applications", *(f"{c.applications:,}" for c in pair)],
        ["Supportable", *(f"{c.supportable:,} ({c.supportable / c.applications:.1%})" for c in pair)],
        [funded_label, *(f"{c.funded:,}" for c in pair)],
        ["Sent for review", *(f"{c.supportable - c.funded:,}" for c in pair)],
        ["Declined", *(f"{c.applications - c.supportable:,}" for c in pair)],
        ["Principal funded", *(f"${c.principal:,.0f}" for c in pair)],
    ]


def matched_counts(study):
    if study == "aws750":
        return None  # The saved AWS summary provides scenario totals only.
    if study == "750":
        # Published DBeaver cohort validation, pp. 13, 19, 22–24 (matched 27).
        return [(1, 27), (0, 27)]
    if study == "take4":
        records = rows("application_paths.csv")
        suffix = "day_120_balance_usd"
    else:
        records = rows(f"funded_paths_{study}.csv")
        suffix = "day120_receivable_usd"
    columns = [f"{scenario.lower()}_{suffix}" for scenario in SCENARIOS]
    matched = [record for record in records if all(record[column] != "" for column in columns)]
    return [(sum(Decimal(record[column]) > 0 for record in matched), len(matched)) for column in columns]


def check_balance_tables(page, records):
    expected = {(key, key) for _, _, key, _ in records} | {("take4", "25000")}
    if set(page.balance_tables) != expected:
        raise ValueError("Day-120 comparisons must belong to their study, plus the separate 25,000 exhibit in Local GUI 750")
    groups = {}
    for _, _, key, counts in records:
        groups[key] = [("All funded in each scenario", [(scenario.opened, scenario.funded) for scenario in counts])]
        matched = matched_counts(key)
        if matched:
            groups[key].append((f"Same {matched[0][1]:,} funded in both", matched))
    for (article, study), table in page.balance_tables.items():
        context = f"{article} article, {study} day-120 exhibit"
        if table[0][1:] != ["Baseline", "Recession Energy"]:
            raise ValueError(f"{context}: missing or misordered scenarios")
        for row, (label, group) in zip(table[1:], groups[study], strict=True):
            cells = [label]
            for owed, funded in group:
                percent = f"{owed / funded:.2%}" if owed else "0%"
                cells.append(f"{owed:,} / {funded:,} {percent}")
            if row != cells:
                raise ValueError(f"{context}: expected {cells}, observed {row}")


def check_pages(html, records=None):
    page = StudyPage()
    page.feed(html)
    page.close()
    records = records or studies()
    check_balance_tables(page, records)
    labels = {key: " ".join(parts) for key, parts in page.selector_labels.items()}
    expected_labels = {key: name.replace(" · ", " ") for name, _, key, _ in records}
    if labels != expected_labels:
        raise ValueError(f"Study selector labels differ\nExpected {expected_labels}\nObserved {labels}")
    expected_studies = {key for _, _, key, _ in records}
    if set(page.tables) != expected_studies or set(page.captions) != expected_studies:
        raise ValueError("Pages must have a funding table and a selectable caption for each of the five studies")
    if page.default_studies != ["take4"] or len(page.mastheads) != 1:
        raise ValueError("Expected one default study and one visible study-summary masthead")
    for name, _, key, pair in records:
        funded_label = "Authorized and funded" if key in ("750", "aws750") else "Funded"
        expected = policy_table(pair, funded_label)
        if page.tables[key] != expected:
            raise ValueError(f"Pages {name} policy table mismatch\nExpected {expected}\nObserved {page.tables[key]}")
        counts = f"{sum(c.applications for c in pair):,} decisions · {sum(c.daily for c in pair):,} daily monitoring records"
        if key == "750" and page.captions[key] != counts:
            raise ValueError(f"The original DBeaver study reports only its decision and monitoring counts: {counts}")
        if page.captions[key].split(" · ", 2)[:2] != counts.split(" · "):
            raise ValueError(f"Pages {name} masthead should begin with {counts}")
    if page.mastheads[0].strip() != page.captions[page.default_studies[0]]:
        raise ValueError("Default study masthead and the caption used by the campaign selector disagree")


if __name__ == "__main__":
    records = studies()
    check(README.read_text(encoding="utf-8"), records)
    check_pages((ROOT / "research-site/index.html").read_text(encoding="utf-8"), records)
    print("PASS day-120 funded and matched counts, denominators and rates in six portfolio exhibits")
    print("PASS five README study rows, five selector labels, ten Pages scenario columns, five selectable mastheads and the default masthead")
