// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "identity_verification_flutter_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "identity_verification_flutter_ios",
            targets: ["identity_verification_flutter_ios"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "identity_verification_flutter_ios",
            dependencies: [],
            resources: []
        )
    ]
)
