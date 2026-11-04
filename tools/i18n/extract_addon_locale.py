#!/usr/bin/env python3
"""One-time import of the addon's zhCN table into the shared i18n catalogue.

After this runs, edit `shared/i18n/addon/addon.yaml` and run
`gen_addon_locale.py`; re-running this extractor overwrites manual changes.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "addon" / "HordesOfAzeroth" / "VanillaBonkLocaleZhCN.lua"
DUMPER = Path(__file__).resolve().parent / "dump_addon_locale.lua"
OUT = ROOT / "shared" / "i18n" / "addon" / "addon.yaml"
PLACEHOLDER_RE = re.compile(r"\{(\d+)\}")


def luajit() -> str:
    found = shutil.which("luajit")
    if found:
        return found
    candidate = Path.home() / "AppData/Local/Programs/LuaJIT/bin/luajit.exe"
    if candidate.exists():
        return str(candidate)
    raise SystemExit("luajit not found; install it or set PATH")


def unescape(text: str) -> str:
    return re.sub(
        r"\\(.)",
        lambda match: {"n": "\n", "t": "\t", "r": "\r", "\\": "\\"}.get(
            match.group(1), match.group(1)
        ),
        text,
    )


def slug(text: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return (value or "empty")[:60]


def placeholders(text: str) -> list[int]:
    return sorted({int(value) for value in PLACEHOLDER_RE.findall(text)})


def main() -> int:
    with tempfile.NamedTemporaryFile(delete=False, suffix=".tsv") as temp:
        temp_path = Path(temp.name)
    try:
        subprocess.run([luajit(), str(DUMPER), str(SOURCE), str(temp_path)], check=True)
        rows = []
        for line in temp_path.read_text(encoding="utf-8").splitlines():
            key, value = line.split("\t", 1)
            rows.append((unescape(key), unescape(value)))
    finally:
        temp_path.unlink(missing_ok=True)

    keys = [key for key, _ in rows]
    if len(keys) != len(set(keys)):
        raise SystemExit("duplicate keys in the addon locale table")

    used: dict[str, int] = {}
    entries = []
    mismatched = 0
    for key, value in sorted(rows):
        base = slug(key)
        used[base] = used.get(base, 0) + 1
        suffix = "" if used[base] == 1 else f"_{used[base]}"
        entry = {"id": f"hoa.addon.{base}{suffix}", "enUS": key, "zhCN": value}
        found = placeholders(key)
        if found:
            entry["placeholders"] = found
        if found != placeholders(value):
            mismatched += 1
        entries.append(entry)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    body = yaml.safe_dump(entries, allow_unicode=True, sort_keys=False, width=4096)
    OUT.write_text(
        "# Imported by tools/i18n/extract_addon_locale.py from\n"
        "# addon/HordesOfAzeroth/VanillaBonkLocaleZhCN.lua. Edit this file, then run\n"
        "# tools/i18n/gen_addon_locale.py.\n" + body,
        encoding="utf-8",
    )
    print(f"wrote {OUT.relative_to(ROOT)}: {len(entries)} entries, {mismatched} placeholder mismatches")
    return 0


if __name__ == "__main__":
    sys.exit(main())
