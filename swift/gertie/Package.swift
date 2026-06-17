// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Gertie",
  platforms: [.macOS(.v10_15), .iOS(.v17)],
  products: [
    .library(name: "Gertie", targets: ["Gertie"]),
    .library(name: "GertieBlocker", targets: ["GertieBlocker"]),
    .library(name: "GertieApp", targets: ["GertieApp"]),
  ],
  dependencies: [
    .package("jaredh159/swift-tagged@0.8.2"),
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
    .package(path: "../ts-codable-macro"),
  ],
  targets: [
    .target(
      name: "Gertie",
      dependencies: [
        .product(name: "XCore", package: "x-kit"),
        .product(name: "TaggedTime", package: "swift-tagged"),
        .product(name: "TSCodable", package: "ts-codable-macro"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "GertieTests",
      dependencies: [
        "Gertie",
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .target(
      name: "GertieBlocker",
      dependencies: [
        "Gertie",
        .product(name: "TSCodable", package: "ts-codable-macro"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "GertieBlockerTests",
      dependencies: [
        "GertieBlocker",
        .product(name: "XExpect", package: "x-expect"),
      ],
    ),
    .target(
      name: "GertieApp",
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "GertieAppTests",
      dependencies: ["GertieApp"],
    ),
  ],
)

// helpers

extension PackageDescription.Package.Dependency {
  static func package(_ commitish: String) -> Package.Dependency {
    let parts = commitish.split(separator: "@")
    return .package(
      url: "https://github.com/\(parts[0]).git",
      from: .init(stringLiteral: "\(parts[1])"),
    )
  }
}
