// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "audio-probe",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AudioProbe", type: .dynamic, targets: ["AudioProbe"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.7.8"),
        .package(url: "https://source.skip.tools/skip-av.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "AudioProbe",
            dependencies: [
                .product(name: "SkipAV", package: "skip-av"),
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
    ]
)
