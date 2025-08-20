import ProjectDescription

let project = Project(
    name: "PythonRunner",
    targets: [
        .target(
            name: "PythonRunner",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.PythonRunner",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["PythonRunner/Sources/**"],
            resources: ["PythonRunner/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "PythonRunnerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.PythonRunnerTests",
            infoPlist: .default,
            sources: ["PythonRunner/Tests/**"],
            resources: [],
            dependencies: [.target(name: "PythonRunner")]
        ),
    ]
)
