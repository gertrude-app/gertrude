import Crypto
import Foundation

public extension Stripe {
  enum Webhook {
    public static func verifySignature(
      payload: String,
      signature: String,
      secret: String,
      tolerance: TimeInterval = 300,
      currentTime: Date,
    ) -> Bool {
      var timestamp: String?
      var signatures: [String] = []

      for part in signature.split(separator: ",") {
        let kv = part.split(separator: "=", maxSplits: 1)
        guard kv.count == 2 else { continue }
        let key = String(kv[0])
        let value = String(kv[1])
        if key == "t" {
          timestamp = value
        } else if key == "v1" {
          signatures.append(value)
        }
      }

      guard let timestamp, !signatures.isEmpty else {
        return false
      }

      if let timestampInt = Int(timestamp) {
        let eventTime = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        let age = currentTime.timeIntervalSince(eventTime)
        if age < 0 || age > tolerance {
          return false
        }
      } else {
        return false
      }

      let signedPayload = "\(timestamp).\(payload)"
      let key = SymmetricKey(data: Data(secret.utf8))
      let hmac = HMAC<SHA256>.authenticationCode(for: Data(signedPayload.utf8), using: key)
      let expectedSignature = Data(hmac).map { String(format: "%02x", $0) }.joined()

      return signatures.contains { receivedSig in
        guard receivedSig.count == expectedSignature.count else { return false }
        var result: UInt8 = 0
        for (a, b) in zip(receivedSig.utf8, expectedSignature.utf8) {
          result |= a ^ b
        }
        return result == 0
      }
    }
  }
}
