"""Sinh ExpenseTracker.xcodeproj (project.pbxproj) bằng Python.

Mục đích: tạo được project Xcode hợp lệ ngay trên Windows mà không cần Xcode.
Sau khi thêm/bớt file Swift, chạy lại script này để cập nhật project:

    python tools/generate_xcodeproj.py
"""
import hashlib
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
APP_DIR = os.path.join(ROOT, "ExpenseTracker")
PROJECT_DIR = os.path.join(ROOT, "ExpenseTracker.xcodeproj")
TARGET_NAME = "ExpenseTracker"
BUNDLE_ID = "com.ductran1302.expensetracker"
MARKETING_VERSION = "1.0.0"
BUILD_NUMBER = "1"
DEPLOYMENT_TARGET = "17.0"
SWIFT_VERSION = "5.0"
OBJECT_VERSION = "56"
COMPATIBILITY_VERSION = "Xcode 14.0"
TOOLS_VERSION = "16.0"


def uid(*parts: str) -> str:
    """Sinh UUID 24 ký tự hex ổn định cho project."""
    key = "::".join(parts)
    return hashlib.md5(key.encode("utf-8")).hexdigest()[:24].upper()


# ----------------------------------------------------------------------
# Thu thập file nguồn
# ----------------------------------------------------------------------

RESOURCE_FILES = [
    ("Assets.xcassets", "folder.assetcatalog"),
    ("PrivacyInfo.xcprivacy", "text.plist.xml"),
    ("Info.plist", "text.plist.xml"),
    ("Localizable.xcstrings", "text.json.xcstrings"),
]


def find_source_files() -> list:
    """Danh sách đường dẫn tương đối (so với ExpenseTracker) của file .swift."""
    result = []
    for dirpath, dirnames, filenames in os.walk(APP_DIR):
        dirnames[:] = [d for d in dirnames if not d.startswith(".") and d != "Assets.xcassets"]
        for name in sorted(filenames):
            if name.endswith(".swift"):
                full = os.path.join(dirpath, name)
                result.append(os.path.relpath(full, APP_DIR).replace("\\", "/"))
    return sorted(result)


class Group:
    """Một nhóm trong cây PBXGroup."""

    def __init__(self, name: str, path: str | None = None):
        self.name = name
        self.path = path
        self.groups: list = []
        self.files: list = []  # (tên hiển thị, uid file reference)


def build_tree(source_files: list) -> Group:
    """Dựng cây group theo cấu trúc thư mục hiện tại."""
    root = Group(TARGET_NAME, TARGET_NAME)

    # Gom file .swift theo thư mục con.
    by_folder: dict = {}
    for rel in source_files:
        folder = os.path.dirname(rel)
        by_folder.setdefault(folder, []).append(os.path.basename(rel))

    def make_group(folder: str) -> Group:
        name = folder.split("/")[-1] if folder else TARGET_NAME
        group = Group(name, name)
        for file_name in by_folder.get(folder, []):
            group.files.append((file_name, uid("fileref", folder + "/" + file_name)))
        return group

    # Các thư mục con trực tiếp.
    direct_folders = sorted({f for f in by_folder if "/" not in f})
    for folder in direct_folders:
        group = make_group(folder)
        root.groups.append(group)
        # Các thư mục con sâu hơn nằm trong group cha tương ứng.
        for deep in sorted(f for f in by_folder if f.startswith(folder + "/")):
            remainder = deep[len(folder) + 1:]
            if "/" in remainder:
                continue
            group.groups.append(make_group(deep))

    # File tài nguyên nằm ở gốc.
    for file_name, file_type in RESOURCE_FILES:
        root.files.append((file_name, uid("fileref", file_name)))

    return root


# ----------------------------------------------------------------------
# Build settings
# ----------------------------------------------------------------------

SHARED_PROJECT_SETTINGS = [
    ("ALWAYS_SEARCH_USER_PATHS", "NO"),
    ("ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS", "YES"),
    ("CLANG_ANALYZER_NONNULL", "YES"),
    ("CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION", "YES_AGGRESSIVE"),
    ("CLANG_CXX_LANGUAGE_STANDARD", '"gnu++20"'),
    ("CLANG_ENABLE_MODULES", "YES"),
    ("CLANG_ENABLE_OBJC_ARC", "YES"),
    ("CLANG_ENABLE_OBJC_WEAK", "YES"),
    ("CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING", "YES"),
    ("CLANG_WARN_BOOL_CONVERSION", "YES"),
    ("CLANG_WARN_COMMA", "YES"),
    ("CLANG_WARN_CONSTANT_CONVERSION", "YES"),
    ("CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS", "YES"),
    ("CLANG_WARN_DIRECT_OBJC_ISA_USAGE", "YES_ERROR"),
    ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
    ("CLANG_WARN_EMPTY_BODY", "YES"),
    ("CLANG_WARN_ENUM_CONVERSION", "YES"),
    ("CLANG_WARN_INFINITE_RECURSION", "YES"),
    ("CLANG_WARN_INT_CONVERSION", "YES"),
    ("CLANG_WARN_NON_LITERAL_NULL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF", "YES"),
    ("CLANG_WARN_OBJC_LITERAL_CONVERSION", "YES"),
    ("CLANG_WARN_OBJC_ROOT_CLASS", "YES_ERROR"),
    ("CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER", "YES"),
    ("CLANG_WARN_RANGE_LOOP_ANALYSIS", "YES"),
    ("CLANG_WARN_STRICT_PROTOTYPES", "YES"),
    ("CLANG_WARN_SUSPICIOUS_MOVE", "YES"),
    ("CLANG_WARN_UNGUARDED_AVAILABILITY", "YES_AGGRESSIVE"),
    ("CLANG_WARN_UNREACHABLE_CODE", "YES"),
    ("CLANG_WARN__DUPLICATE_METHOD_MATCH", "YES"),
    ("COPY_PHASE_STRIP", "NO"),
    ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
    ("ENABLE_USER_SCRIPT_SANDBOXING", "YES"),
    # Ngôn ngữ gốc của bundle: tiếng Việt là mặc định của app.
    ("DEVELOPMENT_LANGUAGE", "vi"),
    ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
    ("GCC_NO_COMMON_BLOCKS", "YES"),
    ("GCC_WARN_64_TO_32_BIT_CONVERSION", "YES"),
    ("GCC_WARN_ABOUT_RETURN_TYPE", "YES_ERROR"),
    ("GCC_WARN_UNDECLARED_SELECTOR", "YES"),
    ("GCC_WARN_UNINITIALIZED_AUTOS", "YES_AGGRESSIVE"),
    ("GCC_WARN_UNUSED_FUNCTION", "YES"),
    ("GCC_WARN_UNUSED_VARIABLE", "YES"),
    ("IPHONEOS_DEPLOYMENT_TARGET", DEPLOYMENT_TARGET),
    ("LOCALIZATION_PREFERS_STRING_CATALOGS", "YES"),
    ("MTL_FAST_MATH", "YES"),
    ("SDKROOT", "iphoneos"),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ("SWIFT_VERSION", SWIFT_VERSION),
]

PROJECT_DEBUG_SETTINGS = SHARED_PROJECT_SETTINGS + [
    ("DEBUG_INFORMATION_FORMAT", "dwarf"),
    ("ENABLE_TESTABILITY", "YES"),
    ("GCC_DYNAMIC_NO_PIC", "NO"),
    ("GCC_OPTIMIZATION_LEVEL", "0"),
    ("GCC_PREPROCESSOR_DEFINITIONS", '(\n\t\t\t\t\t"DEBUG=1",\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t)'),
    ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
    ("ONLY_ACTIVE_ARCH", "YES"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", '"DEBUG $(inherited)"'),
    ("SWIFT_OPTIMIZATION_LEVEL", '"-Onone"'),
]

PROJECT_RELEASE_SETTINGS = SHARED_PROJECT_SETTINGS + [
    ("DEBUG_INFORMATION_FORMAT", '"dwarf-with-dsym"'),
    ("ENABLE_NS_ASSERTIONS", "NO"),
    ("MTL_ENABLE_DEBUG_INFO", "NO"),
    ("SWIFT_COMPILATION_MODE", "wholemodule"),
    ("SWIFT_OPTIMIZATION_LEVEL", '"-O"'),
    ("VALIDATE_PRODUCT", "YES"),
]

TARGET_SHARED_SETTINGS = [
    ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
    ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
    ("CODE_SIGN_STYLE", "Automatic"),
    ("CURRENT_PROJECT_VERSION", BUILD_NUMBER),
    ("ENABLE_PREVIEWS", "YES"),
    ("GENERATE_INFOPLIST_FILE", "NO"),
    ("INFOPLIST_FILE", "ExpenseTracker/Info.plist"),
    ("LD_RUNPATH_SEARCH_PATHS", '(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t)'),
    ("MARKETING_VERSION", MARKETING_VERSION),
    ("PRODUCT_BUNDLE_IDENTIFIER", BUNDLE_ID),
    ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
    ("SUPPORTED_PLATFORMS", '"iphoneos iphonesimulator"'),
    ("SUPPORTS_MACCATALYST", "NO"),
    ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ("TARGETED_DEVICE_FAMILY", '"1,2"'),
]

TARGET_DEBUG_SETTINGS = TARGET_SHARED_SETTINGS + [
    ("DEBUG_INFORMATION_FORMAT", "dwarf"),
    ("ENABLE_TESTABILITY", "YES"),
    ("GCC_OPTIMIZATION_LEVEL", "0"),
    ("ONLY_ACTIVE_ARCH", "YES"),
    ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", '"DEBUG $(inherited)"'),
    ("SWIFT_OPTIMIZATION_LEVEL", '"-Onone"'),
]

TARGET_RELEASE_SETTINGS = TARGET_SHARED_SETTINGS + [
    ("DEBUG_INFORMATION_FORMAT", '"dwarf-with-dsym"'),
    ("ENABLE_NS_ASSERTIONS", "NO"),
    ("SWIFT_COMPILATION_MODE", "wholemodule"),
    ("SWIFT_OPTIMIZATION_LEVEL", '"-O"'),
    ("VALIDATE_PRODUCT", "YES"),
]


def render_settings(settings) -> str:
    return "\n".join(f"\t\t\t\t{key} = {value};" for key, value in settings)


def render_config(name, config_uid, settings) -> str:
    return (
        f'\t\t{config_uid} /* {name} */ = {{\n'
        f'\t\t\tisa = XCBuildConfiguration;\n'
        f'\t\t\tbuildSettings = {{\n{render_settings(settings)}\n\t\t\t}};\n'
        f'\t\t\tname = {name};\n'
        f'\t\t}};'
    )


def main() -> None:
    source_files = find_source_files()
    tree = build_tree(source_files)

    # UID quan trọng
    project_uid = uid("project")
    products_group_uid = uid("group", "products")
    target_uid = uid("target")
    product_ref_uid = uid("fileref", "product")
    sources_phase_uid = uid("phase", "sources")
    frameworks_phase_uid = uid("phase", "frameworks")
    resources_phase_uid = uid("phase", "resources")
    project_cfg_list_uid = uid("configlist", "project")
    target_cfg_list_uid = uid("configlist", "target")
    project_debug_uid = uid("config", "project", "debug")
    project_release_uid = uid("config", "project", "release")
    target_debug_uid = uid("config", "target", "debug")
    target_release_uid = uid("config", "target", "release")

    file_ref_lines = []
    for rel in source_files:
        file_ref_lines.append(
            f'\t\t{uid("fileref", rel)} /* {os.path.basename(rel)} */ = {{isa = PBXFileReference; '
            f'lastKnownFileType = sourcecode.swift; path = {os.path.basename(rel)}; '
            f'sourceTree = "<group>"; }};'
        )
    for file_name, file_type in RESOURCE_FILES:
        file_ref_lines.append(
            f'\t\t{uid("fileref", file_name)} /* {file_name} */ = {{isa = PBXFileReference; '
            f'lastKnownFileType = {file_type}; path = {file_name}; sourceTree = "<group>"; }};'
        )
    file_ref_lines.append(
        f'\t\t{product_ref_uid} /* {TARGET_NAME}.app */ = {{isa = PBXFileReference; '
        f'explicitFileType = wrapper.application; includeInIndex = 0; '
        f'path = {TARGET_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )

    # Build files
    build_file_lines = []
    sources_entries = []
    for rel in source_files:
        bf = uid("buildfile", "sources", rel)
        build_file_lines.append(
            f'\t\t{bf} /* {os.path.basename(rel)} in Sources */ = {{isa = PBXBuildFile; '
            f'fileRef = {uid("fileref", rel)} /* {os.path.basename(rel)} */; }};'
        )
        sources_entries.append(f'\t\t\t\t{bf} /* {os.path.basename(rel)} in Sources */,')

    resources_entries = []
    for file_name in ("Assets.xcassets", "PrivacyInfo.xcprivacy", "Localizable.xcstrings"):
        bf = uid("buildfile", "resources", file_name)
        build_file_lines.append(
            f'\t\t{bf} /* {file_name} in Resources */ = {{isa = PBXBuildFile; '
            f'fileRef = {uid("fileref", file_name)} /* {file_name} */; }};'
        )
        resources_entries.append(f'\t\t\t\t{bf} /* {file_name} in Resources */,')

    # Groups
    group_lines = []

    def emit_group(group: Group) -> str:
        group_uid = uid("group", group.path or group.name)
        children = []
        for child_group in group.groups:
            children.append((emit_group(child_group), child_group.name))
        for file_name, file_uid in group.files:
            children.append((file_uid, file_name))

        children_text = "".join(f'\t\t\t\t{ref} /* {name} */,\n' for ref, name in children)
        group_lines.append(
            f'\t\t{group_uid} /* {group.name} */ = {{\n'
            f'\t\t\tisa = PBXGroup;\n'
            f'\t\t\tchildren = (\n{children_text}'
            f'\t\t\t);\n'
            f'\t\t\tpath = {group.path};\n'
            f'\t\t\tsourceTree = "<group>";\n'
            f'\t\t}};'
        )
        return group_uid

    root_group_uid = emit_group(tree)
    main_group_uid = uid("group", "main")

    # Build configurations
    config_lines = [
        render_config("Debug", project_debug_uid, PROJECT_DEBUG_SETTINGS),
        render_config("Release", project_release_uid, PROJECT_RELEASE_SETTINGS),
        render_config("Debug", target_debug_uid, TARGET_DEBUG_SETTINGS),
        render_config("Release", target_release_uid, TARGET_RELEASE_SETTINGS),
    ]

    out = []
    out.append("// !$*UTF8*$!")
    out.append("{")
    out.append("\tarchiveVersion = 1;")
    out.append("\tclasses = {")
    out.append("\t};")
    out.append(f"\tobjectVersion = {OBJECT_VERSION};")
    out.append("\tobjects = {")
    out.append("")
    out.append("/* Begin PBXBuildFile section */")
    out.extend(build_file_lines)
    out.append("/* End PBXBuildFile section */")
    out.append("")
    out.append("/* Begin PBXFileReference section */")
    out.extend(file_ref_lines)
    out.append("/* End PBXFileReference section */")
    out.append("")
    out.append("/* Begin PBXFrameworksBuildPhase section */")
    out.append(
        f'\t\t{frameworks_phase_uid} /* Frameworks */ = {{\n'
        f'\t\t\tisa = PBXFrameworksBuildPhase;\n'
        f'\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n\t\t\t);\n'
        f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
        f'\t\t}};'
    )
    out.append("/* End PBXFrameworksBuildPhase section */")
    out.append("")
    out.append("/* Begin PBXGroup section */")
    out.append(
        f'\t\t{main_group_uid} = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\t{root_group_uid} /* {TARGET_NAME} */,\n'
        f'\t\t\t\t{products_group_uid} /* Products */,\n'
        f'\t\t\t);\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};'
    )
    out.append(
        f'\t\t{products_group_uid} /* Products */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\t{product_ref_uid} /* {TARGET_NAME}.app */,\n'
        f'\t\t\t);\n'
        f'\t\t\tname = Products;\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};'
    )
    out.extend(group_lines)
    out.append("/* End PBXGroup section */")
    out.append("")
    out.append("/* Begin PBXNativeTarget section */")
    out.append(
        f'\t\t{target_uid} /* {TARGET_NAME} */ = {{\n'
        f'\t\t\tisa = PBXNativeTarget;\n'
        f'\t\t\tbuildConfigurationList = {target_cfg_list_uid} /* Build configuration list for PBXNativeTarget "{TARGET_NAME}" */;\n'
        f'\t\t\tbuildPhases = (\n'
        f'\t\t\t\t{sources_phase_uid} /* Sources */,\n'
        f'\t\t\t\t{frameworks_phase_uid} /* Frameworks */,\n'
        f'\t\t\t\t{resources_phase_uid} /* Resources */,\n'
        f'\t\t\t);\n'
        f'\t\t\tbuildRules = (\n\t\t\t);\n'
        f'\t\t\tdependencies = (\n\t\t\t);\n'
        f'\t\t\tname = {TARGET_NAME};\n'
        f'\t\t\tpackageProductDependencies = (\n\t\t\t);\n'
        f'\t\t\tproductName = {TARGET_NAME};\n'
        f'\t\t\tproductReference = {product_ref_uid} /* {TARGET_NAME}.app */;\n'
        f'\t\t\tproductType = "com.apple.product-type.application";\n'
        f'\t\t}};'
    )
    out.append("/* End PBXNativeTarget section */")
    out.append("")
    out.append("/* Begin PBXProject section */")
    out.append(
        f'\t\t{project_uid} /* Project object */ = {{\n'
        f'\t\t\tisa = PBXProject;\n'
        f'\t\t\tattributes = {{\n'
        f'\t\t\t\tBuildIndependentTargetsInParallel = 1;\n'
        f'\t\t\t\tLastSwiftUpdateCheck = {TOOLS_VERSION};\n'
        f'\t\t\t\tLastUpgradeCheck = {TOOLS_VERSION};\n'
        f'\t\t\t\tTargetAttributes = {{\n'
        f'\t\t\t\t\t{target_uid} = {{\n'
        f'\t\t\t\t\t\tCreatedOnToolsVersion = {TOOLS_VERSION};\n'
        f'\t\t\t\t\t}};\n'
        f'\t\t\t\t}};\n'
        f'\t\t\t}};\n'
        f'\t\t\tbuildConfigurationList = {project_cfg_list_uid} /* Build configuration list for PBXProject "{TARGET_NAME}" */;\n'
        f'\t\t\tcompatibilityVersion = "{COMPATIBILITY_VERSION}";\n'
        f'\t\t\tdevelopmentRegion = vi;\n'
        f'\t\t\thasScannedForEncodings = 0;\n'
        f'\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tvi,\n\t\t\t\tBase,\n\t\t\t);\n'
        f'\t\t\tmainGroup = {main_group_uid};\n'
        f'\t\t\tproductRefGroup = {products_group_uid} /* Products */;\n'
        f'\t\t\tprojectDirPath = "";\n'
        f'\t\t\tprojectRoot = "";\n'
        f'\t\t\ttargets = (\n'
        f'\t\t\t\t{target_uid} /* {TARGET_NAME} */,\n'
        f'\t\t\t);\n'
        f'\t\t}};'
    )
    out.append("/* End PBXProject section */")
    out.append("")
    out.append("/* Begin PBXResourcesBuildPhase section */")
    out.append(
        f'\t\t{resources_phase_uid} /* Resources */ = {{\n'
        f'\t\t\tisa = PBXResourcesBuildPhase;\n'
        f'\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n'
        + "\n".join(resources_entries)
        + f'\n\t\t\t);\n'
        f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
        f'\t\t}};'
    )
    out.append("/* End PBXResourcesBuildPhase section */")
    out.append("")
    out.append("/* Begin PBXSourcesBuildPhase section */")
    out.append(
        f'\t\t{sources_phase_uid} /* Sources */ = {{\n'
        f'\t\t\tisa = PBXSourcesBuildPhase;\n'
        f'\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n'
        + "\n".join(sources_entries)
        + f'\n\t\t\t);\n'
        f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n'
        f'\t\t}};'
    )
    out.append("/* End PBXSourcesBuildPhase section */")
    out.append("")
    out.append("/* Begin XCBuildConfiguration section */")
    out.extend(config_lines)
    out.append("/* End XCBuildConfiguration section */")
    out.append("")
    out.append("/* Begin XCConfigurationList section */")
    out.append(
        f'\t\t{project_cfg_list_uid} /* Build configuration list for PBXProject "{TARGET_NAME}" */ = {{\n'
        f'\t\t\tisa = XCConfigurationList;\n'
        f'\t\t\tbuildConfigurations = (\n'
        f'\t\t\t\t{project_debug_uid} /* Debug */,\n'
        f'\t\t\t\t{project_release_uid} /* Release */,\n'
        f'\t\t\t);\n'
        f'\t\t\tdefaultConfigurationIsVisible = 0;\n'
        f'\t\t\tdefaultConfigurationName = Release;\n'
        f'\t\t}};'
    )
    out.append(
        f'\t\t{target_cfg_list_uid} /* Build configuration list for PBXNativeTarget "{TARGET_NAME}" */ = {{\n'
        f'\t\t\tisa = XCConfigurationList;\n'
        f'\t\t\tbuildConfigurations = (\n'
        f'\t\t\t\t{target_debug_uid} /* Debug */,\n'
        f'\t\t\t\t{target_release_uid} /* Release */,\n'
        f'\t\t\t);\n'
        f'\t\t\tdefaultConfigurationIsVisible = 0;\n'
        f'\t\t\tdefaultConfigurationName = Release;\n'
        f'\t\t}};'
    )
    out.append("/* End XCConfigurationList section */")
    out.append("\t};")
    out.append(f"\trootObject = {project_uid} /* Project object */;")
    out.append("}")

    os.makedirs(PROJECT_DIR, exist_ok=True)
    pbxproj_path = os.path.join(PROJECT_DIR, "project.pbxproj")
    with open(pbxproj_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")

    # ---------------- workspace ----------------
    workspace_dir = os.path.join(PROJECT_DIR, "project.xcworkspace")
    os.makedirs(workspace_dir, exist_ok=True)
    with open(os.path.join(workspace_dir, "contents.xcworkspacedata"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Workspace\n'
            '   version = "1.0">\n'
            '   <FileRef\n'
            '      location = "self:">\n'
            '   </FileRef>\n'
            '</Workspace>\n'
        )
    shared_dir = os.path.join(workspace_dir, "xcshareddata")
    os.makedirs(shared_dir, exist_ok=True)
    with open(os.path.join(shared_dir, "IDEWorkspaceChecks.plist"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
            '<plist version="1.0">\n'
            '<dict>\n'
            '\t<key>IDEDidComputeMac32BitWarning</key>\n'
            '\t<true/>\n'
            '</dict>\n'
            '</plist>\n'
        )

    # ---------------- scheme ----------------
    scheme_dir = os.path.join(PROJECT_DIR, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "{TOOLS_VERSION}"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_uid}"
               BuildableName = "{TARGET_NAME}.app"
               BlueprintName = "{TARGET_NAME}"
               ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uid}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uid}"
            BuildableName = "{TARGET_NAME}.app"
            BlueprintName = "{TARGET_NAME}"
            ReferencedContainer = "container:{TARGET_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    with open(os.path.join(scheme_dir, f"{TARGET_NAME}.xcscheme"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(scheme)

    print(f"Da sinh {pbxproj_path}")
    print(f"  {len(source_files)} file Swift")
    for rel in source_files:
        print(f"    - {rel}")


if __name__ == "__main__":
    main()
