// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibViews",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [.library(name: "LibViews", targets: ["LibViews"])],
  targets: [
    .target(
      name: "LibViews",
      exclude: ["FakeEntry.swift"],
    ),
    .testTarget(
      name: "LibViewsTests",
      dependencies: ["LibViews"],
    ),
  ],
)
