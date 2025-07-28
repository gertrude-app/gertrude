// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Core",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "Core", targets: ["Core"])],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Core",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "CoreTests",
      dependencies: ["Core"]
    ),
  ]
)
