// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LibViews",
  platforms: [.iOS(.v18)],
  products: [.library(name: "LibViews", targets: ["LibViews"])],
  dependencies: [
    .package(path: "../lib-core"),
  ],
  targets: [
    .target(
      name: "LibViews",
      dependencies: [
        .product(name: "LibCore", package: "lib-core"),
      ]
    ),
  ]
)
