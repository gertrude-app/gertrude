import XCTest
import XExpect

@testable import Api

final class ModelIdentifierTests: XCTestCase {
  func testIPhoneDuoMarketingName() {
    expect(ModelIdentifier.marketingName(for: "iPhone19,4")).toEqual("iPhone Duo")
  }

  func testIPhoneDuoDeviceType() {
    expect(ModelIdentifier.deviceType(from: "iPhone19,4")).toEqual("iPhone")
  }
}
