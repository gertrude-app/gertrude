// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibTCA",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "LibTCA", targets: ["LibTCA"])],
  dependencies: [
    .package(path: "../lib-core"),
    .package(path: "../lib-views"),
    .package(path: "../../pairql-podcasts"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", exact: "1.4.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.22.3"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-structured-queries",
      from: "0.22.0",
      traits: ["StructuredQueriesTagged"],
    ),
  ],
  targets: [
    .target(
      name: "LibTCA",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data"),
        .product(name: "LibCore", package: "lib-core"),
        .product(name: "LibViews", package: "lib-views"),
        .product(name: "PodcastRoute", package: "pairql-podcasts"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      resources: [.process("Resources")],
    ),
    .testTarget(
      name: "LibTCATests",
      dependencies: [
        "LibTCA",
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
      ],
    ),
  ],
)
