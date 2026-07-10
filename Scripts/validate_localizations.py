#!/usr/bin/env python3
"""Validate that Lernzeit's English and German localizations stay in sync."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import NoReturn

ROOT = Path(__file__).resolve().parents[1]
LOCALIZATION_PATHS = {
    "en": ROOT / "Lernzeit" / "en.lproj" / "Localizable.strings",
    "de": ROOT / "Lernzeit" / "de.lproj" / "Localizable.strings",
}
ENTRY_PATTERN = re.compile(r'^\s*"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;\s*$')
KEY_PATTERN = re.compile(
    r'"((?:appearance|common|duration|history|menu|mini|navigation|notification|settings|stats|status|subjects|timer)\.[a-z0-9_.]+)"'
)
PLACEHOLDER_PATTERN = re.compile(r'%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.\d+|\.\*)?[hlLzjtq]*[@diuoxXfFeEgGaAcCsSp]')


def fail(message: str) -> NoReturn:
    print(f"localization validation failed: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_strings(path: Path) -> dict[str, str]:
    if not path.is_file():
        fail(f"missing {path.relative_to(ROOT)}")

    entries: dict[str, str] = {}
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("/*") or stripped.startswith("//"):
            continue
        match = ENTRY_PATTERN.match(line)
        if not match:
            fail(f"invalid entry in {path.relative_to(ROOT)}:{line_number}")
        key, value = match.groups()
        if key in entries:
            fail(f"duplicate key {key!r} in {path.relative_to(ROOT)}")
        entries[key] = value
    return entries


def placeholder_signature(value: str) -> list[str]:
    return [re.sub(r'^%(?:\d+\$)?', "%", item) for item in PLACEHOLDER_PATTERN.findall(value)]


def main() -> None:
    translations = {language: parse_strings(path) for language, path in LOCALIZATION_PATHS.items()}
    english_keys = set(translations["en"])
    german_keys = set(translations["de"])

    if english_keys != german_keys:
        missing_de = sorted(english_keys - german_keys)
        missing_en = sorted(german_keys - english_keys)
        fail(f"key sets differ; missing in de={missing_de}, missing in en={missing_en}")

    used_keys: set[str] = set()
    for source_root in (ROOT / "Lernzeit", ROOT / "Shared"):
        for path in source_root.rglob("*.swift"):
            used_keys.update(KEY_PATTERN.findall(path.read_text(encoding="utf-8")))

    if not used_keys:
        fail("no localized keys are used by the Swift sources")

    missing = sorted(used_keys - english_keys)
    unused = sorted(english_keys - used_keys)
    if missing:
        fail(f"keys used in Swift but absent from translations: {missing}")
    if unused:
        fail(f"translation keys not used in Swift: {unused}")

    for key in sorted(english_keys):
        english = translations["en"][key]
        german = translations["de"][key]
        if not english or not german:
            fail(f"empty translation for {key!r}")
        if placeholder_signature(english) != placeholder_signature(german):
            fail(
                f"format placeholders differ for {key!r}: "
                f"en={placeholder_signature(english)}, de={placeholder_signature(german)}"
            )

    print(f"localization validation passed: {len(english_keys)} keys in English and German")


if __name__ == "__main__":
    main()
