// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "DeviceIdentity",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "DeviceIdentity", targets: ["DeviceIdentity"])],
  dependencies: [
    .package(path: "../pairql-ios-apps"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
  ],
  targets: [
    .target(name: "DeviceIdentity", dependencies: [
      .product(name: "IOSAppsRoute", package: "pairql-ios-apps"),
      .product(name: "Dependencies", package: "swift-dependencies"),
    ]),
    .testTarget(name: "DeviceIdentityTests", dependencies: [
      "DeviceIdentity",
      .product(name: "CustomDump", package: "swift-custom-dump"),
      .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
    ]),
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
