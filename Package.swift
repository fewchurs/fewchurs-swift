// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureRequestKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureRequestKit",
            targets: ["FeatureRequestKit"]
        ),
    ],
    targets: [
        .target(
            name: "FeatureRequestKit",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FeatureRequestKitTests",
            dependencies: ["FeatureRequestKit"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
