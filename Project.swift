// Project.swift - Tuist Configuration
import ProjectDescription

let project = Project(
    name: "PythonRunner",
    organizationName: "com.pythonrunner.app",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetSchemesGrouping: .singleScheme,
            codeCoverageEnabled: false,
            testingOptions: []
        )
    ),
    packages: [
        // Add any Swift Package dependencies here
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "YOUR_TEAM_ID", // Replace with your team ID
            "CODE_SIGN_STYLE": "Automatic",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.pythonrunner.app",
        ],
        configurations: [
            .debug(name: .debug),
            .release(name: .release),
        ]
    ),
    targets: [
        .target(
            name: "PythonRunner",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.PythonRunner",
            deploymentTarget: .iOS(targetVersion: "15.0", devices: [.iphone, .ipad]),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight",
                    ],
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight",
                    ],
                    "UISupportsDocumentBrowser": true,
                    "CFBundleDocumentTypes": [
                        [
                            "CFBundleTypeName": "Python Script",
                            "CFBundleTypeRole": "Editor",
                            "LSItemContentTypes": ["public.python-script"],
                            "LSHandlerRank": "Owner",
                        ],
                    ],
                    "UTExportedTypeDeclarations": [
                        [
                            "UTTypeIdentifier": "public.python-script",
                            "UTTypeDescription": "Python Script",
                            "UTTypeConformsTo": ["public.source-code"],
                            "UTTypeTagSpecification": [
                                "public.filename-extension": ["py"],
                            ],
                        ],
                    ],
                ]
            ),
            sources: ["PythonRunner/Sources/**"],
            resources: [
                "PythonRunner/Resources/**",
                "Python.xcframework", // Python framework
                "python/**", // Python standard library
            ],
            frameworks: [
                .xcframework(path: "Python.xcframework"),
            ],
            settings: .settings(
                base: [
                    "FRAMEWORK_SEARCH_PATHS": "$(PROJECT_DIR)",
                    "HEADER_SEARCH_PATHS": "$(BUILT_PRODUCTS_DIR)/Python.framework/Headers",
                    "ENABLE_TESTABILITY": "YES",
                    "OTHER_LDFLAGS": "-ObjC",
                ]
            ),
            scripts: [
                .pre(
                    script: """
                    set -e
                    mkdir -p "$CODESIGNING_FOLDER_PATH/python/lib"
                    if [ "$EFFECTIVE_PLATFORM_NAME" = "-iphonesimulator" ]; then
                        echo "Installing Python modules for iOS Simulator"
                        rsync -au --delete "$PROJECT_DIR/Python.xcframework/ios-arm64_x86_64-simulator/lib/" "$CODESIGNING_FOLDER_PATH/python/lib/"
                    else
                        echo "Installing Python modules for iOS Device"
                        rsync -au --delete "$PROJECT_DIR/Python.xcframework/ios-arm64/lib/" "$CODESIGNING_FOLDER_PATH/python/lib/"
                    fi
                    """,
                    name: "Install Python Standard Library"
                ),
                .pre(
                    script: """
                    set -e

                    install_dylib () {
                        INSTALL_BASE=$1
                        FULL_EXT=$2

                        EXT=$(basename "$FULL_EXT")
                        RELATIVE_EXT=${FULL_EXT#$CODESIGNING_FOLDER_PATH/}
                        PYTHON_EXT=${RELATIVE_EXT/$INSTALL_BASE/}
                        FULL_MODULE_NAME=$(echo $PYTHON_EXT | cut -d "." -f 1 | tr "/" ".");
                        FRAMEWORK_BUNDLE_ID=$(echo $PRODUCT_BUNDLE_IDENTIFIER.$FULL_MODULE_NAME | tr "_" "-")
                        FRAMEWORK_FOLDER="Frameworks/$FULL_MODULE_NAME.framework"

                        if [ ! -d "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER" ]; then
                            echo "Creating framework for $RELATIVE_EXT"
                            mkdir -p "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER"
                            cp "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                            plutil -replace CFBundleExecutable -string "$FULL_MODULE_NAME" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                            plutil -replace CFBundleIdentifier -string "$FRAMEWORK_BUNDLE_ID" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/Info.plist"
                        fi

                        echo "Installing binary for $FRAMEWORK_FOLDER/$FULL_MODULE_NAME"
                        mv "$FULL_EXT" "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/$FULL_MODULE_NAME"
                        echo "$FRAMEWORK_FOLDER/$FULL_MODULE_NAME" > ${FULL_EXT%.so}.fwork
                        echo "${RELATIVE_EXT%.so}.fwork" > "$CODESIGNING_FOLDER_PATH/$FRAMEWORK_FOLDER/$FULL_MODULE_NAME.origin"
                     }

                     PYTHON_VER=$(ls -1 "$CODESIGNING_FOLDER_PATH/python/lib" | head -1)
                     if [ -n "$PYTHON_VER" ]; then
                         echo "Install Python $PYTHON_VER standard library extension modules..."
                         find "$CODESIGNING_FOLDER_PATH/python/lib/$PYTHON_VER/lib-dynload" -name "*.so" 2>/dev/null | while read FULL_EXT; do
                            install_dylib python/lib/$PYTHON_VER/lib-dynload/ "$FULL_EXT"
                         done
                     fi

                     rm -f "$CODESIGNING_FOLDER_PATH/dylib-Info-template.plist"

                     echo "Signing frameworks..."
                     find "$CODESIGNING_FOLDER_PATH/Frameworks" -name "*.framework" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} -o runtime --timestamp=none --preserve-metadata=identifier,entitlements,flags --generate-entitlement-der "{}" \\; 2>/dev/null || true
                    """,
                    name: "Prepare Python Binary Modules"
                ),
            ]
        ),
    ]
)
