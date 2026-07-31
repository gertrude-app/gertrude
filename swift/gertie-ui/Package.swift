// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "GertieUI",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [
    .library(name: "GertieUI", targets: ["GertieUI"]),
  ],
  targets: [
    .target(name: "GertieUI"),
  ],
)
