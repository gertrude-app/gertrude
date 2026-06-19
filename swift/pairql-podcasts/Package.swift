// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PodcastRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "PodcastRoute", targets: ["PodcastRoute"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../pairql"),
    .package(path: "../gertie"),
    .package(path: "../ts-codable-macro"),
  ],
  targets: [
    .target(
      name: "PodcastRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "TSCodable", package: "ts-codable-macro"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
