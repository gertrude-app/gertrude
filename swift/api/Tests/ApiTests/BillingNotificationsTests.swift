import XCTest
import XExpect

@testable import Api

final class BillingNotificationsTests: ApiTestCase, @unchecked Sendable {
  func testFirstPaymentSlackMessageIncludesReferralContext() {
    let referrer = Parent.random(with: {
      $0.referralCode = "PARENT-ONE"
    })

    let message = firstPaymentSlackMessage("customer", .full, referrer)

    expect(message).toContain("referral: `PARENT-ONE`")
    expect(message).toContain(referrer.email.rawValue)
  }

  func testFirstPaymentSlackMessageOmitsReferralContextWithoutReferrer() {
    let message = firstPaymentSlackMessage("customer", .full, nil)

    expect(message).not.toContain("referral:")
  }
}
