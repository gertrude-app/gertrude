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
    .package(path: "../pairql"),
  ],
  targets: [
    .target(
      name: "MusicRoute",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing"),
        .product(name: "PairQL", package: "pairql"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
