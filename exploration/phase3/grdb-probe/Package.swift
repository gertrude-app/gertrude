// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "grdb-probe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GRDBProbe", type: .dynamic, targets: ["GRDBProbe"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "GRDBProbe",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SkipFoundation", package: "skip-foundation"),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
