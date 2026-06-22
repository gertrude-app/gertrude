// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "LibTCA",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "LibTCA", targets: ["LibTCA"])],
  dependencies: [
    .package(path: "../lib-views"),
    .package(path: "../../pairql"),
    .package(path: "../../pairql-music"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
  ],
  targets: [
    .target(
      name: "LibTCA",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "LibViews", package: "lib-views"),
        .product(name: "MusicRoute", package: "pairql-music"),
        .product(name: "PairQLClient", package: "pairql"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      // To re-enable the iOS lock-screen / control-center artwork suppression after App
      // Review, uncomment the define below. It is compiled out by default so the private
      // MediaRemote framework symbols (MRMediaRemote*) never enter the shipped binary
      // (App Store guideline 2.5.1 risk). Also re-enable the dashboard toggle in
      // web/dash/app/src/components/routes/MusicCuration.tsx.
      swiftSettings: [
        // .define("GERTRUDE_MUSIC_NOW_PLAYING_OVERRIDE"),
      ],
    ),
    .testTarget(
      name: "LibTCATests",
      dependencies: [
        "LibTCA",
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ],
    ),
  ],
)

if ProcessInfo.processInfo.environment["CI"] != nil
  || ProcessInfo.processInfo.environment["SWIFT_WARNINGS_AS_ERRORS"] != nil {
  for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
      .unsafeFlags(["-Xfrontend", "-warnings-as-errors"]),
    ]
  }
}
