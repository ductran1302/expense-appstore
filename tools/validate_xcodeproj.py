"""Parser OpenStep plist (định dạng pbxproj) + kiểm tra cấu trúc project.

Mục đích: chắc chắn file project.pbxproj parse được như Xcode parse, và
mọi tham chiếu giữa các object đều hợp lệ.

Cách dùng:
    python tools/validate_xcodeproj.py
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PROJECT_DIR = os.path.join(ROOT, "ExpenseTracker.xcodeproj")
PBXPROJ = os.path.join(PROJECT_DIR, "project.pbxproj")
APP_DIR = os.path.join(ROOT, "ExpenseTracker")

errors: list = []


class Parser:
    """Parser OpenStep plist tối giản."""

    def __init__(self, text: str):
        self.text = text
        self.pos = 0

    def error(self, message: str):
        line = self.text.count("\n", 0, self.pos) + 1
        raise ValueError(f"parse error tai dong {line}: {message}")

    def skip_ws(self):
        while self.pos < len(self.text):
            char = self.text[self.pos]
            if char in " \t\r\n":
                self.pos += 1
            elif self.text.startswith("//", self.pos):
                end = self.text.find("\n", self.pos)
                self.pos = len(self.text) if end == -1 else end
            elif self.text.startswith("/*", self.pos):
                end = self.text.find("*/", self.pos + 2)
                if end == -1:
                    self.error("khong dong comment")
                self.pos = end + 2
            else:
                break

    def parse(self):
        self.skip_ws()
        if self.text.startswith("// !$*UTF8*$!", self.pos):
            self.pos += len("// !$*UTF8*$!")
        self.skip_ws()
        value = self.parse_value()
        self.skip_ws()
        if self.pos != len(self.text):
            self.error("con thua du lieu sau khi parse xong")
        return value

    def parse_value(self):
        self.skip_ws()
        if self.pos >= len(self.text):
            self.error("het du lieu")
        char = self.text[self.pos]
        if char == "{":
            return self.parse_dict()
        if char == "(":
            return self.parse_array()
        if char == '"':
            return self.parse_quoted()
        return self.parse_bare()

    def parse_dict(self):
        result = {}
        self.pos += 1  # {
        while True:
            self.skip_ws()
            if self.pos >= len(self.text):
                self.error("dict khong dong")
            if self.text[self.pos] == "}":
                self.pos += 1
                return result
            key = self.parse_value()
            self.skip_ws()
            if self.pos >= len(self.text) or self.text[self.pos] != "=":
                self.error(f"thieu '=' sau key '{key}'")
            self.pos += 1
            value = self.parse_value()
            self.skip_ws()
            if self.pos < len(self.text) and self.text[self.pos] == ";":
                self.pos += 1
            result[key] = value

    def parse_array(self):
        result = []
        self.pos += 1  # (
        while True:
            self.skip_ws()
            if self.pos >= len(self.text):
                self.error("array khong dong")
            if self.text[self.pos] == ")":
                self.pos += 1
                return result
            result.append(self.parse_value())
            self.skip_ws()
            if self.pos < len(self.text) and self.text[self.pos] == ",":
                self.pos += 1

    def parse_quoted(self):
        self.pos += 1  # "
        chunks = []
        while True:
            if self.pos >= len(self.text):
                self.error("chuoi khong dong")
            char = self.text[self.pos]
            if char == "\\":
                self.pos += 1
                chunks.append(self.text[self.pos])
                self.pos += 1
            elif char == '"':
                self.pos += 1
                return "".join(chunks)
            else:
                chunks.append(char)
                self.pos += 1

    def parse_bare(self):
        start = self.pos
        while self.pos < len(self.text) and self.text[self.pos] not in " \t\r\n=;,(){}\"":
            self.pos += 1
        if start == self.pos:
            self.error(f"ky tu khong hop le '{self.text[self.pos]}'")
        return self.text[start:self.pos]


def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def validate_structure(project: dict) -> None:
    objects = project.get("objects")
    check(isinstance(objects, dict), "Thieu 'objects'")
    if not isinstance(objects, dict):
        return

    root_uid = project.get("rootObject")
    check(root_uid in objects, "rootObject khong ton tai trong objects")
    root = objects.get(root_uid, {})
    check(root.get("isa") == "PBXProject", "rootObject phai la PBXProject")

    # Tim target
    targets = root.get("targets", [])
    check(len(targets) == 1, f"Project phai co dung 1 target (co {len(targets)})")

    for target_uid in targets:
        target = objects.get(target_uid, {})
        check(target.get("isa") == "PBXNativeTarget", "Target khong phai PBXNativeTarget")
        check(
            target.get("productType") == "com.apple.product-type.application",
            "Target phai la application",
        )
        check(target.get("productReference") in objects, "Target thiieu productReference")

        # Build phases
        phases = [objects.get(phase, {}) for phase in target.get("buildPhases", [])]
        isas = [phase.get("isa") for phase in phases]
        check("PBXSourcesBuildPhase" in isas, "Target thieu Sources build phase")
        check("PBXResourcesBuildPhase" in isas, "Target thieu Resources build phase")

        # Sources phase: moi buildFile phai tro toi file reference ton tai
        for phase in phases:
            for build_file_uid in phase.get("files", []):
                build_file = objects.get(build_file_uid, {})
                check(build_file.get("isa") == "PBXBuildFile", f"BuildFile sai isa: {build_file_uid}")
                file_ref = build_file.get("fileRef")
                check(file_ref in objects, f"BuildFile tro toi fileRef khong ton tai: {build_file_uid}")

        # Build configurations
        cfg_list = objects.get(target.get("buildConfigurationList"), {})
        configs = [objects.get(c, {}) for c in cfg_list.get("buildConfigurations", [])]
        names = sorted(c.get("name") for c in configs)
        check(names == ["Debug", "Release"], f"Target thieu build config Debug/Release (co {names})")
        for cfg in configs:
            settings = cfg.get("buildSettings", {})
            check(settings.get("PRODUCT_BUNDLE_IDENTIFIER"), "Thieu PRODUCT_BUNDLE_IDENTIFIER")
            check(settings.get("INFOPLIST_FILE"), "Thieu INFOPLIST_FILE")
            check(settings.get("IPHONEOS_DEPLOYMENT_TARGET") is None, "IPHONEOS_DEPLOYMENT_TARGET nen o project level")

    # Project level config
    project_cfg_list = objects.get(root.get("buildConfigurationList"), {})
    project_configs = [objects.get(c, {}) for c in project_cfg_list.get("buildConfigurations", [])]
    names = sorted(c.get("name") for c in project_configs)
    check(names == ["Debug", "Release"], f"Project thieu build config Debug/Release (co {names})")

    # Build settings quan trong
    for cfg in project_configs:
        settings = cfg.get("buildSettings", {})
        check(
            settings.get("IPHONEOS_DEPLOYMENT_TARGET") == "17.0",
            "IPHONEOS_DEPLOYMENT_TARGET phai la 17.0",
        )
        check(settings.get("SWIFT_VERSION") == "5.0", "SWIFT_VERSION phai la 5.0")

    # Group tree: khong co group rong, khong co vong lap
    def walk(group_uid, seen, depth):
        check(group_uid not in seen, f"Group bi vong lap: {group_uid}")
        if group_uid in seen:
            return
        seen = seen | {group_uid}
        group = objects.get(group_uid, {})
        check(group.get("isa") == "PBXGroup", f"{group_uid} khong phai PBXGroup")
        children = group.get("children", [])
        check(len(children) > 0, f"Group rong: {group_uid}")
        for child_uid in children:
            check(child_uid in objects, f"Group tro toi child khong ton tai: {child_uid}")
            child = objects.get(child_uid, {})
            if child.get("isa") == "PBXGroup":
                walk(child_uid, seen, depth + 1)
            else:
                check(child.get("isa") == "PBXFileReference", f"Child khong phai file/group: {child_uid}")

    walk(root.get("mainGroup"), set(), 0)

    # File reference phai tro toi file that tren dia
    def check_paths(group_uid, prefix):
        group = objects.get(group_uid, {})
        group_path = group.get("path", "")
        group_prefix = os.path.join(prefix, group_path) if group_path else prefix
        for child_uid in group.get("children", []):
            child = objects.get(child_uid, {})
            if child.get("isa") == "PBXGroup":
                check_paths(child_uid, group_prefix)
                continue
            if child.get("sourceTree") == "BUILT_PRODUCTS_DIR":
                continue
            path = child.get("path")
            if not path:
                continue
            full = os.path.join(group_prefix, path).replace("\\", "/")
            check(os.path.exists(os.path.join(ROOT, full)), f"File khong ton tai: {full}")

    check_paths(root.get("mainGroup"), "")

    # Moi file .swift tren dia phai nam trong Sources phase
    swift_on_disk = set()
    for dirpath, dirnames, filenames in os.walk(APP_DIR):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if name.endswith(".swift"):
                swift_on_disk.add(name)

    in_sources = set()
    for target_uid in targets:
        target = objects.get(target_uid, {})
        for phase_uid in target.get("buildPhases", []):
            phase = objects.get(phase_uid, {})
            if phase.get("isa") != "PBXSourcesBuildPhase":
                continue
            for build_file_uid in phase.get("files", []):
                build_file = objects.get(build_file_uid, {})
                file_ref = objects.get(build_file.get("fileRef"), {})
                name = file_ref.get("path", "")
                if name.endswith(".swift"):
                    in_sources.add(name)

    missing = swift_on_disk - in_sources
    check(not missing, f"File Swift chua duoc them vao Sources phase: {sorted(missing)}")


def main() -> int:
    if not os.path.exists(PBXPROJ):
        print("FAIL: khong tim thay project.pbxproj")
        return 1

    with open(PBXPROJ, "r", encoding="utf-8") as handle:
        content = handle.read()

    try:
        project = Parser(content).parse()
    except ValueError as error:
        print(f"FAIL: project.pbxproj khong parse duoc -> {error}")
        return 1

    validate_structure(project)

    # Scheme
    scheme = os.path.join(PROJECT_DIR, "xcshareddata", "xcschemes", "ExpenseTracker.xcscheme")
    check(os.path.exists(scheme), "Thieu shared scheme ExpenseTracker.xcscheme")
    if os.path.exists(scheme):
        with open(scheme, "r", encoding="utf-8") as handle:
            scheme_content = handle.read()
        match = re.search(r'BlueprintIdentifier = "([0-9A-F]{24})"', scheme_content)
        check(match is not None, "Scheme thieu BlueprintIdentifier")
        if match:
            check(
                match.group(1) in project["objects"],
                "Scheme tro toi target UID khong ton tai",
            )

    # Icon + assets
    icon = os.path.join(APP_DIR, "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png")
    check(os.path.exists(icon), "Thieu app icon 1024x1024")

    if errors:
        print(f"FAIL ({len(errors)} loi):")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("OK: project.pbxroj parse thanh cong va cau truc hop le")
    print(f"  {len(project['objects'])} object")
    swift_count = sum(
        1 for obj in project["objects"].values()
        if obj.get("isa") == "PBXFileReference" and str(obj.get("path", "")).endswith(".swift")
    )
    print(f"  {swift_count} file Swift trong project")
    return 0


if __name__ == "__main__":
    sys.exit(main())
