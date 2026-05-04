import Foundation
import XCore

private let regexCache = RegexCache()
private let domainRegexCache = DomainRegexCache()

private final class RegexCache: @unchecked Sendable {
  private var cache: [String: NSRegularExpression] = [:]
  private let lock = NSLock()

  func compiled(_ pattern: String) -> NSRegularExpression? {
    self.lock.lock()
    defer { lock.unlock() }
    if let cached = cache[pattern] { return cached }
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    self.cache[pattern] = regex
    return regex
  }
}

private final class DomainRegexCache: @unchecked Sendable {
  struct Entry {
    let regex: NSRegularExpression
    let inert: Bool
  }

  private var cache: [String: Entry?] = [:]
  private let lock = NSLock()

  func entry(for pattern: String) -> Entry? {
    self.lock.lock()
    defer { self.lock.unlock() }
    if let cached = self.cache[pattern] {
      return cached
    }
    let entry: Entry?
    if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
      let matchesEmpty = regex.firstMatch(
        in: "",
        range: NSRange(location: 0, length: 0),
      ) != nil
      entry = Entry(regex: regex, inert: matchesEmpty)
    } else {
      entry = nil
    }
    self.cache[pattern] = entry
    return entry
  }
}

public func matchesCompiledRegex(_ string: String, pattern: String) -> Bool {
  guard let regex = regexCache.compiled(pattern) else { return false }
  let range = NSRange(string.startIndex..., in: string)
  return regex.firstMatch(in: string, range: range) != nil
}

public func matchesDomainRegex(_ hostname: String, pattern: String) -> Bool {
  guard let entry = domainRegexCache.entry(for: pattern), !entry.inert else {
    return false
  }
  let range = NSRange(hostname.startIndex..., in: hostname)
  return entry.regex.firstMatch(in: hostname, range: range) != nil
}

public extension Key.Domain {
  init?(_ input: String) {
    var domain = input
    if domain.starts(with: "http") {
      domain = domain.regexRemove("^https?://")
    }
    if domain.last == "/" {
      domain.removeLast()
    }
    guard !domain.contains("/"),
          !domain.contains(" "),
          URL(string: domain) != nil else {
      return nil
    }
    let lowered = domain.lowercased()
    string = lowered
    utf8 = Array(lowered.utf8)
  }

  func matches(hostname: String) -> Bool {
    self.matches(lowercasedHostname: hostname.lowercased())
  }

  func matches(lowercasedHostname hostname: String) -> Bool {
    self.matchesUTF8(Array(hostname.utf8))
  }

  func matchesUTF8(_ hostname: [UInt8]) -> Bool {
    let www: [UInt8] = [0x77, 0x77, 0x77, 0x2E] // "www."
    if hostname == utf8 {
      return true
    }

    if hostname.count == utf8.count + 4,
       hostname.starts(with: www),
       hostname.dropFirst(4).elementsEqual(utf8) {
      return true
    }

    if utf8.count == hostname.count + 4,
       utf8.starts(with: www),
       utf8.dropFirst(4).elementsEqual(hostname) {
      return true
    }

    return false
  }

  func matchesAnySubdomain(of hostname: String) -> Bool {
    self.matchesAnySubdomain(ofLowercased: hostname.lowercased())
  }

  func matchesAnySubdomain(ofLowercased hostname: String) -> Bool {
    self.matchesAnySubdomainUTF8(Array(hostname.utf8))
  }

  func matchesAnySubdomainUTF8(_ hostname: [UInt8]) -> Bool {
    self.matchesUTF8(hostname)
      || (hostname.count > utf8.count + 1
        && hostname[hostname.count - utf8.count - 1] == 0x2E // "."
        && hostname.suffix(utf8.count).elementsEqual(utf8))
  }
}

public extension Key.DomainRegexPattern {
  init(_ input: String) {
    string = input
    regex = input
  }
}

public extension Key.Path {
  init?(_ input: String) {
    let parts = input.split(separator: "/", maxSplits: 1)
    guard parts.count == 2, !parts[1].isEmpty,
          let domain = Key.Domain(String(parts[0])) else {
      return nil
    }
    self.domain = domain
    path = String(parts[1]).lowercased()
    if path.contains("*") {
      regex = "^" + domain.string + "/" + path
        .replacingOccurrences(of: ".", with: "\\.")
        .replacingOccurrences(of: "*", with: ".*") + "$"
    } else {
      regex = nil
    }
  }

  func matches(url: String) -> Bool {
    self.matches(lowercasedUrl: url.regexRemove("^https?://").lowercased())
  }

  func matches(lowercasedUrl url: String) -> Bool {
    if let regex {
      matchesCompiledRegex(url, pattern: regex)
    } else {
      url.regexRemove("/$") == domain.string + "/" + path.regexRemove("/$")
    }
  }
}

public extension Key.Ip {
  init?(_ input: String) {
    // these regexes are naive, but probably good enough
    if input.matchesRegex(#"^\d+\.\d+\.\d+\.\d+"#) {
      string = input
    } else if input.matchesRegex(#"^[0-9a-zA-Z]*:[0-9a-zA-Z:%]*$"#) {
      string = input
    } else {
      return nil
    }
  }
}

public extension AppScope {
  static var safeFallback: AppScope {
    .single(.bundleId(UUID().uuidString))
  }
}

// expressible by string literal (test only)

#if DEBUG
  extension Key.Path: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Path(value)!
    }
  }

  extension Key.Ip: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Ip(value)!
    }
  }

  extension Key.DomainRegexPattern: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.DomainRegexPattern(value)
    }
  }

  extension Key.Domain: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      self = Key.Domain(value)!
    }
  }
#endif
