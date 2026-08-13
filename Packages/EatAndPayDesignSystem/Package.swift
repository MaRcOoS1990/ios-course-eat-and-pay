// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EatAndPayDesignSystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "EatAndPayDesignSystem",
            targets: ["EatAndPayDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "EatAndPayDesignSystem"
        )
    ]
)
