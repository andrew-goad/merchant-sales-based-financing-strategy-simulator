"""Check the published HTML's local dependencies and registered report downloads."""

import json
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
        if self.template_study is not None:
            self.film_transcripts[self.template_study].append(data)

    def handle_endtag(self, tag):
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
