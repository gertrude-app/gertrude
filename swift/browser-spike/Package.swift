// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "browser-spike",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: "BrowserSpike",
      path: "Sources/BrowserSpike",
    ),
    .executableTarget(
      name: "PolicyStub",
      path: "Sources/PolicyStub",
    ),
  ],
)
