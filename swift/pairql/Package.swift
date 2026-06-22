// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PairQL",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "PairQL", targets: ["PairQL"]),
    .library(name: "PairQLClient", targets: ["PairQLClient"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.6.2"),
    .package(path: "../x-kit"),
  ],
  targets: [
    .target(
      name: "PairQL",
      dependencies: [.product(name: "URLRouting", package: "swift-url-routing")],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .target(
      name: "PairQLClient",
      dependencies: [
        "PairQL",
        .product(name: "XCore", package: "x-kit"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
  ],
)
