"""Rebuild or check the four public file inventories against the staged Git tree."""
import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys
from tempfile import NamedTemporaryFile


INVENTORIES = ("MANIFEST.csv", "manifest.json", "SHA256SUMS.txt", "PACKAGE_INVENTORY.csv")


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args])


def collect_records(repo, tree):
    entries = []
    for raw in git(repo, "ls-tree", "-r", "-z", tree).split(b"\0"):
        if not raw:
            continue
        metadata, encoded_path = raw.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        path = encoded_path.decode("utf-8")
        if mode not in (b"100644", b"100755") or kind != b"blob":
            raise ValueError(f"Expected a regular file in the public tree at {path}")
        if path not in INVENTORIES:
            entries.append((path, oid))

    records = []
    hashes = {}
    command = ["git", "-C", str(repo), "cat-file", "--batch"]
    with subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE) as batch:
        try:
            for path, oid in sorted(entries, key=lambda e: PurePosixPath(e[0]).parts):
                if oid not in hashes:
                    batch.stdin.write(oid + b"\n")
                    batch.stdin.flush()
                    header = batch.stdout.readline().split()
                    if len(header) != 3 or header[:2] != [oid, b"blob"]:
                        raise ValueError(f"Git could not read the staged blob for {path}")
                    size = int(header[2])
                    remaining = size
                    digest = hashlib.sha256()
                    while remaining:
                        chunk = batch.stdout.read(min(remaining, 1024 * 1024))
                        if not chunk:
                            raise ValueError(f"Incomplete staged blob for {path}")
                        digest.update(chunk)
                        remaining -= len(chunk)
                    if batch.stdout.read(1) != b"\n":
                        raise ValueError(f"Malformed Git blob response for {path}")
                    hashes[oid] = size, digest.hexdigest()
                size, digest_hex = hashes[oid]
                records.append({"path": path, "size_bytes": size, "sha256": digest_hex})
        finally:
            batch.stdin.close()
            # Close the response pipe before waiting if an object read was interrupted.
            batch.stdout.close()
        if batch.wait() != 0:
            raise RuntimeError("Git could not finish reading the staged objects")
    return records


def csv_bytes(columns, rows):
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, columns, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue().encode("utf-8")


def render(records):
    package = []
    for row in records:
        path = PurePosixPath(row["path"])
        package.append({**row, "top_level_area": path.parts[0], "extension": path.suffix.lower()})
    return {
        "MANIFEST.csv": csv_bytes(["path", "size_bytes", "sha256"], records),
        "manifest.json": (json.dumps({"file_count": len(records), "files": records}, indent=2)
                          + "\n").encode("utf-8"),
        "SHA256SUMS.txt": "".join(f'{r["sha256"]}  {r["path"]}\n' for r in records).encode("utf-8"),
        "PACKAGE_INVENTORY.csv": csv_bytes(["path", "top_level_area", "extension", "size_bytes", "sha256"], package),
    }


def write_file(path, data):
    if path.is_file() and path.read_bytes() == data:
        return
    with NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
        temporary = Path(tmp.name)
        try:
            tmp.write(data)
        except BaseException:
            tmp.close()
            temporary.unlink(missing_ok=True)
            raise
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="write inventories of staged content into the checkout")
    mode.add_argument("--check", action="store_true", help="verify the staged inventories (default)")
    parser.add_argument("--repo", default=".", help="path inside the publication checkout (default: current directory)")
    args = parser.parse_args()
    repo = Path(os.fsdecode(git(args.repo, "rev-parse", "--show-toplevel")).strip())
    tree = git(repo, "write-tree").decode("ascii").strip()
    records = collect_records(repo, tree)
    rendered = render(records)
    if args.write:
        for name, data in rendered.items():
            write_file(repo / name, data)
        print(f"Generated four inventories from {len(records):,} staged files. Stage the four inventory files and run --check.")
        return 0
    mismatches = []
    for name, data in rendered.items():
        result = subprocess.run(["git", "-C", str(repo), "show", f"{tree}:{name}"],
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        if result.returncode or data != result.stdout:
            mismatches.append(name)
    if mismatches:
        print("Staged inventory differs: " + ", ".join(mismatches), file=sys.stderr)
        return 1
    print(f"PASS all four inventories match {len(records):,} staged public files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
