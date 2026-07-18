// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TiviOS",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16)
    ],
    products: [
        .library(name: "TiviOS", targets: ["TiviOS"])
    ],
    dependencies: [
        // Add dependencies here if needed in future
    ],
    targets: [
        .target(
            name: "TiviOS",
            path: "TiviOS/Sources"
        ),
        .testTarget(
            name: "TiviOSTests",
            dependencies: ["TiviOS"],
            path: "TiviOS/Tests"
        )
    ]
)
