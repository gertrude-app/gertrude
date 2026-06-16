// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "deps-probe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DepsProbe", type: .dynamic, targets: ["DepsProbe"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    ],
    targets: [
        .target(
            name: "DepsProbe",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
