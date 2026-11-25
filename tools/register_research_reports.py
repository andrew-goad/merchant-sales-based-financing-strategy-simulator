"""Register locally selected study workbooks for preview or a GitHub release."""
import argparse
import hashlib
import json
import os
import re
import tempfile
from pathlib import Path
from urllib.parse import quote
from urllib.request import Request, urlopen


PROJECT = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
RELEASES = f'https://github.com/{PROJECT}/releases/download'
RUNS = {
    '750': '750 · Local DBeaver',
    'take4': '750 · Local GUI',
    'aws750': '750 · AWS GUI',
    '2500': '2,500 · AWS PowerShell',
    '25000': '25,000 · AWS GUI',
}


def register(root, release_tag=None):
    reports = root / 'research-site' / 'reports'
    catalog = {}
    asset_names = set()
    for cohort in RUNS:
        folder = reports / cohort
        workbooks = {}
        if cohort in ('take4', 'aws750') and not folder.exists():
            catalog[cohort] = workbooks
            continue
        for file in sorted(folder.iterdir()):
            kind = file.suffix.lower()
            if kind not in ('.twbx', '.pbix') or not file.is_file():
                continue
            if kind in workbooks:
                raise ValueError(f'{folder} contains two {kind} workbooks. Place one selected workbook of each type in this folder.')
            filename = quote(file.name, safe='')
            if release_tag:
                if file.name.casefold() in asset_names:
                    raise ValueError(f'Each file in one release needs a distinct name: {file.name}')
                asset_names.add(file.name.casefold())
                workbooks[kind] = f'{RELEASES}/{quote(release_tag, safe="")}/{filename}'
            else:
                workbooks[kind] = f'reports/{cohort}/{filename}'
        catalog[cohort] = workbooks

    return write_catalog(reports, catalog)


def write_catalog(reports, catalog):
    # Replace the catalog after every selected file has been checked.
    target = reports / 'catalog.js'
    contents = 'window.MSBF_REPORTS = ' + json.dumps(catalog, indent=2) + ';\n'
    with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', newline='\n',
                                     dir=reports, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(contents)
        except BaseException:
            stream.close()
            temporary.unlink(missing_ok=True)
            raise
    try:
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
    return catalog


def verified_public_catalog(tag, checksum_path):
    """Map staged checksums to exact assets on the named public release."""
    asset_slots = {}
    for cohort, label in RUNS.items():
        stem = 'MSBF-' + label.replace(' · ', '-').replace(',', '').replace(' ', '-')
        for extension in ('.pbix', '.twbx'):
            asset_slots[stem + extension] = (cohort, extension)
    expected = {}
    for line in checksum_path.read_text(encoding='utf-8-sig').splitlines():
        match = re.fullmatch(r'([a-fA-F0-9]{64})  (.+)', line)
        if not match or match[2] not in asset_slots or match[2] in expected:
            raise ValueError(f'Unknown or duplicate workbook in {checksum_path}: {line!r}')
        expected[match[2]] = match[1].lower()
    if not expected:
        raise ValueError(f'No selected workbooks in {checksum_path}.')
    encoded_tag = quote(tag, safe='')
    api = f'https://api.github.com/repos/{PROJECT}/releases/tags/{encoded_tag}'
    with urlopen(Request(api, headers={'Accept': 'application/vnd.github+json'}), timeout=45) as stream:
        release = json.load(stream)
    if release.get('draft') or release.get('tag_name') != tag or not release.get('published_at'):
        raise ValueError(f'No published public release for {tag}.')
    assets = {asset['name']: asset for asset in release['assets']}
    catalog = {cohort: {} for cohort in RUNS}
    for filename, expected_hash in expected.items():
        url = f'{RELEASES}/{encoded_tag}/{filename}'
        asset = assets.get(filename, {})
        if asset.get('state') != 'uploaded' or asset.get('browser_download_url') != url:
            raise ValueError(f'{filename} is unavailable at its expected URL in release {tag}.')
        digest = asset.get('digest')
        if not digest:
            # Older release assets may omit the digest. Check the published bytes.
            with urlopen(url, timeout=60) as stream:
                h = hashlib.sha256()
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    h.update(block)
            digest = 'sha256:' + h.hexdigest()
        if digest != 'sha256:' + expected_hash:
            raise ValueError(f'{filename} differs from its staged checksum.')
        cohort, extension = asset_slots[filename]
        catalog[cohort][extension] = url
    return catalog


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--release-tag', help='The published release tag containing your selected, identically named assets. Omit for local review.')
    mode.add_argument('--published-assets', metavar='TAG', help='Read and verify the selected workbook assets on this public GitHub release.')
    parser.add_argument('--checksums', type=Path, help='Local SHA256SUMS.txt from workbook staging; required with --published-assets.')
    args = parser.parse_args()
    if bool(args.published_assets) != bool(args.checksums):
        parser.error('--published-assets and --checksums must be supplied together.')
    root = Path(__file__).resolve().parent.parent
    try:
        if args.published_assets:
            catalog = verified_public_catalog(args.published_assets, args.checksums)
            write_catalog(root / 'research-site' / 'reports', catalog)
        else:
            catalog = register(root, args.release_tag)
    except (ValueError, OSError) as problem:
        raise SystemExit(str(problem))
    for cohort, workbooks in catalog.items():
        included = ', '.join(sorted(workbooks)) or 'no workbooks staged'
        print(f'{RUNS[cohort]} — {included}')
