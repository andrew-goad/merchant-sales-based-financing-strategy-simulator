"""Maintain the two Pages reading guides.

Run --write with Pandoc installed after editing the canonical Markdown. Run
--check in CI with standard Python. UTF-8 and LF normalization make both
commands independent of Git's checkout newline settings.
"""

import argparse
import hashlib
from html import escape, unescape
import os
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import urlsplit

REPO = Path(__file__).resolve().parents[1]
SITE = REPO / "research-site"
SITE_URL = "https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/"
REPO_URL = "https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/blob/main/"
PAGES = {
    "PROJECT_GUIDE.md": ("PROJECT_GUIDE.html", "index.html#750b/project", "evidence/index.html", "Study evidence"),
    "evidence/STUDY_SOURCES.md": ("evidence/index.html", "../index.html#750b/evidence", "../PROJECT_GUIDE.html", "Project guide"),
}
CSS = """
:root{color-scheme:light;--ink:#16323d;--line:#bfd0cd;--accent:#006966}
*{box-sizing:border-box}body{margin:0;background:#faf9f5;color:var(--ink);font:1rem/1.6 system-ui,-apple-system,"Segoe UI",sans-serif}
header{border-bottom:1px solid var(--line);background:#fff} header div,main{width:min(62rem,calc(100% - 2.5rem));margin:auto}
header div{display:flex;flex-wrap:wrap;justify-content:space-between;gap:.4rem;padding:1rem 0}header a{font-weight:650;text-decoration:none}
a{color:var(--accent);text-underline-offset:.18em}a:hover{text-decoration:underline}a:focus-visible{outline:3px solid #af5918;outline-offset:3px}
main{padding:2.5rem 0 4rem}h1,h2,h3{font-family:Georgia,"Times New Roman",serif;line-height:1.15;letter-spacing:-.02em;font-weight:500}
h1{font-size:clamp(2.2rem,5vw,3.4rem);margin:0 0 1.3rem}h2{font-size:clamp(1.6rem,3vw,2.15rem);margin:2.1rem 0 .75rem}
p,li{max-width:78ch}h3{font-size:1.35rem}pre, code{font-family:ui-monospace,monospace;font-size:.9em}
pre{overflow:auto;background:#f0f2ee;border-left:.25rem solid var(--accent);padding:1rem}
table{border-collapse:collapse;width:100%;font-size:.94rem}th,td{padding:.6rem;text-align:left;border-bottom:1px solid var(--line);vertical-align:top}th{color:#15534f}
.table-wrap{overflow-x:auto;margin:1rem 0}main{overflow-wrap:anywhere}.table-wrap table{min-width:36rem}img{max-width:100%;height:auto}ol,ul{padding-left:1.5rem}
"""
def relative_url(path, directory):
    return Path(os.path.relpath(path, directory)).as_posix()


def local_link(href, source, destination):
    parsed = urlsplit(unescape(href))
    if href.startswith(SITE_URL):
        path = SITE / (parsed.path[len(urlsplit(SITE_URL).path):] or 'index.html')
    elif parsed.scheme or parsed.netloc or not parsed.path:
        return href
    else:
        path = (source.parent / parsed.path).resolve()
    if path.is_relative_to(SITE):
        key = path.relative_to(SITE).as_posix()
        if key in PAGES:
            path = SITE / PAGES[key][0]
        url = relative_url(path, destination.parent)
    else:
        url = REPO_URL + path.relative_to(REPO).as_posix()
    if parsed.query:
        url += '?' + parsed.query
    if parsed.fragment:
        url += '#' + parsed.fragment
    return escape(url, quote=True)


def render(source, destination, home, peer, peer_title, markdown):
    if not shutil.which("pandoc"):
        raise SystemExit("Install Pandoc to regenerate the guides. CI --check uses only Python.")
    body = subprocess.run(
        ["pandoc", "--from=gfm", "--to=html5", "--no-highlight", "--wrap=none"],
        input=markdown, text=True, encoding="utf-8", stdout=subprocess.PIPE, check=True
    ).stdout
    body = re.sub(r'(<a\b[^>]*? href=")([^"]*)(")',
                  lambda m: m[1] + local_link(m[2], source, destination) + m[3], body)
    body = re.sub(r'(<table\b)', r'<div class="table-wrap" tabindex="0" role="region" aria-label="Scrollable table">\1', body)
    body = body.replace('</table>', '</table></div>')
    title = escape(next(line[2:] for line in markdown.splitlines() if line.startswith('# ')))
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} · MSBF</title><style>{CSS}</style></head><body>
<header><div><a href="{home}">Return to the research</a><a href="{peer}">{peer_title}</a></div></header>
<main>{body}</main>
</body></html>
"""


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def stamp(markdown, body, renderer):
    return f"<!-- Source SHA-256 {digest(markdown)} / HTML SHA-256 {digest(body)} / Renderer SHA-256 {renderer} -->"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="Regenerate HTML with Pandoc.")
    mode.add_argument("--check", action="store_true", help="Validate source, HTML and renderer digests (default).")
    args = parser.parse_args()
    renderer = digest(Path(__file__).read_text(encoding='utf-8'))
    for key, (output, home, peer, peer_title) in PAGES.items():
        source = SITE / key
        destination = SITE / output
        markdown = source.read_text(encoding="utf-8")
        if args.write:
            body = render(source, destination, home, peer, peer_title, markdown)
            destination.write_text(body + stamp(markdown, body, renderer) + "\n", encoding='utf-8', newline='\n')
        else:
            content = destination.read_text(encoding="utf-8").rstrip("\n")
            body, separator, mark = content.rpartition("\n")
            if not separator or mark != stamp(markdown, body + "\n", renderer):
                raise SystemExit(f"{output} differs from its source or renderer. Run tools/render_research_guides.py --write.")
        print(f"{'WROTE' if args.write else 'PASS'} {output}")


if __name__ == "__main__":
    main()
