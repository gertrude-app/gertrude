// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibIOS",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [
    .library(name: "LibCore", targets: ["LibCore"]),
    .library(name: "LibFilter", targets: ["LibFilter"]),
    .library(name: "LibController", targets: ["LibController"]),
    .library(name: "LibClients", targets: ["LibClients"]),
    .library(name: "LibApp", targets: ["LibApp"]),
    .library(name: "LibViews", targets: ["LibViews"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.8.1",
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-concurrency-extras",
      from: "1.3.1",
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.25.0",
      traits: ["ComposableArchitecture2Deprecations"],
    ),
    .package(path: "../../pairql"),
    .package(path: "../../pairql-blocker"),
    .package(path: "../../gertie"),
    .package(path: "../../gertie-tca-features"),
    .package(path: "../../gertie-ui"),
    .package(path: "../../x-expect"),
    .package(path: "../../x-kit"),
  ],
  targets: [
    .target(
      name: "LibCore",
      dependencies: [
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "GertieApp", package: "gertie"),
      ],
    ),
    .target(
      name: "LibFilter",
      dependencies: [
        "LibCore",
        "LibClients",
        .product(name: "XCore", package: "x-kit"),
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ],
    ),
    .target(
      name: "LibApp",
      dependencies: [
        "LibCore",
        "LibClients",
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "GertieTcaFeatures", package: "gertie-tca-features"),
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
    ),
    .target(
      name: "LibController",
      dependencies: [
        "LibClients",
      ],
    ),
    .target(
      name: "LibViews",
      dependencies: [
        "LibCore",
        "LibApp",
        "LibClients",
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "GertieTcaFeatures", package: "gertie-tca-features"),
        .product(name: "GertieUI", package: "gertie-ui"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ],
    ),
    .target(
      name: "LibClients",
      dependencies: [
        "LibCore",
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "AppEvents", package: "gertie-tca-features"),
        .product(name: "BlockerRoute", package: "pairql-blocker"),
        .product(name: "PairQLClient", package: "pairql"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ],
    ),
    .testTarget(
      name: "LibFilterTests",
      dependencies: [
        "LibFilter",
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .testTarget(
      name: "LibAppTests",
      dependencies: [
        "LibApp",
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .testTarget(
      name: "LibClientsTests",
      dependencies: [
        "LibClients",
        "LibCore",
        .product(name: "GertieBlocker", package: "gertie"),
      ],
    ),
    .testTarget(
      name: "LibControllerTests",
      dependencies: [
        "LibController",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
  ],
)
