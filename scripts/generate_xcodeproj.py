#!/usr/bin/env python3
"""Generate a SwiftUI Xcode project from the source tree."""
from __future__ import annotations

import os
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "KkanbuStock"
PROJECT = APP_DIR / "KkanbuStock.xcodeproj"
SOURCES = APP_DIR / "KkanbuStock"
TESTS = APP_DIR / "KkanbuStockTests"


def xid() -> str:
    return uuid.uuid4().hex[:24].upper()


def collect(dirpath: Path) -> list[Path]:
    files = []
    for path in sorted(dirpath.rglob("*")):
        if path.suffix in {".swift", ".plist", ".json", ".png"} and "xcodeproj" not in str(path):
            files.append(path)
        if path.suffix == ".xcassets" or path.name.endswith(".colorset") or path.name.endswith(".appiconset"):
            continue
    return files


def main() -> None:
    swift_app = [p for p in collect(SOURCES) if p.suffix == ".swift"]
    assets = SOURCES / "Resources" / "Assets.xcassets"
    tests = [p for p in collect(TESTS) if p.suffix == ".swift"]

    ids = {
        "project": xid(),
        "app_target": xid(),
        "test_target": xid(),
        "app_product": xid(),
        "test_product": xid(),
        "sources_group": xid(),
        "tests_group": xid(),
        "products_group": xid(),
        "main_group": xid(),
        "app_build": xid(),
        "test_build": xid(),
        "project_config_list": xid(),
        "app_config_list": xid(),
        "test_config_list": xid(),
        "debug": xid(),
        "release": xid(),
        "app_debug": xid(),
        "app_release": xid(),
        "test_debug": xid(),
        "test_release": xid(),
        "sources_phase": xid(),
        "resources_phase": xid(),
        "frameworks_phase": xid(),
        "test_sources_phase": xid(),
        "test_frameworks_phase": xid(),
        "assets_file": xid(),
        "container": xid(),
        "dependency": xid(),
    }

    file_refs = {}
    build_files = {}
    for path in swift_app:
        file_refs[path] = xid()
        build_files[path] = xid()
    for path in tests:
        file_refs[path] = xid()
        build_files[path] = xid()

    def rel(path: Path) -> str:
        return str(path.relative_to(APP_DIR))

    pb = []
    pb.append("// !$*UTF8*$!")
    pb.append("{")
    pb.append("\tarchiveVersion = 1;")
    pb.append("\tclasses = {};")
    pb.append("\tobjectVersion = 56;")
    pb.append("\tobjects = {")

    pb.append("\n/* Begin PBXBuildFile section */")
    for path in swift_app:
        pb.append(f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};")
    for path in tests:
        pb.append(f"\t\t{build_files[path]} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};")
    pb.append(f"\t\t{ids['assets_file']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = ASSETSREF /* Assets.xcassets */; }};")
    pb.append("/* End PBXBuildFile section */\n")

    assets_ref = xid()
    pb.append("/* Begin PBXFileReference section */")
    pb.append(f"\t\t{ids['app_product']} /* KkanbuStock.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = KkanbuStock.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pb.append(f"\t\t{ids['test_product']} /* KkanbuStockTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = KkanbuStockTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pb.append(f"\t\t{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    for path in swift_app + tests:
        pb.append(
            f"\t\t{file_refs[path]} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = \"<group>\"; }};"
        )
    pb.append("/* End PBXFileReference section */\n")

    # Groups: keep a flat-ish structure with folders
    def group_tree(base: Path, files: list[Path], group_id: str, path_value: str) -> tuple[str, list[str]]:
        # We'll emit nested groups by directory
        return group_id, []

    dir_groups = {}
    dir_groups[SOURCES] = ids["sources_group"]
    dir_groups[TESTS] = ids["tests_group"]
    extra_groups = []
    for path in swift_app:
        parent = path.parent
        while parent != SOURCES and parent not in dir_groups:
            dir_groups[parent] = xid()
            extra_groups.append(parent)
            parent = parent.parent
    extra_groups = sorted(set(extra_groups), key=lambda p: len(p.parts), reverse=True)

    pb.append("/* Begin PBXGroup section */")
    pb.append(f"\t\t{ids['main_group']} = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append("\t\t\tchildren = (")
    pb.append(f"\t\t\t\t{ids['sources_group']} /* KkanbuStock */,")
    pb.append(f"\t\t\t\t{ids['tests_group']} /* KkanbuStockTests */,")
    pb.append(f"\t\t\t\t{ids['products_group']} /* Products */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")
    pb.append(f"\t\t{ids['products_group']} /* Products */ = {{")
    pb.append("\t\t\tisa = PBXGroup;")
    pb.append(f"\t\t\tchildren = ({ids['app_product']} /* KkanbuStock.app */, {ids['test_product']} /* KkanbuStockTests.xctest */,);")
    pb.append("\t\t\tname = Products;")
    pb.append("\t\t\tsourceTree = \"<group>\";")
    pb.append("\t\t};")

    def children_of(folder: Path) -> list[str]:
        items = []
        for child_dir in sorted([p for p in dir_groups if p.parent == folder], key=lambda x: x.name):
            items.append(f"{dir_groups[child_dir]} /* {child_dir.name} */")
        if folder == SOURCES:
            items.append(f"{assets_ref} /* Assets.xcassets */")
        for path in swift_app + tests:
            if path.parent == folder:
                items.append(f"{file_refs[path]} /* {path.name} */")
        return items

    for folder, gid in sorted(dir_groups.items(), key=lambda kv: str(kv[0])):
        name = folder.name
        rel_path = folder.name
        pb.append(f"\t\t{gid} /* {name} */ = {{")
        pb.append("\t\t\tisa = PBXGroup;")
        pb.append("\t\t\tchildren = (")
        for child in children_of(folder):
            pb.append(f"\t\t\t\t{child},")
        pb.append("\t\t\t);")
        pb.append(f"\t\t\tpath = {name};")
        pb.append("\t\t\tsourceTree = \"<group>\";")
        pb.append("\t\t};")

    pb.append("/* End PBXGroup section */\n")

    pb.append("/* Begin PBXNativeTarget section */")
    pb.append(f"\t\t{ids['app_target']} /* KkanbuStock */ = {{")
    pb.append("\t\t\tisa = PBXNativeTarget;")
    pb.append("\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"KkanbuStock\" */;" % ids["app_config_list"])
    pb.append("\t\t\tbuildPhases = (")
    pb.append(f"\t\t\t\t{ids['sources_phase']} /* Sources */,")
    pb.append(f"\t\t\t\t{ids['frameworks_phase']} /* Frameworks */,")
    pb.append(f"\t\t\t\t{ids['resources_phase']} /* Resources */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tbuildRules = ();")
    pb.append("\t\t\tdependencies = ();")
    pb.append("\t\t\tname = KkanbuStock;")
    pb.append("\t\t\tproductName = KkanbuStock;")
    pb.append(f"\t\t\tproductReference = {ids['app_product']} /* KkanbuStock.app */;")
    pb.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pb.append("\t\t};")
    pb.append(f"\t\t{ids['test_target']} /* KkanbuStockTests */ = {{")
    pb.append("\t\t\tisa = PBXNativeTarget;")
    pb.append("\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"KkanbuStockTests\" */;" % ids["test_config_list"])
    pb.append("\t\t\tbuildPhases = (")
    pb.append(f"\t\t\t\t{ids['test_sources_phase']} /* Sources */,")
    pb.append(f"\t\t\t\t{ids['test_frameworks_phase']} /* Frameworks */,")
    pb.append("\t\t\t);")
    pb.append("\t\t\tbuildRules = ();")
    pb.append(f"\t\t\tdependencies = ({ids['dependency']} /* PBXTargetDependency */,);")
    pb.append("\t\t\tname = KkanbuStockTests;")
    pb.append("\t\t\tproductName = KkanbuStockTests;")
    pb.append(f"\t\t\tproductReference = {ids['test_product']} /* KkanbuStockTests.xctest */;")
    pb.append("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    pb.append("\t\t};")
    pb.append("/* End PBXNativeTarget section */\n")

    pb.append("/* Begin PBXContainerItemProxy section */")
    pb.append(f"\t\t{ids['container']} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {ids['project']} /* Project object */; proxyType = 1; remoteGlobalIDString = {ids['app_target']}; remoteInfo = KkanbuStock; }};")
    pb.append("/* End PBXContainerItemProxy section */\n")
    pb.append("/* Begin PBXTargetDependency section */")
    pb.append(f"\t\t{ids['dependency']} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {ids['app_target']} /* KkanbuStock */; targetProxy = {ids['container']} /* PBXContainerItemProxy */; }};")
    pb.append("/* End PBXTargetDependency section */\n")

    pb.append("/* Begin PBXProject section */")
    pb.append(f"\t\t{ids['project']} /* Project object */ = {{")
    pb.append("\t\t\tisa = PBXProject;")
    pb.append("\t\t\tattributes = {LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; TargetAttributes = {")
    pb.append(f"\t\t\t\t{ids['app_target']} = {{CreatedOnToolsVersion = 16.0; }};")
    pb.append(f"\t\t\t\t{ids['test_target']} = {{CreatedOnToolsVersion = 16.0; TestTargetID = {ids['app_target']}; }};")
    pb.append("\t\t\t}; };")
    pb.append(f"\t\t\tbuildConfigurationList = {ids['project_config_list']} /* Build configuration list for PBXProject \"KkanbuStock\" */;")
    pb.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    pb.append("\t\t\tdevelopmentRegion = ko;")
    pb.append("\t\t\thasScannedForEncodings = 0;")
    pb.append("\t\t\tknownRegions = (en, ko, Base,);")
    pb.append(f"\t\t\tmainGroup = {ids['main_group']};")
    pb.append(f"\t\t\tproductRefGroup = {ids['products_group']} /* Products */;")
    pb.append("\t\t\tprojectDirPath = \"\";")
    pb.append("\t\t\tprojectRoot = \"\";")
    pb.append(f"\t\t\ttargets = ({ids['app_target']} /* KkanbuStock */, {ids['test_target']} /* KkanbuStockTests */,);")
    pb.append("\t\t};")
    pb.append("/* End PBXProject section */\n")

    pb.append("/* Begin PBXResourcesBuildPhase section */")
    pb.append(f"\t\t{ids['resources_phase']} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({ids['assets_file']} /* Assets.xcassets in Resources */,); runOnlyForDeploymentPostprocessing = 0; }};")
    pb.append("/* End PBXResourcesBuildPhase section */\n")

    pb.append("/* Begin PBXFrameworksBuildPhase section */")
    pb.append(f"\t\t{ids['frameworks_phase']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    pb.append(f"\t\t{ids['test_frameworks_phase']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    pb.append("/* End PBXFrameworksBuildPhase section */\n")

    pb.append("/* Begin PBXSourcesBuildPhase section */")
    pb.append(f"\t\t{ids['sources_phase']} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (")
    for path in swift_app:
        pb.append(f"\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    pb.append("\t\t); runOnlyForDeploymentPostprocessing = 0; };")
    pb.append(f"\t\t{ids['test_sources_phase']} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (")
    for path in tests:
        pb.append(f"\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    pb.append("\t\t); runOnlyForDeploymentPostprocessing = 0; };")
    pb.append("/* End PBXSourcesBuildPhase section */\n")

    def xcconfig(cid: str, name: str, extra: str) -> None:
        pb.append(f"\t\t{cid} /* {name} */ = {{")
        pb.append("\t\t\tisa = XCBuildConfiguration;")
        pb.append("\t\t\tbuildSettings = {")
        pb.append(extra)
        pb.append("\t\t\t};")
        pb.append(f"\t\t\tname = {name};")
        pb.append("\t\t};")

    project_settings = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				SDKROOT = iphoneos;
				SWIFT_VERSION = 5.0;
				SWIFT_EMIT_LOC_STRINGS = YES;
"""
    xcconfig(ids["debug"], "Debug", project_settings + "\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";\n\t\t\t\tENABLE_TESTABILITY = YES;")
    xcconfig(ids["release"], "Release", project_settings + "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";\n\t\t\t\tENABLE_NS_ASSERTIONS = NO;")

    app_settings = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = \"주식 깐부\";
				INFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.social-networking\";
				INFOPLIST_KEY_NSCameraUsageDescription = \"증권 앱 화면을 촬영해 종목과 매수가를 인식합니다. 원본 이미지는 친구에게 공유되지 않습니다.\";
				INFOPLIST_KEY_NSPhotoLibraryUsageDescription = \"캡처한 증권 화면에서 종목 정보를 인식합니다. 원본 이미지는 친구에게 공개되지 않습니다.\";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = \"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";
				LD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks\";
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.kkanbu.stock;
				PRODUCT_NAME = KkanbuStock;
				SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = \"1,2\";
"""
    xcconfig(ids["app_debug"], "Debug", app_settings)
    xcconfig(ids["app_release"], "Release", app_settings)

    test_settings = """
				BUNDLE_LOADER = \"$(TEST_HOST)\";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.kkanbu.stock.tests;
				PRODUCT_NAME = \"$(TARGET_NAME)\";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = \"1,2\";
				TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/KkanbuStock.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/KkanbuStock\";
"""
    xcconfig(ids["test_debug"], "Debug", test_settings)
    xcconfig(ids["test_release"], "Release", test_settings)

    pb.append("/* Begin XCConfigurationList section */")
    pb.append(f"\t\t{ids['project_config_list']} /* Build configuration list for PBXProject \"KkanbuStock\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['debug']} /* Debug */, {ids['release']} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    pb.append(f"\t\t{ids['app_config_list']} /* Build configuration list for PBXNativeTarget \"KkanbuStock\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['app_debug']} /* Debug */, {ids['app_release']} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    pb.append(f"\t\t{ids['test_config_list']} /* Build configuration list for PBXNativeTarget \"KkanbuStockTests\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['test_debug']} /* Debug */, {ids['test_release']} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    pb.append("/* End XCConfigurationList section */")

    pb.append("\t};")
    pb.append(f"\trootObject = {ids['project']} /* Project object */;")
    pb.append("}")

    # Fix assets fileRef placeholder
    text = "\n".join(pb).replace("ASSETSREF", assets_ref)
    PROJECT.mkdir(parents=True, exist_ok=True)
    (PROJECT / "project.pbxproj").write_text(text)
    scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "KkanbuStock.xcscheme").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="KkanbuStock.app" BlueprintName="KkanbuStock" ReferencedContainer="container:KkanbuStock.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
      <Testables>
         <TestableReference skipped="NO">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['test_target']}" BuildableName="KkanbuStockTests.xctest" BlueprintName="KkanbuStockTests" ReferencedContainer="container:KkanbuStock.xcodeproj"/>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="KkanbuStock.app" BlueprintName="KkanbuStock" ReferencedContainer="container:KkanbuStock.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ids['app_target']}" BuildableName="KkanbuStock.app" BlueprintName="KkanbuStock" ReferencedContainer="container:KkanbuStock.xcodeproj"/>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration="Debug"/>
   <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
""")
    print(f"Wrote project with {len(swift_app)} app files and {len(tests)} tests")


if __name__ == "__main__":
    main()
