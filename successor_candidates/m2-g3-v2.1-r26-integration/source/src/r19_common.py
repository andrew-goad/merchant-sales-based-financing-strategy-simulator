from __future__ import annotations

import base64
import csv
import hashlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def canonical_json_bytes(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')


def canonical_hash(value: Any) -> str:
    return sha256_bytes(canonical_json_bytes(value))


def normalize_pg_dump_schema_bytes(data: bytes) -> bytes:
    """Normalize only PostgreSQL 17's randomized psql guard tokens and line endings.

    PostgreSQL 17 schema-only dumps include random ``\\restrict`` / ``\\unrestrict``
    tokens. Those tokens are execution guards, not database state, and otherwise make
    two unchanged schema dumps hash differently. No SQL statement or identifier is
    removed or rewritten.
    """
    text = data.decode('utf-8-sig').replace('\r\n', '\n').replace('\r', '\n')
    lines = []
    for line in text.split('\n'):
        if re.match(r'^\\(?:un)?restrict(?:\s|$)', line):
            continue
        lines.append(line)
    return ('\n'.join(lines).rstrip('\n') + '\n').encode('utf-8')


def normalized_pg_dump_schema_sha256(data: bytes) -> str:
    return sha256_bytes(normalize_pg_dump_schema_bytes(data))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding='utf-8-sig'))


def qident(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def run(cmd: Sequence[str], *, env: dict[str, str] | None = None, cwd: Path | None = None,
        input_text: str | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    cp = subprocess.run(
        list(map(str, cmd)),
        cwd=str(cwd) if cwd else None,
        env=env,
        input=input_text,
        text=True,
        encoding='utf-8',
        errors='replace',
        capture_output=True,
    )
    if check and cp.returncode != 0:
        raise RuntimeError(
            f"Command failed ({cp.returncode}): {' '.join(map(str, cmd))}\n"
            f"STDOUT:\n{cp.stdout[-8000:]}\nSTDERR:\n{cp.stderr[-8000:]}"
        )
    return cp


@dataclass(frozen=True)
class PgTools:
    psql: Path
    createdb: Path
    dropdb: Path
    pg_dump: Path
    pg_restore: Path

    @classmethod
    def from_bin(cls, pg_bin: Path) -> 'PgTools':
        suffix = '.exe' if os.name == 'nt' else ''
        tools = cls(*(pg_bin / f'{name}{suffix}' for name in ('psql','createdb','dropdb','pg_dump','pg_restore')))
        for tool in (tools.psql, tools.createdb, tools.dropdb, tools.pg_dump, tools.pg_restore):
            if not tool.exists():
                raise FileNotFoundError(f'Missing PostgreSQL executable: {tool}')
        return tools


@dataclass
class PgContext:
    tools: PgTools
    host: str
    port: int
    user: str
    env: dict[str, str]

    def base(self, database: str) -> list[str]:
        return [str(self.tools.psql), '-h', self.host, '-p', str(self.port), '-U', self.user,
                '-d', database, '-X', '-v', 'ON_ERROR_STOP=1']

    def scalar(self, database: str, sql: str, *, read_only: bool = False) -> str:
        prefix = "SET default_transaction_read_only=on; " if read_only else ''
        cp = run(self.base(database) + ['-q', '-At', '-c', prefix + sql], env=self.env)
        return cp.stdout.strip()

    def script(self, database: str, sql: str, *, read_only: bool = False) -> str:
        prefix = "\\set ON_ERROR_STOP on\nSET default_transaction_read_only=on;\n" if read_only else "\\set ON_ERROR_STOP on\n"
        cp = run(self.base(database) + ['-q'], env=self.env, input_text=prefix + sql)
        return cp.stdout

    def copy_to_csv(self, database: str, query: str, *, read_only: bool = True) -> bytes:
        prefix = "SET default_transaction_read_only=on; " if read_only else ''
        sql = prefix + f"COPY ({query}) TO STDOUT WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');"
        cp = subprocess.run(
            self.base(database) + ['-q', '-c', sql], env=self.env,
            capture_output=True, check=False
        )
        if cp.returncode != 0:
            raise RuntimeError(
                f"COPY export failed ({cp.returncode}): {query}\n"
                f"STDOUT:\n{cp.stdout.decode('utf-8','replace')[-8000:]}\n"
                f"STDERR:\n{cp.stderr.decode('utf-8','replace')[-8000:]}"
            )
        return cp.stdout.replace(b'\r\n', b'\n')

    def relation_json_rows(self, database: str, schema: str, relation: str) -> list[dict[str, Any]]:
        target = f'{qident(schema)}.{qident(relation)}'
        sql = (
            "SELECT encode(convert_to(row_to_json(t)::text,'UTF8'),'base64') "
            f"FROM {target} AS t;"
        )
        cp = run(self.base(database) + ['-At', '-c', "SET default_transaction_read_only=on; " + sql], env=self.env)
        rows: list[dict[str, Any]] = []
        for line in cp.stdout.splitlines():
            if not line.strip():
                continue
            text = base64.b64decode(line.strip()).decode('utf-8')
            rows.append(json.loads(text))
        return rows

    def db_exists(self, database: str) -> bool:
        v = self.scalar('postgres', "SELECT count(*) FROM pg_database WHERE datname=" + sql_literal(database) + ';', read_only=True)
        return v == '1'

    def drop_database(self, database: str) -> None:
        if not self.db_exists(database):
            return
        self.scalar('postgres', f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname={sql_literal(database)} AND pid<>pg_backend_pid();")
        run([str(self.tools.dropdb), '-h', self.host, '-p', str(self.port), '-U', self.user, '--if-exists', database], env=self.env)

    def clone_database(self, source: str, target: str, scratch: Path) -> dict[str, Any]:
        if self.db_exists(target):
            raise RuntimeError(f'Target database already exists: {target}')
        # Fast path: template clone. Fall back to pg_dump/pg_restore if the source has a concurrent connection.
        cp = run([str(self.tools.createdb), '-h', self.host, '-p', str(self.port), '-U', self.user,
                  '-T', source, target], env=self.env, check=False)
        if cp.returncode == 0:
            return {'method': 'CREATE_DATABASE_TEMPLATE', 'source': source, 'target': target}
        dump_path = scratch / f'{target}.dump'
        run([str(self.tools.pg_dump), '-h', self.host, '-p', str(self.port), '-U', self.user,
             '-Fc', '--no-owner', '--no-privileges', '-f', str(dump_path), source], env=self.env)
        run([str(self.tools.createdb), '-h', self.host, '-p', str(self.port), '-U', self.user, target], env=self.env)
        run([str(self.tools.pg_restore), '-h', self.host, '-p', str(self.port), '-U', self.user,
             '-d', target, '--no-owner', '--no-privileges', str(dump_path)], env=self.env)
        dump_sha = sha256_file(dump_path)
        dump_path.unlink(missing_ok=True)
        return {'method': 'PG_DUMP_RESTORE', 'source': source, 'target': target, 'temporary_dump_sha256': dump_sha,
                'template_clone_stderr': cp.stderr[-4000:]}


def sql_literal(value: Any) -> str:
    if value is None:
        return 'NULL'
    if isinstance(value, bool):
        return 'TRUE' if value else 'FALSE'
    if isinstance(value, (int, float)):
        return str(value)
    s = str(value).replace("'", "''")
    return "'" + s + "'"


def rows_to_csv_bytes(rows: list[dict[str, Any]], columns: list[str]) -> bytes:
    sio = io.StringIO(newline='')
    writer = csv.DictWriter(sio, fieldnames=columns, extrasaction='ignore', lineterminator='\n')
    writer.writeheader()
    for row in rows:
        out: dict[str, Any] = {}
        for col in columns:
            value = row.get(col)
            if isinstance(value, (dict, list)):
                out[col] = json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)
            elif value is None:
                out[col] = ''
            elif isinstance(value, bool):
                out[col] = 'true' if value else 'false'
            else:
                out[col] = value
        writer.writerow(out)
    return sio.getvalue().encode('utf-8')


def copy_csv_into(pg: PgContext, database: str, table: str, columns: list[str], csv_bytes: bytes) -> None:
    csv_text = csv_bytes.decode('utf-8')
    cols = ','.join(qident(c) for c in columns)
    script = f"COPY {table} ({cols}) FROM STDIN WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');\n{csv_text}\\.\n"
    pg.script(database, script)


def zip_tree(root: Path, output_zip: Path) -> None:
    output_zip.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_zip, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in sorted(root.rglob('*')):
            if path.is_file():
                zf.write(path, path.relative_to(root.parent).as_posix())


def safe_extract_zip(path: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path) as zf:
        for info in zf.infolist():
            p = Path(info.filename)
            if p.is_absolute() or '..' in p.parts:
                raise RuntimeError(f'Unsafe ZIP member: {info.filename}')
        zf.extractall(dest)


def normalize_sha_sidecar(text: str) -> set[str]:
    import re
    return set(re.findall(r'(?i)\b[a-f0-9]{64}\b', text))
