// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibTCA",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "LibTCA", targets: ["LibTCA"])],
  dependencies: [
    .package(path: "../lib-views"),
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
        .product(name: "Tagged", package: "swift-tagged"),
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
