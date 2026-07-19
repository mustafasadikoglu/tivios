// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TiviOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "TiviOS", targets: ["TiviOS"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TiviOS",
            path: "TiviOS/Sources",
            exclude: ["TiviOSApp.swift"]
        )
    ]
)
