// swift-tools-version: 6.0
import Foundation
import PackageDescription

let package = Package(
  name: "XExpect",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "XExpect", targets: ["XExpect"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: "1.3.2"),
  ],
  targets: [
    .target(
      name: "XExpect",
      dependencies: [
        .product(name: "CustomDump", package: "swift-custom-dump"),
      ],
    ),
  ],
)

if ProcessInfo.processInfo.environment["CI"] != nil
  || ProcessInfo.processInfo.environment["SWIFT_WARNINGS_AS_ERRORS"] != nil {
  for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
      .unsafeFlags(["-Xfrontend", "-warnings-as-errors"]),
    ]
  }
}
