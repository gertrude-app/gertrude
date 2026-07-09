// swift-tools-version:6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Duet",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "Duet", targets: ["Duet"]),
    .library(name: "DuetSQL", targets: ["DuetSQL"]),
  ],
  dependencies: [
    .package(path: "../x-kit"),
    .package(path: "../x-expect"),
    .package("vapor/fluent-postgres-driver@2.9.2"),
    .package("jaredh159/swift-tagged@0.10.1"),
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
  ],
  targets: [
    .target(
      name: "Duet",
      dependencies: [
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .macro(
      name: "DuetMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .target(
      name: "DuetSQL",
      dependencies: [
        "Duet",
        "DuetMacros",
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "XCore", package: "x-kit"),
        .product(name: "Tagged", package: "swift-tagged"),
      ],
      swiftSettings: [.unsafeFlags(["-Xfrontend", "-warnings-as-errors"])],
    ),
    .testTarget(
      name: "DuetSQLTests",
      dependencies: ["DuetSQL", .product(name: "XExpect", package: "x-expect")],
    ),
  ],
)

#if os(macOS)
  package.dependencies.append(
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
  )
  package.targets.append(
    .testTarget(
      name: "DuetMacrosTests",
      dependencies: [
        "DuetMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ],
    ),
  )
#endif

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
