// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibViews",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "LibViews", targets: ["LibViews"])],
  dependencies: [
    .package(path: "../lib-core"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
  ],
  targets: [
    .target(
      name: "LibViews",
      dependencies: [
        .product(name: "LibCore", package: "lib-core"),
      ],
      exclude: ["FakeEntry.swift"],
      resources: [.process("Resources")],
    ),
    .testTarget(
      name: "LibViewsTests",
      dependencies: [
        "LibViews",
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ],
    ),
  ],
)
