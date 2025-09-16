// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibTCA",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "LibTCA", targets: ["LibTCA"])],
  dependencies: [
    .package(path: "../lib-core"),
    .package(path: "../lib-views"),
    .package(url: "https://github.com/pointfreeco/sharing-grdb", exact: "0.5.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-structured-queries",
      from: "0.17.0",
      traits: ["StructuredQueriesTagged"],
    ),
  ],
  targets: [
    .target(
      name: "LibTCA",
      dependencies: [
        .product(name: "SharingGRDB", package: "sharing-grdb"),
        .product(name: "LibCore", package: "lib-core"),
        .product(name: "LibViews", package: "lib-views"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "LibTCATests",
      dependencies: ["LibTCA"]
    ),
  ]
)
