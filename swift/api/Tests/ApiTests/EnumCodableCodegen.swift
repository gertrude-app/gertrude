import Foundation
import Gertie
import GertieIOS
import TypeScriptInterop
import XCTest

@testable import Api

final class Codegen: XCTestCase {
  func test_codegenSwift() throws {
    if self.envVarSet("CODEGEN_API")
      || self.envVarSet("CODEGEN_TS_CODABLE_ENUMS")
      || self.envVarSet("CODEGEN_SWIFT") {
      try ApiTypeScriptEnumsCodableGenerator().write()
    }
  }

  func envVarSet(_ name: String) -> Bool {
    ProcessInfo.processInfo.environment[name] != nil
  }
}

struct ApiTypeScriptEnumsCodableGenerator: AggregateCodeGenerator {
  static let repoRoot: String = {
    var url = URL(fileURLWithPath: #filePath)
    while url.lastPathComponent != "swift" {
      url = url.deletingLastPathComponent()
    }
    return url.deletingLastPathComponent().path
  }()

  var generators: [CodeGenerator] = [
    EnumCodableGen.EnumsGenerator(
      path: "\(repoRoot)/swift/api/Sources/Api/Extend/Enums+Codable.swift",
      types: [
        (ClaimSupervisionCode.ChildAssignment.self, false),
        (Parent.NotificationMethod.Config.self, false),
        (DecideFilterSuspensionRequest.Decision.self, false),
        (GetAdmin.SubscriptionStatus.self, false),
        (SecurityEventsFeed.FeedEvent.self, false),
        (UserActivity.Item.self, true),
        (ChildComputerStatus.self, false),
        (Plan.self, false),
        (Plan.FreeKind.self, false),
        (BillingStatus.Full.self, false),
        (BillingStatus.Full.TrialKind.self, false),
        (BillingStatus.Light.self, false),
      ],
      imports: [
        "Tagged": "Tagged",
      ],
      replacements: [
        "Foundation.UUID": "UUID",
        "Tagged.Tagged": "Tagged",
      ],
    ),
    EnumCodableGen.EnumsGenerator(
      path: "\(repoRoot)/swift/gertie/Sources/GertieIOS/Enums+Codable.swift",
      types: [(GertieIOS.BlockRule.self, true)],
    ),
  ]
}
