// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "tca-probe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TCAProbe", type: .dynamic, targets: ["TCAProbe"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.25.0"
        ),
    ],
    targets: [
        .target(
            name: "TCAProbe",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
