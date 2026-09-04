// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "identity_verification_flutter",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "identity-verification-flutter",
            targets: ["identity_verification_flutter"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "identity_verification_flutter",
            dependencies: [],
            resources: []
        )
    ]
)
