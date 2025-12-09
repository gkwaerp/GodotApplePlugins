#!/usr/bin/env python3
"""
Post-process the generated doc XML files so Godot's doc tooling can ingest them.

The doctool emits enum parameters as custom types (e.g. PlayerScope), which
the downstream linter does not recognize. This script rewrites those parameter
types back to `int` (leaving the enum references in the descriptions) and
renames a handful of signal arguments so their `[param ...]` references resolve.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

DOC_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("doc_classes")

if not DOC_DIR.is_dir():
    print(f"Error: Directory '{DOC_DIR}' not found", file=sys.stderr)
    sys.exit(1)

# Signals that need stable parameter names so the descriptions can refer to them.
SIGNAL_PARAM_RENAMES: dict[str, dict[str, dict[int, str]]] = {
    "ASAuthorizationController": {
        "authorization_completed": {0: "credential"},
        "authorization_failed": {0: "error"},
    },
    "StoreKitManager": {
        "products_request_completed": {0: "products", 1: "status"},
        "purchase_completed": {0: "transaction", 1: "status", 2: "error_message"},
        "restore_completed": {0: "status", 1: "error_message"},
        "transaction_updated": {0: "transaction"},
    },
}


def collect_enum_names(directory: Path) -> set[str]:
    enum_names: set[str] = set()
    pattern = re.compile(r'enum="([A-Za-z0-9_.]+)"')
    for xml_file in sorted(directory.glob("*.xml")):
        text = xml_file.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            enum_names.add(match.group(1).split(".")[-1])
    return enum_names


ALL_ENUM_NAMES = collect_enum_names(DOC_DIR)


def replace_enum_params(text: str, enum_names: set[str]) -> tuple[str, bool]:
    changed = False
    for enum_name in enum_names:
        if f'type="{enum_name}"' not in text:
            continue
        pattern = re.compile(
            rf'(<param[^>]*\btype="){re.escape(enum_name)}(")',
            flags=re.MULTILINE,
        )
        text, count = pattern.subn(r"\1int\2", text)
        if count:
            changed = True
    # Normalize Array[...] parameter types.
    text, count = re.subn(r'type="Array\[[^"]+\]"', 'type="Array"', text)
    if count:
        changed = True
    return text, changed


def rename_signal_params(class_name: str, text: str) -> tuple[str, bool]:
    changed = False
    if class_name not in SIGNAL_PARAM_RENAMES:
        return text, changed

    for signal_name, rename_map in SIGNAL_PARAM_RENAMES[class_name].items():
        for index, new_name in rename_map.items():
            pattern = re.compile(
                rf'(<signal name="{re.escape(signal_name)}">.*?<param index="{index}" name=")[^"]+(")',
                flags=re.DOTALL,
            )
            new_text, count = pattern.subn(rf"\1{new_name}\2", text, count=1)
            if count == 0:
                print(
                    f"Warning: Could not rename param {index} in {class_name}.{signal_name}",
                    file=sys.stderr,
                )
            else:
                text = new_text
                changed = True
    return text, changed


def process_file(path: Path, enum_names: set[str]) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text
    text, enums_changed = replace_enum_params(text, enum_names)

    class_match = re.search(r'<class name="([^"]+)"', text)
    class_name = class_match.group(1) if class_match else ""
    text, renames_changed = rename_signal_params(class_name, text)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return enums_changed or renames_changed


changed_files = 0
for xml_file in sorted(DOC_DIR.glob("*.xml")):
    if process_file(xml_file, ALL_ENUM_NAMES):
        changed_files += 1

if changed_files:
    print(f"Fixed {changed_files} file(s)")
else:
    print("No files needed fixing")
