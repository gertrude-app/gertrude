// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "BlockerRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "BlockerRoute", targets: ["BlockerRoute"]),
  ],
  dependencies: [
    .package(url: "https://github.com/jaredh159/swift-tagged", exact: "0.10.1"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
  ],
  targets: [
    .target(
      name: "BlockerRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "Gertie", package: "gertie"),
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "TaggedTime", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
