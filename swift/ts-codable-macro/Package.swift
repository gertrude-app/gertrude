// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "ts-codable-macro",
  platforms: [.macOS(.v10_15), .iOS(.v13)],
  products: [
    .library(name: "TSCodable", targets: ["TSCodable"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
  ],
  targets: [
    .macro(
      name: "TSCodableMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
      ],
    ),
    .target(
      name: "TSCodable",
      dependencies: ["TSCodableMacros"],
    ),
  ],
)

#if os(macOS)
  package.dependencies.append(
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.5.0"),
  )
  package.targets.append(
    .testTarget(
      name: "TSCodableMacrosTests",
      dependencies: [
        "TSCodableMacros",
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ],
    ),
  )
#endif
