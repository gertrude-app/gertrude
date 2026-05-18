import Crypto
import Foundation
import XCTest

import XStripe

private func signatureHeader(payload: String, secret: String, timestamp: Int) -> String {
  let signedPayload = "\(timestamp).\(payload)"
  let key = SymmetricKey(data: Data(secret.utf8))
  let hmac = HMAC<SHA256>.authenticationCode(for: Data(signedPayload.utf8), using: key)
  let hex = Data(hmac).map { String(format: "%02x", $0) }.joined()
  return "t=\(timestamp),v1=\(hex)"
}

final class WebhookTests: XCTestCase {
  let payload = #"{"id":"evt_1","type":"invoice.paid"}"#
  let secret = "whsec_test_secret"
  let timestamp = 1_700_000_000

  func testValidSignaturePasses() {
    let header = signatureHeader(payload: payload, secret: secret, timestamp: timestamp)
    XCTAssertTrue(Stripe.Webhook.verifySignature(
      payload: self.payload,
      signature: header,
      secret: self.secret,
      currentTime: Date(timeIntervalSince1970: TimeInterval(self.timestamp + 10)),
    ))
  }

  func testWrongSecretFails() {
    let header = signatureHeader(payload: payload, secret: secret, timestamp: timestamp)
    XCTAssertFalse(Stripe.Webhook.verifySignature(
      payload: self.payload,
      signature: header,
      secret: "whsec_wrong_secret",
      currentTime: Date(timeIntervalSince1970: TimeInterval(self.timestamp + 10)),
    ))
  }

  func testExpiredTimestampFails() {
    let header = signatureHeader(payload: payload, secret: secret, timestamp: timestamp)
    XCTAssertFalse(Stripe.Webhook.verifySignature(
      payload: self.payload,
      signature: header,
      secret: self.secret,
      tolerance: 300,
      currentTime: Date(timeIntervalSince1970: TimeInterval(self.timestamp + 1000)),
    ))
  }
}
