// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "IOSRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "IOSRoute", targets: ["IOSRoute"]),
  ],
  dependencies: [
    .package(url: "https://github.com/jaredh159/swift-tagged", exact: "0.8.2"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
  ],
  targets: [
    .target(
      name: "IOSRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "Gertie", package: "gertie"),
        .product(name: "GertieBlocker", package: "gertie"),
        .product(name: "TaggedTime", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
