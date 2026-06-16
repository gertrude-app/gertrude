// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "skip-sql-probe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SkipSQLProbe", type: .dynamic, targets: ["SkipSQLProbe"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
        .package(url: "https://source.skip.tools/skip-sql.git", from: "0.16.0"),
    ],
    targets: [
        .target(
            name: "SkipSQLProbe",
            dependencies: [
                .product(name: "SkipSQLPlus", package: "skip-sql"),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
