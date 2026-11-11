"""Kiểm tra nhanh cú pháp Swift: cân bằng ngoặc, string không đóng, import thiếu.

Không thay thế việc build bằng Xcode, nhưng bắt được lỗi cú pháp thường gặp.

Cách dùng:
    python tools/check_swift_syntax.py
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APP_DIR = os.path.join(ROOT, "ExpenseTracker")

errors: list = []


def check_file(path: str) -> None:
    rel = os.path.relpath(path, ROOT).replace("\\", "/")
    with open(path, "r", encoding="utf-8") as handle:
        source = handle.read()

    # Loại bỏ comment và chuỗi để đếm ngoặc chính xác.
    cleaned = []
    index = 0
    length = len(source)
    in_line_comment = False
    in_block_comment = False
    in_string = False
    in_multiline_string = False
    string_quote = ""

    while index < length:
        char = source[index]
        nxt = source[index + 1] if index + 1 < length else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
                cleaned.append(char)
            index += 1
            continue

        if in_block_comment:
            if char == "*" and nxt == "/":
                in_block_comment = False
                index += 2
                continue
            if char == "\n":
                cleaned.append(char)
            index += 1
            continue

        if in_multiline_string:
            if source.startswith('"""', index):
                in_multiline_string = False
                index += 3
                continue
            if char == "\n":
                cleaned.append(char)
            index += 1
            continue

        if in_string:
            if char == "\\":
                # String interpolation: \(...) - bo qua noi dung ben trong,
                # nhung van giu nguyen so ngoac de khong lam lech can bang.
                if nxt == "(":
                    depth = 1
                    index += 2
                    cleaned.append("(")
                    while index < length and depth > 0:
                        inner = source[index]
                        if inner == "(":
                            depth += 1
                            cleaned.append(inner)
                        elif inner == ")":
                            depth -= 1
                            cleaned.append(inner)
                        elif inner == '"':
                            # String long trong interpolation: bo qua.
                            index += 1
                            while index < length:
                                if source[index] == "\\":
                                    index += 2
                                    continue
                                if source[index] == '"':
                                    break
                                index += 1
                        index += 1
                    continue
                index += 2
                continue
            if char == string_quote:
                in_string = False
            index += 1
            continue

        if char == "/" and nxt == "/":
            in_line_comment = True
            index += 2
            continue

        if char == "/" and nxt == "*":
            in_block_comment = True
            index += 2
            continue

        if source.startswith('"""', index):
            in_multiline_string = True
            index += 3
            continue

        if char == '"':
            in_string = True
            string_quote = '"'
            index += 1
            continue

        cleaned.append(char)
        index += 1

    if in_string or in_block_comment or in_multiline_string:
        errors.append(f"{rel}: chuoi hoac comment khong dong")

    text = "".join(cleaned)

    for open_char, close_char, name in [("{", "}", "ngoac nhoac"), ("(", ")", "ngoac tròn"), ("[", "]", "ngoac vuong")]:
        if text.count(open_char) != text.count(close_char):
            errors.append(
                f"{rel}: {name} khong can bang "
                f"({open_char}={text.count(open_char)}, {close_char}={text.count(close_char)})"
            )

    # Import can thiet.
    imports = set(re.findall(r"^import\s+(\w+)", source, re.MULTILINE))

    def uses(symbol: str) -> bool:
        return re.search(rf"\b{symbol}\b", source) is not None

    if uses("Color") or uses("View") or uses("Text") or uses("VStack"):
        if "SwiftUI" not in imports and "Charts" not in imports:
            errors.append(f"{rel}: dung SwiftUI nhung thieu import SwiftUI")
    if uses("@Query") or uses("@Model") or uses("ModelContext") or uses("ModelContainer"):
        if "SwiftData" not in imports:
            errors.append(f"{rel}: dung SwiftData nhung thieu import SwiftData")
    if uses("Chart") or uses("SectorMark") or uses("BarMark"):
        if "Charts" not in imports:
            errors.append(f"{rel}: dung Charts nhung thieu import Charts")
    if uses("@Observable"):
        if "Observation" not in imports and "SwiftUI" not in imports:
            errors.append(f"{rel}: dung @Observable nhung thieu import Observation")
    if uses("FileDocument") or uses("fileExporter"):
        if "UniformTypeIdentifiers" not in imports:
            errors.append(f"{rel}: dung fileExporter nhung thieu import UniformTypeIdentifiers")

    # @Model phai co import SwiftData.
    if "@Model" in source and "SwiftData" not in imports:
        errors.append(f"{rel}: co @Model nhung thieu import SwiftData")

    # Dung "@Query" trong struct View -> can import SwiftData (da check o tren).


def main() -> int:
    count = 0
    for dirpath, dirnames, filenames in os.walk(APP_DIR):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in sorted(filenames):
            if name.endswith(".swift"):
                check_file(os.path.join(dirpath, name))
                count += 1

    if errors:
        print(f"FAIL ({len(errors)} loi):")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(f"OK: {count} file Swift khong co loi cú phap co ban")
    return 0


if __name__ == "__main__":
    sys.exit(main())
