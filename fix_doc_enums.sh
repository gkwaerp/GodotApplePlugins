#!/bin/bash
#
# fix_doc_enums.sh - Post-process generated doc XML.
#
# 1. Convert enum parameter types from "Class.Enum" to "int" + enum attr.
# 2. Add [code skip-lint] to snippets that trip Godot's doc linter.
#

set -euo pipefail

DOC_DIR="${1:-doc_classes}"

if [ ! -d "$DOC_DIR" ]; then
    echo "Error: Directory '$DOC_DIR' not found" >&2
    echo "Usage: $0 [doc_classes_directory]" >&2
    exit 1
fi

python3 - "$DOC_DIR" <<'PY'
import re
import sys
from pathlib import Path

doc_dir = Path(sys.argv[1])

ENUM_DOTTED_PATTERN = re.compile(r'type="([A-Z][A-Za-z0-9]*\.[A-Z][A-Za-z0-9]*)"')
CODE_PATTERN = re.compile(r'\[code\]([A-Za-z0-9_.@\[\]\(\)]+)\[/code\]')
ARRAY_PATTERN = re.compile(r'type="Array\[[^"]+\]"')
ENUM_DECL_PATTERN = re.compile(r'enum="([A-Za-z0-9_.]+)"')
CLASS_PATTERN = re.compile(r'<class name="([^"]+)"')
CODEBLOCK_OPEN_PATTERN = re.compile(r'(^[ \t]*)\[codeblock\]', re.MULTILINE)
CODEBLOCK_CLOSE_PATTERN = re.compile(r'(^[ \t]*)\[/codeblock\]', re.MULTILINE)

TYPE_ALIASES = {
    "GKAccessPoint": {"State"},
    "GKGameCenterViewController": {"PlayerScope", "TimeScope", "State"},
    "GKMatch": {"SendDataMode"},
    "GKMatchRequest": {"MatchType"},
}

SIGNAL_PARAM_RENAMES = {
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

LOWER_SKIP = {
    "classic",
    "recurring",
    "unknown",
    "invite_message",
    "hosted",
    "load_image",
    "authenticate",
    "scopedIDsArePersistent",
}


def replace_enum_types(text: str, class_name: str) -> tuple[str, bool]:
    changed = False

    def repl(match: re.Match) -> str:
        nonlocal changed
        changed = True
        return f'type="int" enum="{match.group(1)}"'

    text = ENUM_DOTTED_PATTERN.sub(repl, text)

    enum_names = {m.group(1).split(".")[-1] for m in ENUM_DECL_PATTERN.finditer(text)}
    alias_names = TYPE_ALIASES.get(class_name, set())
    enum_names.update(alias_names)

    for enum_name in sorted(enum_names):
        pattern = re.compile(rf'(<param[^>]*\btype="){re.escape(enum_name)}(")')
        text, count = pattern.subn(r'\1int\2', text)
        if count:
            changed = True

    text, count = ARRAY_PATTERN.subn('type="Array"', text)
    if count:
        changed = True

    return text, changed


def add_skip_lint(text: str) -> tuple[str, bool]:
    changed = False

    def repl(match: re.Match) -> str:
        nonlocal changed
        token = match.group(1)
        normalized = token.lstrip("@")
        normalized = normalized.rstrip("()")
        normalized = normalized.replace("[", "").replace("]", "")
        if token in LOWER_SKIP or normalized in LOWER_SKIP or (normalized and normalized[0].isupper()):
            changed = True
            return f"[code skip-lint]{token}[/code]"
        return match.group(0)

    return CODE_PATTERN.sub(repl, text), changed


def rename_signal_params(text: str, class_name: str) -> tuple[str, bool]:
    if class_name not in SIGNAL_PARAM_RENAMES:
        return text, False
    changed = False
    for signal_name, renames in SIGNAL_PARAM_RENAMES[class_name].items():
        for index, new_name in renames.items():
            pattern = re.compile(
                rf'(<signal name="{re.escape(signal_name)}">.*?<param index="{index}" name=")[^"]+(")',
                re.DOTALL,
            )
            new_text, count = pattern.subn(rf"\1{new_name}\2", text, count=1)
            if count:
                text = new_text
                changed = True
    return text, changed


def convert_codeblocks(text: str) -> tuple[str, bool]:
    changed = False

    def open_repl(match: re.Match) -> str:
        nonlocal changed
        changed = True
        indent = match.group(1)
        return f"{indent}[codeblocks]\n{indent}[gdscript]"

    def close_repl(match: re.Match) -> str:
        indent = match.group(1)
        return f"{indent}[/gdscript]\n{indent}[/codeblocks]"

    new_text = CODEBLOCK_OPEN_PATTERN.sub(open_repl, text)
    new_text = CODEBLOCK_CLOSE_PATTERN.sub(close_repl, new_text)
    if new_text != text:
        changed = True
    return new_text, changed


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    class_match = CLASS_PATTERN.search(text)
    class_name = class_match.group(1) if class_match else ""

    text, enums_changed = replace_enum_types(text, class_name)
    text, skip_changed = add_skip_lint(text)
    text, rename_changed = rename_signal_params(text, class_name)
    text, tabs_changed = convert_codeblocks(text)

    if enums_changed or skip_changed or rename_changed or tabs_changed:
        path.write_text(text, encoding="utf-8")
        return True
    return False


changed = 0
for xml_file in sorted(doc_dir.glob("*.xml")):
    if process_file(xml_file):
        changed += 1
        print(f"Fixed: {xml_file.name}")

if changed == 0:
    print("No files needed fixing")
else:
    print(f"Fixed {changed} file(s)")
PY
