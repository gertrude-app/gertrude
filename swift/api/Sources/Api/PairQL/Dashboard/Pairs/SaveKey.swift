import Foundation
import Gertie
import PairQL

struct SaveKey: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var isNew: Bool
    var id: Key.Id
    var keychainId: Keychain.Id
    var key: Gertie.Key
    var comment: String?
    var expiration: Date?
  }
}

// resolver

extension SaveKey: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    if input.key.targetsCloudflareEch {
      throw context.error(
        id: "734da77b",
        type: .badRequest,
        debugMessage: "rejected key targeting cloudflare-ech.com",
        userMessage: "Gertrude blocks cloudflare-ech.com automatically — no key needed.",
        showContactSupport: false,
      )
    }
    if let regexError = input.key.domainRegexValidationError {
      throw context.error(
        id: "1b74e25b",
        type: .badRequest,
        debugMessage: "domainRegex validation failed: \(regexError)",
        userMessage: regexError,
        showContactSupport: false,
      )
    }
    let keychain = try await context.parent.keychain(input.keychainId, in: context.db)
    if case .skeleton = input.key, !keychain.isPublic {
      throw context.error(
        id: "d2f81a9c",
        type: .badRequest,
        debugMessage: "rejected skeleton key for non-public keychain",
        userMessage: "App keys can no longer be created here — manage app internet access from the child's Mac Apps screen instead.",
        showContactSupport: false,
      )
    }
    if input.isNew {
      let existingKeys = try await keychain.keys(in: context.db)
      if var existing = existingKeys.first(where: { $0.key == input.key }) {
        var needsUpdate = false
        if let comment = input.comment, comment != existing.comment {
          existing.comment = comment
          needsUpdate = true
        }
        if input.expiration != existing.deletedAt {
          existing.deletedAt = input.expiration
          needsUpdate = true
        }
        if needsUpdate {
          try await context.db.update(existing)
        }
      } else {
        try await context.db.create(Key(
          id: input.id,
          keychainId: keychain.id,
          key: input.key,
          comment: input.comment,
          deletedAt: input.expiration,
        ))
        let detail = "key opening \(input.key.simpleDescription) added to keychain '\(keychain.name)'"
        dashSecurityEvent(.keyCreated, detail, in: context)
      }
    } else {
      let existingKeys = try await keychain.keys(in: context.db)
      let conflict = existingKeys.first(where: { $0.key == input.key && $0.id != input.id })
      if var conflict {
        conflict.comment = input.comment
        conflict.deletedAt = input.expiration
        try await context.db.update(conflict)
        try await context.db.delete(input.id, force: true)
      } else {
        var key = try await context.db.find(input.id)
        key.comment = input.comment
        key.key = input.key
        key.deletedAt = input.expiration
        try await context.db.update(key)
      }
    }
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .usersWith(keychain: keychain.id))
    return .success
  }
}

extension Gertie.Key {
  var domainRegexValidationError: String? {
    guard case .domainRegex(let pattern, _) = self else { return nil }
    return validateDomainRegexPattern(pattern.string)
  }

  var targetsCloudflareEch: Bool {
    let hostname: String? = switch self {
    case .domain(let domain, _), .anySubdomain(let domain, _): domain.string
    case .path(let path, _): path.domain.string
    case .domainRegex, .ipAddress, .skeleton: nil
    }
    guard let hostname else { return false }
    return hostname == "cloudflare-ech.com" || hostname.hasSuffix(".cloudflare-ech.com")
  }

  var simpleDescription: String {
    switch self {
    case .anySubdomain(let domain, let scope):
      "any subdomain of \(domain.string) for \(scope.simpleDescription)"
    case .domain(let domain, let scope):
      "domain \(domain.string) for \(scope.simpleDescription)"
    case .domainRegex(let pattern, let scope):
      "domains matching pattern: \(pattern.string) for \(scope.simpleDescription)"
    case .ipAddress(let ipAddress, let scope):
      "ip \(ipAddress.string) for \(scope.simpleDescription)"
    case .path(let path, let scope):
      "path \(path.domain.string)\(path.path) for \(scope.simpleDescription)"
    case .skeleton(let scope):
      "unrestricted access for \(scope.simpleDescription)"
    }
  }
}

extension AppScope {
  var simpleDescription: String {
    switch self {
    case .unrestricted:
      "unrestricted"
    case .webBrowsers:
      "all web browsers"
    case .single(let single):
      "single app, \(single.simpleDescription)"
    }
  }
}

extension AppScope.Single {
  var simpleDescription: String {
    switch self {
    case .bundleId(let bundleId):
      "bundle=\(bundleId)"
    case .identifiedAppSlug(let slug):
      "slug=\(slug)"
    }
  }
}

private let MAX_DOMAIN_REGEX_PATTERN_LENGTH = 200
private let DOMAIN_REGEX_CANARY_HOSTNAME = "nothing-to-do-with-anything.invalid"

private func validateDomainRegexPattern(_ pattern: String) -> String? {
  if pattern.count > MAX_DOMAIN_REGEX_PATTERN_LENGTH {
    return "regex pattern too long: \(pattern.count) chars, max \(MAX_DOMAIN_REGEX_PATTERN_LENGTH)"
  }
  let regex: NSRegularExpression
  do {
    regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
  } catch {
    let msg = (error as NSError).localizedDescription
    return "invalid regex pattern: \(msg)"
  }
  if regex.firstMatch(in: "", range: NSRange(location: 0, length: 0)) != nil {
    return "regex pattern is too broad: matches the empty string"
  }
  let canary = DOMAIN_REGEX_CANARY_HOSTNAME
  if regex.firstMatch(in: canary, range: NSRange(canary.startIndex..., in: canary)) != nil {
    return "regex pattern is too broad: matches arbitrary hostnames"
  }
  if !patternHasLiteralAlphanumeric(pattern) {
    return "regex pattern must contain at least one literal alphanumeric character"
  }
  return nil
}

private func patternHasLiteralAlphanumeric(_ pattern: String) -> Bool {
  var i = pattern.startIndex
  var inClass = false
  while i < pattern.endIndex {
    let c = pattern[i]
    if c == "\\" {
      let next = pattern.index(after: i)
      if next < pattern.endIndex {
        i = pattern.index(after: next)
      } else {
        i = next
      }
      continue
    }
    if c == "[" {
      inClass = true
      i = pattern.index(after: i)
      continue
    }
    if c == "]" {
      inClass = false
      i = pattern.index(after: i)
      continue
    }
    if !inClass, c.isLetter || c.isNumber {
      return true
    }
    i = pattern.index(after: i)
  }
  return false
}
