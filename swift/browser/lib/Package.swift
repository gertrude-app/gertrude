// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LibBrowser",
  platforms: [.macOS(.v11), .iOS(.v15)],
  products: [
    .library(name: "BrowserApp", targets: ["BrowserApp"]),
  ],
  dependencies: [
    // NB: 1.23.2 is the last TCA version that supports macOS 11 (Big Sur).
    // see swift/macapp/App/Package.swift for the same constraint.
    .github("pointfreeco/swift-composable-architecture", exact: "1.23.2"),
    .package(path: "../../x-expect"),
  ],
  targets: [
    .checkedTarget(
      name: "BrowserApp",
      dependencies: [.tca],
    ),
    .testTarget(
      name: "BrowserAppTests",
      dependencies: [
        "BrowserApp",
        "x-expect" => "XExpect",
      ],
    ),
  ],
)

// extensions, helpers

infix operator =>
private func => (lhs: String, rhs: String) -> Target.Dependency {
  .product(name: rhs, package: lhs)
}

extension Target {
  static func checkedTarget(
    name: String,
    dependencies: [Target.Dependency],
  ) -> Target {
    .target(
      name: name,
      dependencies: dependencies,
      swiftSettings: [
        .unsafeFlags([
          "-Xfrontend", "-warn-concurrency",
          "-Xfrontend", "-enable-actor-data-race-checks",
        ]),
      ],
    )
  }
}

extension PackageDescription.Package.Dependency {
  static func github(_ repo: String, exact: String) -> Package.Dependency {
    .package(url: "https://github.com/\(repo).git", exact: .init(stringLiteral: exact))
  }
}

extension Target.Dependency {
  static let tca: Self = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture",
  )
}
