"""Check the published HTML's local dependencies and registered report downloads."""

import csv
import io
import json
import re
from base64 import b64decode
from hashlib import sha256
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


SITE = Path(__file__).resolve().parents[1] / "research-site"
ROUTES = {
    "750a": "750",
    "750b": "take4",
    "750c": "aws750",
    "2500": "2500",
    "25000": "25000",
}
# Byte lengths of the saved workbooks on the November research release.
# Keep the displayed MiB values tied to the same assets as the static URLs.
WORKBOOK_ASSETS = {
    "750": ("MSBF-750-Local-DBeaver", 368319, 27605824),
    "take4": ("MSBF-750-Local-GUI", 372287, 29423307),
    "aws750": ("MSBF-750-AWS-GUI", 367746, 29101487),
    "2500": ("MSBF-2500-AWS-PowerShell", 988984, 94845642),
    "25000": ("MSBF-25000-AWS-GUI", 8293317, 922390240),
}


class ResearchPage(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
        self.studies = set()
        self.current_study = None
        self.film_links = {}
        self.players = {}
        self.current_player = None
        self.template_study = None
        self.film_transcripts = {}
        self.anchors = []
        self.current_anchor = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            ident = attrs["id"]
            if ident in self.ids:
                raise ValueError(f"Duplicate HTML id {ident!r}")
            self.ids.add(ident)
        if tag == "article" and "data-study" in attrs:
            self.studies.add(attrs["data-study"])
            self.current_study = attrs["data-study"]
        if tag == "a" and attrs.get("href"):
            self.current_anchor = (self.current_study, attrs, [])
            self.anchors.append(self.current_anchor)
        if tag == "template" and "data-spoken" in attrs:
            self.template_study = self.current_study
            self.film_transcripts[self.template_study] = []
        if tag == "a" and "data-study-film" in attrs:
            key = attrs["data-study-film"]
            if key in self.film_links or self.current_study != ROUTES.get(key):
                raise ValueError(f"Duplicate or misplaced campaign film link: {key}")
            self.film_links[key] = attrs
        if tag == "video":
            self.current_player = attrs.get("id")
            self.players[self.current_player] = {}
        if self.current_player and tag in {"source", "track"}:
            self.players[self.current_player][tag] = attrs.get("src")

        for attr in ("href", "src", "poster"):
            if attrs.get(attr):
                self.links.append(attrs[attr])

    def handle_data(self, data):
        if self.current_anchor is not None:
            self.current_anchor[2].append(data)
        if self.template_study is not None:
            self.film_transcripts[self.template_study].append(data)

    def handle_endtag(self, tag):
        if tag == "a":
            self.current_anchor = None
        if tag == "template":
            self.template_study = None
        if tag == "article":
            self.current_study = None
        if tag == "video":
            self.current_player = None


def check_narrated_films(page):
    films = json.loads((SITE / "evidence" / "film_assets.json").read_text(encoding="utf-8"))
    shared = {"mechanics", "research", "architecture", "gui"}
    if set(films) != set(ROUTES) | shared or set(page.film_links) != set(ROUTES):
        raise ValueError("The five campaign routes and four shared films must match the film inventory.")
    if set(page.players) != {name + "-player" for name in shared} | {"cohort-player"}:
        raise ValueError("The four shared players and the cohort player must match the film inventory.")
    for key, assets in films.items():
        wanted = {}
        for kind in ("video", "captions", "transcript"):
            file = assets[kind]
            path = SITE / file["path"]
            if not path.resolve().is_relative_to(SITE / "media") or sha256(path.read_bytes()).hexdigest() != file["sha256"]:
                raise ValueError(f"{key} has the wrong {kind}: {file['path']}")
            wanted[kind] = file["path"]
        if key in ROUTES:
            link = page.film_links[key]
            if link.get("href") != f"#{key}/film" or any(link.get("data-" + kind) != path for kind, path in wanted.items()):
                raise ValueError(f"The {key} campaign route does not open its approved film, captions and transcript.")
            inline_captions = b64decode(link["data-captions-inline"], validate=True)
            if sha256(inline_captions).hexdigest() != assets["captions"]["sha256"]:
                raise ValueError(f"The {key} offline captions differ from the film's caption file.")
            transcript = (SITE / wanted["transcript"]).read_text(encoding="utf-8-sig")
            displayed = " ".join(page.film_transcripts[ROUTES[key]])
            if displayed.split() != transcript.split():
                raise ValueError(f"The {key} visible transcript differs from the download.")
        else:
            player = page.players[key + "-player"]
            if player != {"source": wanted["video"], "track": wanted["captions"]} or wanted["transcript"] not in page.links:
                raise ValueError(f"The {key} player does not reference its approved media.")
    print("PASS five campaign film routes, four shared films and 27 film, caption and transcript hashes, including offline captions and displayed campaign transcripts")


def check_local_reference(value, origin, pages):
    url = urlsplit(value)
    if url.scheme or url.netloc:
        return
    path = unquote(url.path)
    target = (origin.parent / path).resolve() if path else origin
    if target.is_dir():
        target = target / "index.html"
    if path.startswith("/") or not target.is_relative_to(SITE) or not target.is_file():
        raise ValueError(f"{origin.relative_to(SITE)} links to a missing file or path outside Pages: {value}")
    if url.fragment and target in pages:
        page = pages[target]
        fragment = unquote(url.fragment)
        if fragment in page.ids:
            return
        cohort, sep, section = fragment.partition("/")
        if target == SITE / "index.html" and cohort in ROUTES:
            if not sep or (section == "film" and cohort in page.film_links) or (section in {"top", "main", "project", "sources"} and section in page.ids):
                return
            if f"{section}-{ROUTES[cohort]}" in page.ids:
                return
        raise ValueError(f"Unknown cohort or section in link: {value}")


def check_reader_downloads(index, guide):
    tag_source = (SITE / "operator-release.js").read_text(encoding="utf-8")
    tag = re.search(r'''MSBF_OPERATOR_RELEASE_TAG\s*=\s*['"]([^'"]+)['"]''', tag_source)
    if not tag:
        raise ValueError("Missing Windows operator release tag")
    releases = "https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download"
    prefix = f"{releases}/{tag[1]}/"
    operator = prefix + "MSBF_Portable_Windows_RC21_A3.zip"
    if operator not in guide.links or operator + ".sha256" not in guide.links:
        raise ValueError("Windows guide must link to the published operator and its SHA-256")
    for cohort, (name, tableau_bytes, powerbi_bytes) in WORKBOOK_ASSETS.items():
        anchors = [(attrs, "".join(label)) for study, attrs, label in index.anchors if study == cohort]
        urls = [attrs["href"] for attrs, _ in anchors]
        viz = f"https://public.tableau.com/app/profile/andrew.goad/viz/{name}/RiskDecisionScenarioReview"
        if not {operator, "experiment.html", "experiment.html#parameters", viz}.issubset(urls):
            raise ValueError(f"{cohort}: missing operator, setup, parameter or browser report link")
        for ext, nbytes in ((".twbx", tableau_bytes), (".pbix", powerbi_bytes)):
            matches = [(attrs, label) for attrs, label in anchors if attrs.get("data-workbook") == ext]
            if len(matches) != 1:
                raise ValueError(f"{cohort}: expected one static {ext} download")
            attrs, label = matches[0]
            if (attrs["href"] != prefix + name + ext or attrs.get("data-bytes") != str(nbytes)
                    or f"{nbytes / 1048576:.2f} MiB" not in label):
                raise ValueError(f"{cohort}: incorrect published {ext} download or display size")

    populations = {"take4": 750, "2500": 2500, "25000": 25000}
    categories = {"Authorized", "Review only", "Declined"}
    matrices = [(study, attrs, "".join(label)) for study, attrs, label in index.anchors
                if (attrs.get("download") or "").startswith("decision_transitions_")]
    if len(matrices) != 3 or {study for study, _, _ in matrices} != set(populations):
        raise ValueError("Expected one downloadable transition table for each of three studies")
    for study, attrs, label in matrices:
        encoding, data = attrs["href"].split(",", 1)
        text = b64decode(data, validate=True).decode() if ";base64" in encoding else unquote(data)
        rows = list(csv.DictReader(io.StringIO(text)))
        transitions = {(row["baseline_disposition"], row["recession_energy_disposition"]) for row in rows}
        if (label != "Download the 3 × 3 decision-transition counts (CSV)" or len(rows) != 9
                or transitions != {(base, stress) for base in categories for stress in categories}
                or sum(int(row["matched_applications"]) for row in rows) != populations[study]):
            raise ValueError(f"{study}: decision-transition download label, cells or total differ")
    print("PASS Windows guide, five Tableau Public links, ten workbook sizes and three 3 × 3 CSVs")


def check_site():
    pages = {}
    for file in sorted(SITE.rglob("*.html")):
        page = ResearchPage()
        page.feed(file.read_text(encoding="utf-8"))
        page.close()
        pages[file] = page
    index = SITE / "index.html"
    if pages[index].studies != set(ROUTES.values()):
        raise ValueError("The site and the five cohort routes disagree")
    check_narrated_films(pages[index])
    check_reader_downloads(pages[index], pages[SITE / "experiment.html"])
    for file, page in pages.items():
        for link in sorted(set(page.links)):
            check_local_reference(link, file, pages)

    assignment = (SITE / "reports/catalog.js").read_text(encoding="utf-8").strip()
    prefix = "window.MSBF_REPORTS = "
    if not assignment.startswith(prefix) or not assignment.endswith(";"):
        raise ValueError("Unrecognized report catalog format")
    catalog = json.loads(assignment[len(prefix):-1])
    if set(catalog) != pages[index].studies:
        raise ValueError("The study selector and the report catalog disagree")
    count = 0
    for cohort, entries in catalog.items():
        for kind, link in entries.items():
            url = urlsplit(link)
            if kind not in (".pbix", ".twbx") or Path(unquote(url.path)).suffix.lower() != kind:
                raise ValueError(f"Wrong workbook type for {cohort}: {link}")
            if url.scheme or url.netloc:
                if url.scheme != "https" or not url.netloc:
                    raise ValueError(f"Invalid download URL for {cohort}: {link}")
            else:
                check_local_reference(link, index, pages)
            count += 1
    print(f"PASS: local links and anchors across {len(pages)} HTML pages, five study routes, {count} registered workbook URLs")


if __name__ == "__main__":
    check_site()
