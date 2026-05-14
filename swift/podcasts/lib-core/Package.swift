// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "LibCore",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "LibCore", targets: ["LibCore"])],
  dependencies: [],
  targets: [
    .target(
      name: "LibCore",
      dependencies: [],
    ),
  ],
)
