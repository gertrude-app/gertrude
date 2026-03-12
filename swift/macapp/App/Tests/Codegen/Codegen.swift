import XCTest

@testable import App

final class Codegen: XCTestCase {
  func test_codegenTypescript() throws {
    if self.envVarSet("CODEGEN_MACAPP")
      || self.envVarSet("CODEGEN_APPVIEWS")
      || self.envVarSet("CODEGEN_TYPESCRIPT") {
      try AppWebViewStoreTypes().write()
    }
  }

  func envVarSet(_ name: String) -> Bool {
    ProcessInfo.processInfo.environment[name] != nil
  }
}
