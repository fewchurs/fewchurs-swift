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
            name: "FeatureRequestKit"
        ),
        .testTarget(
            name: "FeatureRequestKitTests",
            dependencies: ["FeatureRequestKit"]
        ),
    ]
)
