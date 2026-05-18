// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "XStripe",
  platforms: [.macOS(.v12)],
  products: [
    .library(name: "XStripe", targets: ["XStripe"]),
  ],
  dependencies: [
    .package(path: "../x-http"),
    .package("apple/swift-crypto@4.1.0"),
  ],
  targets: [
    .target(
      name: "XStripe",
      dependencies: [
        .product(name: "XHttp", package: "x-http"),
        .product(name: "Crypto", package: "swift-crypto"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "XStripeTests",
      dependencies: [
        "XStripe",
        .product(name: "Crypto", package: "swift-crypto"),
      ],
    ),
  ],
)

// helpers

extension PackageDescription.Package.Dependency {
  static func package(_ commitish: String) -> Package.Dependency {
    let parts = commitish.split(separator: "@")
    return .package(
      url: "https://github.com/\(parts[0]).git",
      exact: .init(stringLiteral: "\(parts[1])"),
    )
  }
}
