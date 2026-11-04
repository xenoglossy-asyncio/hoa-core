"""Load and validate the shared i18n message catalogue."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
MESSAGES = ROOT / "shared" / "i18n" / "messages"
CONFIG = ROOT / "shared" / "i18n" / "config.yaml"

ID_RE = re.compile(r"^hoa\.[a-z0-9_]+(\.[a-z0-9_]+)*$")
PLACEHOLDER_RE = re.compile(r"\{(\d+)\}")


@dataclass
class Result:
    entries: list[dict[str, Any]]
    errors: list[str]
    warnings: list[str]
    languages: list[str]
    required: list[str]
    optional: list[str]
    source: str


def placeholders(text: str) -> list[int]:
    return sorted({int(value) for value in PLACEHOLDER_RE.findall(text)})


def load() -> Result:
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    source = config["source_language"]
    required = list(config.get("required") or [source])
    optional = list(config.get("optional") or [])
    languages = list(dict.fromkeys([source, *required, *optional]))
    allowed = {"id", "legacy_server_id", "placeholders", *languages}

    entries: list[dict[str, Any]] = []
    errors: list[str] = []
    warnings: list[str] = []
    seen_ids: set[str] = set()
    seen_legacy: set[int] = set()

    for path in sorted(MESSAGES.glob("*.yaml")):
        relative = path.relative_to(ROOT)
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            errors.append(f"{relative}: top level must be a list")
            continue
        for index, entry in enumerate(data):
            where = f"{relative}[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{where}: entry must be a mapping")
                continue
            unknown = set(entry) - allowed
            if unknown:
                errors.append(f"{where}: unknown keys {sorted(unknown)}")
            message_id = entry.get("id")
            if not isinstance(message_id, str) or not ID_RE.match(message_id):
                errors.append(f"{where}: invalid id {message_id!r}")
                continue
            if message_id in seen_ids:
                errors.append(f"{where}: duplicate id {message_id}")
                continue
            seen_ids.add(message_id)
            if "legacy_server_id" in entry:
                legacy = entry["legacy_server_id"]
                if not isinstance(legacy, int):
                    errors.append(f"{message_id}: legacy_server_id must be an integer")
                elif legacy in seen_legacy:
                    errors.append(f"{message_id}: duplicate legacy_server_id {legacy}")
                else:
                    seen_legacy.add(legacy)
            source_text = entry.get(source)
            if not isinstance(source_text, str) or not source_text.strip():
                errors.append(f"{message_id}: missing {source}")
                continue
            expected = placeholders(source_text)
            declared = entry.get("placeholders")
            if declared is not None and declared != expected:
                errors.append(
                    f"{message_id}: declared placeholders {declared} != source placeholders {expected}"
                )
            for language in languages:
                if language == source:
                    continue
                text = entry.get(language)
                if text is None or (isinstance(text, str) and not text.strip()):
                    if language in required:
                        errors.append(f"{message_id}: missing required language {language}")
                    else:
                        warnings.append(f"{message_id}: missing optional language {language}")
                    continue
                if not isinstance(text, str):
                    errors.append(f"{message_id}: {language} must be a string")
                    continue
                found = placeholders(text)
                if found != expected:
                    errors.append(
                        f"{message_id}: {language} placeholders {found} != {expected}"
                    )
            entries.append(entry)

    entries.sort(key=lambda item: item["id"])
    return Result(entries, errors, warnings, languages, required, optional, source)
