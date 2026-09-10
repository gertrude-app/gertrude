// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "MusicRoute",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "MusicRoute", targets: ["MusicRoute"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../gertie"),
    .package(path: "../pairql"),
    .package(path: "../ts-codable-macro"),
  ],
  targets: [
    .target(
      name: "MusicRoute",
      dependencies: [
        .product(name: "GertieApp", package: "gertie"),
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "TSCodable", package: "ts-codable-macro"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
