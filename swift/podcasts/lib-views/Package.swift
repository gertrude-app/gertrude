// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LibViews",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "LibViews", targets: ["LibViews"])],
  dependencies: [
    .package(path: "../lib-core"),
  ],
  targets: [
    .target(
      name: "LibViews",
      dependencies: [
        .product(name: "LibCore", package: "lib-core"),
      ],
      exclude: ["FakeEntry.swift"]
    ),
  ]
)
