// swift-tools-version: 5.9
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
