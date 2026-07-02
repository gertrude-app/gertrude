// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "IOSAppsRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "IOSAppsRoute", targets: ["IOSAppsRoute"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.2"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
  ],
  targets: [
    .target(
      name: "IOSAppsRoute",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "GertieApp", package: "gertie"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
