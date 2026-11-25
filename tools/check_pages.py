"""Check the published HTML's local dependencies and registered report downloads."""

import json
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

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            ident = attrs["id"]
            if ident in self.ids:
                raise ValueError(f"Duplicate HTML id {ident!r}")
            self.ids.add(ident)
        if tag == "article" and "data-study" in attrs:
            self.studies.add(attrs["data-study"])
        for attr in ("href", "src", "poster"):
            if attrs.get(attr):
                self.links.append(attrs[attr])


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
            if not sep or (section in {"top", "main", "project", "sources"} and section in page.ids):
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
