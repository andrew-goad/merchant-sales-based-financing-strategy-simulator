"""Compare the GitHub and Pages study exhibits with their companion CSV extracts."""
import re
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
        self.transition_tables = {}
        self.default_studies = []
        self.mastheads = []
        self.study = None
        self.funding = self.in_masthead = False
        self.active_table = None
        self.abstract_tables = []
        self.portfolio_tables = []
        self.abstract_caption = []
        self.in_abstract_caption = False
        self.in_abstract_figure = False
        self.abstract_lead_depth = 0
        self.abstract_lead = []
        self.cell = None
        self.row = []

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        classes = attrs.get("class", "").split()
        if tag == "figure" and "abstract-result" in classes:
            self.in_abstract_figure = True
        elif tag == "figcaption" and self.in_abstract_figure:
            self.in_abstract_caption = True
        elif tag == "div" and (self.abstract_lead_depth or "abstract-lead" in classes):
            self.abstract_lead_depth += 1
        elif tag == "table" and self.in_abstract_figure:
            self.active_table = []
            self.abstract_tables.append(self.active_table)
        elif tag == "table" and "portfolio-comparison" in classes:
            if self.study != "25000":
                raise ValueError("The full-versus-matched comparison belongs to the 25,000 campaign")
            self.active_table = []
            self.portfolio_tables.append(self.active_table)
        elif tag == "input" and attrs.get("name") == "study" and attrs.get("type") == "radio":
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
        elif tag == "table" and "data-transition-matrix" in attrs:
            if not self.funding or self.study in self.transition_tables:
                raise ValueError(f"Expected one transition matrix in the financing results for {self.study}")
            self.transition_tables[self.study] = self.active_table = []
        elif tag == "table" and self.funding and "metric-table" in classes:
            if self.study in self.tables:
                raise ValueError(f"Duplicate policy table for {self.study}")
            self.tables[self.study] = self.active_table = []
        elif self.active_table is not None and tag == "tr":
            self.row = []
        elif self.active_table is not None and tag in ("td", "th"):
            self.cell = []

    def handle_data(self, text):
        if self.in_abstract_caption:
            self.abstract_caption.append(text)
        if self.abstract_lead_depth:
            self.abstract_lead.append(text)
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
        elif tag == "figcaption":
            self.in_abstract_caption = False
        elif tag == "figure":
            self.in_abstract_figure = False
        elif tag == "div" and self.abstract_lead_depth:
            self.abstract_lead_depth -= 1
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


def check_transition_tables(page, records):
    groups = ["Authorized", "Review only", "Declined"]
    evidence = rows("governed_decision_transitions.csv")
    expected_studies = {"750", "take4", "2500", "25000"}
    if set(page.transition_tables) != expected_studies:
        raise ValueError("The financing results must contain the four published decision matrices")
    for _, _, study, pair in records:
        if study not in expected_studies:
            continue
        table = page.transition_tables[study]
        if (len(table) != 4 or table[0] != ["Baseline decision", *groups]
                or [row[0] for row in table[1:]] != groups or any(len(row) != 4 for row in table[1:])):
            raise ValueError(f"{study}: expected labeled decision groups on both axes")
        observed = [[int(cell.replace(",", "")) for cell in row[1:]] for row in table[1:]]
        for totals, scenario in zip(pair, (observed, zip(*observed)), strict=True):
            expected = [totals.funded, totals.supportable - totals.funded, totals.applications - totals.supportable]
            if [sum(line) for line in scenario] != expected:
                raise ValueError(f"{study}: matrix margins differ from the funding, review and decline counts")
        # The historical DBeaver extract provides both margins. The other three
        # studies also publish joint counts for each of the nine transitions.
        if study != "750":
            source = {(r["baseline_disposition"], r["recession_energy_disposition"]): int(r["matched_applications"])
                      for r in evidence if int(r["cohort_merchants"]) == pair[0].applications}
            if observed != [[source[base, stress] for stress in groups] for base in groups]:
                raise ValueError(f"{study}: displayed decision transitions differ from the campaign extract")


def check_abstract(page, markdown):
    paths = rows("funded_paths_25000.csv")
    sides = [scenario.lower() for scenario in SCENARIOS]
    matched = [row for row in paths if all(row[f"{side}_principal_usd"] for side in sides)]
    changed = sum(Decimal(row["baseline_principal_usd"]) != Decimal(row["recession_energy_principal_usd"])
                  for row in matched)
    table = [["Funded group", "Baseline", "Energy stress"]]
    portfolio_table = [["Funded group", "Baseline", "Recession Energy"]]
    fractions, shares, matched_open = [], [], []
    for label, group in (("All funded in each scenario", paths), ("Same businesses funded in both", matched)):
        cells = [label]
        portfolio_cells = [label]
        for side in sides:
            balances = [Decimal(r[f"{side}_day120_receivable_usd"]) for r in group if r[f"{side}_principal_usd"]]
            opened = sum(balance > 0 for balance in balances)
            share = f"{opened / len(balances):.2%}"
            fraction = f"{opened:,} / {len(balances):,}"
            cells.append(f"{share} {fraction}")
            portfolio_cells.append(f"{fraction} ({share})")
            shares.append(share)
            if group is paths:
                fractions.append(f"{opened:,} of {len(balances):,}")
            else:
                matched_open.append(f"{opened:,}")
        table.append(cells)
        portfolio_table.append(portfolio_cells)
    if page.portfolio_tables != [portfolio_table]:
        raise ValueError(f"25,000 portfolio results differ from the funded paths. Expected {portfolio_table}")
    case_numbers = re.findall(r"\b[\d,]+\b", " ".join(page.abstract_caption))
    if case_numbers != ["25,000", matched_open[1], matched_open[0]]:
        raise ValueError(f"Pages headline should report {matched_open[1]} still owing under stress, up from {matched_open[0]}")
    if page.abstract_tables != [table]:
        raise ValueError(f"Pages abstract differs from the 25,000 funded paths. Expected {table}")

    abstract = markdown.partition("## Research abstract\n")[2].partition("\n## ")[0].replace("*", "")
    expected_counts = [*fractions, f"same {len(matched):,} businesses", " to ".join(matched_open),
                       f"{changed:,} received different advance amounts"]
    if not all(number in abstract for number in expected_counts) or re.findall(r"\d+(?:\.\d+)?%", abstract) != shares:
        raise ValueError(f"README abstract differs from the 25,000 funded paths. Expected {expected_counts}, {shares}")

    account = next(row for row in rows("funding_pairs.csv") if row["merchant_key"] == "M000462")
    trace = rows("merchant_000462.csv")
    payoff = min(int(row["day"]) for row in trace if Decimal(row["baseline_receivable_usd"]) == 0)
    endpoint = max(trace, key=lambda row: int(row["day"]))
    advance = Decimal(account["baseline_principal_usd"])
    if advance != Decimal(account["recession_energy_principal_usd"]):
        raise ValueError("Merchant 000462 no longer has identical funded principal across scenarios")
    facts = [f"${advance:,.0f}", f"day {payoff}", f"${Decimal(endpoint['recession_energy_receivable_usd']):,.2f}",
             f"day {endpoint['day']}"]
    case = markdown.partition(f"## Repayment on a ${advance:,.0f} equipment-repair advance\n")[2].partition("\n## ")[0]
    lead = "".join(page.abstract_lead)
    if not all(fact in case and fact in lead for fact in facts):
        raise ValueError(f"Merchant 000462 opening differs from its ledger. Expected {facts}")


def check_pages(html, records=None, markdown=None):
    page = StudyPage()
    page.feed(html)
    page.close()
    records = records or studies()
    check_abstract(page, README.read_text(encoding="utf-8") if markdown is None else markdown)
    check_transition_tables(page, records)
    labels = {key: " ".join(parts) for key, parts in page.selector_labels.items()}
    expected_labels = {key: name.replace(" · ", " ") for name, _, key, _ in records}
    if labels != expected_labels:
        raise ValueError(f"Study selector labels differ\nExpected {expected_labels}\nObserved {labels}")
    expected_studies = {key for _, _, key, _ in records}
    if set(page.tables) != expected_studies or set(page.captions) != expected_studies:
        raise ValueError("Pages must have a funding table and a selectable caption for each of the five studies")
    if len(page.default_studies) != 1 or len(page.mastheads) != 1:
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
    markdown = README.read_text(encoding="utf-8")
    check(markdown, records)
    check_pages((ROOT / "research-site/index.html").read_text(encoding="utf-8"), records, markdown)
    print("PASS README and Pages abstracts against the funded portfolios, matched merchants and merchant 000462 ledger")
    print("PASS decision transitions in the financing results, including all 27 published joint counts")
    print("PASS five README study rows, five selector labels, ten Pages scenario columns, five selectable mastheads and the default masthead")
