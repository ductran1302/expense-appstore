"""Kiểm tra mọi `L.xxx` dùng trong code đều được định nghĩa trong enum L.

Cách dùng:
    python tools/check_localization_usage.py
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SWIFT_DIR = os.path.join(ROOT, "ExpenseTracker")
LOCALIZATION = os.path.join(SWIFT_DIR, "Shared", "Localization.swift")


def main() -> int:
    with open(LOCALIZATION, "r", encoding="utf-8") as handle:
        source = handle.read()

    members = set(re.findall(r"static var (\w+): LocalizedStringKey", source))
    functions = set(re.findall(r"static func (\w+)\(", source))

    used_members = set()
    used_functions = set()

    for dirpath, dirnames, filenames in os.walk(SWIFT_DIR):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if not name.endswith(".swift") or name == "Localization.swift":
                continue
            with open(os.path.join(dirpath, name), "r", encoding="utf-8") as handle:
                file_source = handle.read()
            used_members.update(re.findall(r"\bL\.(\w+)", file_source))
            used_functions.update(re.findall(r"\bL\.(\w+)\s*\(", file_source))

    errors = []

    for member in sorted(used_members):
        if member not in members and member not in functions:
            errors.append(f"L.{member} chua duoc dinh nghia trong enum L")

    for function in sorted(used_functions):
        if function not in functions:
            errors.append(f"L.{function}() chua duoc dinh nghia trong enum L")

    if errors:
        print(f"FAIL ({len(errors)} loi):")
        for error in errors:
            print(f"  - {error}")
        return 1

    unused = sorted((members | functions) - used_members - used_functions)
    print(f"OK: tat ca L.xxx deu ton tai ({len(members)} thuoc tinh, {len(functions)} ham)")
    if unused:
        print(f"  ({len(unused)} chua dung: {', '.join(unused)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
