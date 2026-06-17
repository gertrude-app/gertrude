// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "LibTCA",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "LibTCA", targets: ["LibTCA"])],
  dependencies: [
    .package(path: "../lib-core"),
    .package(path: "../lib-views"),
    .package(path: "../../pairql-podcasts"),
    .package(path: "../../x-kit"),
    .package(path: "../../gertie"),
    .package(path: "../../gertie-tca-features"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", exact: "1.6.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.25.0",
      traits: ["ComposableArchitecture2Deprecations"],
    ),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/jaredh159/swift-tagged", exact: "0.10.1"),
    .package(
      url: "https://github.com/pointfreeco/swift-structured-queries",
      exact: "0.31.1",
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
        .product(name: "XCore", package: "x-kit"),
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "GertieTcaFeatures", package: "gertie-tca-features"),
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

if ProcessInfo.processInfo.environment["CI"] != nil
  || ProcessInfo.processInfo.environment["SWIFT_WARNINGS_AS_ERRORS"] != nil {
  for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
      .unsafeFlags(["-Xfrontend", "-warnings-as-errors"]),
    ]
  }
}
