// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Fewchurs",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Fewchurs",
            targets: ["Fewchurs"]
        ),
    ],
    targets: [
        .target(
            name: "Fewchurs",
            resources: [
                .copy("PrivacyInfo.xcprivacy"),
                .process("Localizable.xcstrings")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FewchursTests",
            dependencies: ["Fewchurs"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
