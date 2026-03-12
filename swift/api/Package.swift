// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "api",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package("vapor/vapor@4.119.1"),
    .package("vapor/fluent@4.11.0"),
    .package("vapor/jwt@5.1.2"),
    .package("vapor/fluent-postgres-driver@2.9.2"),
    .package("onevcat/Rainbow@4.0.1"),
    .package("jaredh159/swift-tagged@0.8.2"),
    .package("pointfreeco/swift-dependencies@1.0.0"),
    .package("pointfreeco/swift-concurrency-extras@1.1.0"),
    .package("m-barthelemy/vapor-queues-fluent-driver@3.0.0-beta1"),
    .package(url: "https://github.com/pointfreeco/vapor-routing", from: "0.1.3"),
    .package(path: "../duet"),
    .package(path: "../gertie"),
    .package(path: "../pairql"),
    .package(path: "../pairql-macapp"),
    .package(path: "../pairql-iosapp"),
    .package(path: "../pairql-podcasts"),
    .package(path: "../ts-interop"),
    .package(path: "../ts-codable-macro"),
    .package(path: "../x-aws"),
    .package(path: "../x-postmark"),
    .package(path: "../x-slack"),
    .package(path: "../x-stripe"),
    .package(path: "../x-expect"),
    .package("apple/swift-certificates@1.15.1"),
    .package("apple/swift-crypto@4.1.0"),
  ],
  targets: [
    .target(
      name: "Api",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "QueuesFluentDriver", package: "vapor-queues-fluent-driver"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "Duet", package: "duet"),
        .product(name: "DuetSQL", package: "duet"),
        .product(name: "TypeScriptInterop", package: "ts-interop"),
        .product(name: "Gertie", package: "gertie"),
        .product(name: "PairQL", package: "pairql"),
        .product(name: "MacAppRoute", package: "pairql-macapp"),
        .product(name: "IOSRoute", package: "pairql-iosapp"),
        .product(name: "PodcastRoute", package: "pairql-podcasts"),
        .product(name: "TaggedTime", package: "swift-tagged"),
        .product(name: "TaggedMoney", package: "swift-tagged"),
        .product(name: "VaporRouting", package: "vapor-routing"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "XAws", package: "x-aws"),
        .product(name: "XPostmark", package: "x-postmark"),
        .product(name: "XSlack", package: "x-slack"),
        .product(name: "XStripe", package: "x-stripe"),
        .product(name: "JWT", package: "jwt"),
        .product(name: "TSCodable", package: "ts-codable-macro"),
        "Rainbow",
        .product(name: "X509", package: "swift-certificates"),
      ],
      exclude: ["Email/Templates/", "Email/Layouts/"],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
      ],
    ),
    .executableTarget(name: "Run", dependencies: [
      .target(name: "Api"),
      .product(name: "Dependencies", package: "swift-dependencies"),
    ]),
    .testTarget(name: "ApiTests", dependencies: [
      .target(name: "Api"),
      .product(name: "XExpect", package: "x-expect"),
      .product(name: "XCTVapor", package: "vapor"),
      .product(name: "X509", package: "swift-certificates"),
      .product(name: "Crypto", package: "swift-crypto"),
    ]),
  ],
)

import Foundation

if ProcessInfo.processInfo.environment["CI"] != nil {
  package.targets[0].swiftSettings?.append(
    .unsafeFlags(["-Xfrontend", "-warnings-as-errors"]),
  )
}

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
