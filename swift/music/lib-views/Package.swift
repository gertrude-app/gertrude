// swift-tools-version: 6.1
import Foundation
import PackageDescription

let package = Package(
  name: "LibViews",
  platforms: [.macOS(.v15), .iOS(.v17)],
  products: [.library(name: "LibViews", targets: ["LibViews"])],
  dependencies: [
    .package(path: "../../gertie-ui"),
  ],
  targets: [
    .target(
      name: "LibViews",
      dependencies: [
        .product(name: "GertieUI", package: "gertie-ui"),
      ],
      resources: [.process("Resources")],
    ),
    .testTarget(
      name: "LibViewsTests",
      dependencies: ["LibViews"],
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
