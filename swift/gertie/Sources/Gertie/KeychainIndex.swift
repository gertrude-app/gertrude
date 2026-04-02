import Foundation

public struct KeychainIndex: Equatable, Sendable {
  public struct DomainMatch: Equatable, Sendable {
    public let ruleKeyId: UUID
    public let scope: AppScope
    public let keychainId: UUID
    public let schedule: RuleSchedule?
  }

  public struct KeychainRemainder: Equatable, Sendable {
    public let keychainId: UUID
    public let schedule: RuleSchedule?
    public let keys: [RuleKey]
  }

  public let exactDomains: [[UInt8]: [DomainMatch]]
  public let remainders: [KeychainRemainder]

  public init(keychains: [RuleKeychain]) {
    var domainMap: [[UInt8]: [DomainMatch]] = [:]
    var remainders: [KeychainRemainder] = []

    for keychain in keychains {
      var nonDomainKeys: [RuleKey] = []
      for ruleKey in keychain.keys {
        switch ruleKey.key {
        case .domain(domain: let domain, scope: let scope):
          let normalized = Self.normalizeUTF8(domain.utf8)
          let match = DomainMatch(
            ruleKeyId: ruleKey.id,
            scope: scope,
            keychainId: keychain.id,
            schedule: keychain.schedule,
          )
          domainMap[normalized, default: []].append(match)
        default:
          nonDomainKeys.append(ruleKey)
        }
      }
      if !nonDomainKeys.isEmpty {
        remainders.append(KeychainRemainder(
          keychainId: keychain.id,
          schedule: keychain.schedule,
          keys: nonDomainKeys,
        ))
      }
    }

    self.exactDomains = domainMap
    self.remainders = remainders
  }

  public static func normalizeUTF8(_ utf8: [UInt8]) -> [UInt8] {
    let www: [UInt8] = [0x77, 0x77, 0x77, 0x2E] // "www."
    if utf8.count > 4, utf8.starts(with: www) {
      return Array(utf8.dropFirst(4))
    }
    return utf8
  }
}
