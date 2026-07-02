// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "GertieTcaFeatures",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "GertieTcaFeatures", targets: ["GertieTcaFeatures"])],
  dependencies: [
    .package(path: "../gertie"),
    .package(path: "../pairql"),
    .package(path: "../pairql-ios-apps"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.25.0",
      traits: ["ComposableArchitecture2Deprecations"],
    ),
  ],
  targets: [
    .target(
      name: "GertieTcaFeatures",
      dependencies: [
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "IOSAppsRoute", package: "pairql-ios-apps"),
        .product(name: "PairQLClient", package: "pairql"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
    ),
    .testTarget(
      name: "GertieTcaFeaturesTests",
      dependencies: [
        "GertieTcaFeatures",
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
