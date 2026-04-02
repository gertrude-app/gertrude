import Core
import Dependencies
import Gertie
import XCTest
import XExpect

@testable import Filter

final class FlowDecisionEdgeCaseTests: XCTestCase {

  // MARK: - www. normalization

  func testWwwDomainKeyMatchesNonWwwHostname() {
    let key = RuleKey(key: .domain(domain: "www.safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(hostname: "safe.com")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testNonWwwDomainKeyMatchesWwwHostname() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(hostname: "www.safe.com")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testBothWwwAndNonWwwKeysForSameDomain() {
    let key1 = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let key2 = RuleKey(key: .domain(domain: "www.safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: [key1, key2].into()])
    var flow1 = FilterFlow.test(hostname: "safe.com")
    let decision1 = filter.completedDecision(&flow1)
    expect(decision1.isAllow).toEqual(true)
    var flow2 = FilterFlow.test(hostname: "www.safe.com")
    let decision2 = filter.completedDecision(&flow2)
    expect(decision2.isAllow).toEqual(true)
  }

  func testWwwSubdomainMatchesNonWwwHostname() {
    let key = RuleKey(key: .anySubdomain(domain: "www.safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(hostname: "safe.com")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  // MARK: - domain near-misses (no false positives)

  func testDomainSuffixDoesNotFalseMatch() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    let hostnames = ["evil-safe.com", "notsafe.com", "safe.com.evil.net", "safe.commercial"]
    for hostname in hostnames {
      var flow = FilterFlow.test(hostname: hostname)
      expect(filter.completedDecision(&flow)).toEqual(.block(.defaultNotAllowed))
    }
  }

  func testSubdomainSuffixDoesNotFalseMatch() {
    let key = RuleKey(key: .anySubdomain(domain: "safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    let hostnames = ["evil-safe.com", "notsafe.com", "safe.com.evil.net"]
    for hostname in hostnames {
      var flow = FilterFlow.test(hostname: hostname)
      expect(filter.completedDecision(&flow)).toEqual(.block(.defaultNotAllowed))
    }
  }

  // MARK: - mixed key types in same keychain

  func testMixedKeyTypesAllWorkInSameKeychain() {
    let domainKey = RuleKey(key: .domain(domain: "exact.com", scope: .unrestricted))
    let subdomainKey = RuleKey(key: .anySubdomain(domain: "wild.com", scope: .unrestricted))
    let regexKey = RuleKey(key: .domainRegex(
      pattern: .init("cdn-*.assets.net")!,
      scope: .unrestricted,
    ))
    let ipKey = RuleKey(key: .ipAddress(ipAddress: .init("10.0.0.1")!, scope: .unrestricted))
    let pathKey = RuleKey(key: .path(path: .init("github.com/allowed/*")!, scope: .unrestricted))
    let skeletonKey = RuleKey(key: .skeleton(scope: .bundleId("com.trusted")))
    let keys = [domainKey, subdomainKey, regexKey, ipKey, pathKey, skeletonKey]
    let filter = TestFilter.scenario(userKeychains: [502: [RuleKeychain(keys: keys)]])

    var f1 = FilterFlow.test(hostname: "exact.com")
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(domainKey.id)))

    var f2 = FilterFlow.test(hostname: "deep.sub.wild.com")
    expect(filter.completedDecision(&f2)).toEqual(.allow(.permittedByKey(subdomainKey.id)))

    var f3 = FilterFlow.test(hostname: "cdn-42.assets.net")
    expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(regexKey.id)))

    var f4 = FilterFlow.test(ipAddress: "10.0.0.1")
    expect(filter.completedDecision(&f4)).toEqual(.allow(.permittedByKey(ipKey.id)))

    var f5 = FilterFlow.test(url: "https://github.com/allowed/repo", hostname: "github.com")
    expect(filter.completedDecision(&f5)).toEqual(.allow(.permittedByKey(pathKey.id)))

    var f6 = FilterFlow.test(hostname: "anything.at.all", bundleId: "com.trusted")
    expect(filter.completedDecision(&f6)).toEqual(.allow(.permittedByKey(skeletonKey.id)))

    var blocked = FilterFlow.test(hostname: "unknown.com")
    expect(filter.completedDecision(&blocked)).toEqual(.block(.defaultNotAllowed))
  }

  // MARK: - scope interactions with domain keys

  func testDomainKeyWithBundleIdScopeOnlyMatchesThatApp() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .single(.bundleId("com.chrome"))))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var allowed = FilterFlow.test(hostname: "safe.com", bundleId: "com.chrome")
    expect(filter.completedDecision(&allowed)).toEqual(.allow(.permittedByKey(key.id)))
    var blocked = FilterFlow.test(hostname: "safe.com", bundleId: "com.firefox")
    expect(filter.completedDecision(&blocked)).toEqual(.block(.defaultNotAllowed))
  }

  func testDomainKeyWithWebBrowsersScopeOnlyMatchesBrowsers() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .webBrowsers))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var browserFlow = FilterFlow.test(hostname: "safe.com", bundleId: "com.chrome")
    expect(filter.completedDecision(&browserFlow)).toEqual(.allow(.permittedByKey(key.id)))
    var nonBrowserFlow = FilterFlow.test(hostname: "safe.com", bundleId: "com.xcode")
    expect(filter.completedDecision(&nonBrowserFlow)).toEqual(.block(.defaultNotAllowed))
  }

  func testSameDomainDifferentScopesInSameKeychain() {
    let browserKey = RuleKey(key: .domain(domain: "safe.com", scope: .webBrowsers))
    let appKey = RuleKey(key: .domain(domain: "safe.com", scope: .single(.bundleId("com.slack"))))
    let filter = TestFilter.scenario(userKeychains: [502: [browserKey, appKey].into()])
    var browserFlow = FilterFlow.test(hostname: "safe.com", bundleId: "com.chrome")
    expect(filter.completedDecision(&browserFlow)).toEqual(.allow(.permittedByKey(browserKey.id)))
    var slackFlow = FilterFlow.test(hostname: "safe.com", bundleId: "com.slack")
    expect(filter.completedDecision(&slackFlow)).toEqual(.allow(.permittedByKey(appKey.id)))
    var xcodeFlow = FilterFlow.test(hostname: "safe.com", bundleId: "com.xcode")
    expect(filter.completedDecision(&xcodeFlow)).toEqual(.block(.defaultNotAllowed))
  }

  func testDomainScopeBlockFallsThroughToSubdomainKey() {
    let domainKey = RuleKey(key: .domain(
      domain: "safe.com",
      scope: .single(.bundleId("com.only-this-app")),
    ))
    let subdomainKey = RuleKey(key: .anySubdomain(domain: "safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: [domainKey, subdomainKey].into()])
    var flow = FilterFlow.test(hostname: "safe.com", bundleId: "com.other-app")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(subdomainKey.id)))
  }

  // MARK: - multiple keychains

  func testDomainKeyInLaterKeychainStillMatches() {
    let kc1Key = RuleKey(key: .domain(domain: "one.com", scope: .unrestricted))
    let kc2Key = RuleKey(key: .domain(domain: "two.com", scope: .unrestricted))
    let kc3Key = RuleKey(key: .domain(domain: "three.com", scope: .unrestricted))
    let keychains = [
      RuleKeychain(keys: [kc1Key]),
      RuleKeychain(keys: [kc2Key]),
      RuleKeychain(keys: [kc3Key]),
    ]
    let filter = TestFilter.scenario(userKeychains: [502: keychains])
    var f1 = FilterFlow.test(hostname: "one.com")
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(kc1Key.id)))
    var f2 = FilterFlow.test(hostname: "two.com")
    expect(filter.completedDecision(&f2)).toEqual(.allow(.permittedByKey(kc2Key.id)))
    var f3 = FilterFlow.test(hostname: "three.com")
    expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(kc3Key.id)))
  }

  func testDomainKeyInInactiveKeychainDoesNotMatch() {
    let activeKey = RuleKey(key: .domain(domain: "active.com", scope: .unrestricted))
    let inactiveKey = RuleKey(key: .domain(domain: "inactive.com", scope: .unrestricted))
    let keychains = [
      RuleKeychain(keys: [activeKey]),
      RuleKeychain(
        schedule: .init(mode: .active, days: .all, window: "04:00-05:00"),
        keys: [inactiveKey],
      ),
    ]
    withDependencies {
      $0.date = .init { .day(.friday, at: "12:00") }
    } operation: {
      let filter = TestFilter.scenario(userKeychains: [502: keychains])
      var f1 = FilterFlow.test(hostname: "active.com")
      expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(activeKey.id)))
      var f2 = FilterFlow.test(hostname: "inactive.com")
      expect(filter.completedDecision(&f2)).toEqual(.block(.defaultNotAllowed))
    }
  }

  func testSameDomainInActiveAndInactiveKeychains() {
    let inactiveKey = RuleKey(key: .domain(domain: "shared.com", scope: .unrestricted))
    let activeKey = RuleKey(key: .domain(domain: "shared.com", scope: .unrestricted))
    let keychains = [
      RuleKeychain(
        schedule: .init(mode: .active, days: .all, window: "04:00-05:00"),
        keys: [inactiveKey],
      ),
      RuleKeychain(keys: [activeKey]),
    ]
    withDependencies {
      $0.date = .init { .day(.friday, at: "12:00") }
    } operation: {
      let filter = TestFilter.scenario(userKeychains: [502: keychains])
      var flow = FilterFlow.test(hostname: "shared.com")
      expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(activeKey.id)))
    }
  }

  func testNonDomainKeysInKeychainWithSchedule() {
    let subKey = RuleKey(key: .anySubdomain(domain: "wild.com", scope: .unrestricted))
    let regexKey = RuleKey(key: .domainRegex(pattern: .init("cdn-*.net")!, scope: .unrestricted))
    let keychains = [
      RuleKeychain(
        schedule: .init(mode: .active, days: .all, window: "04:00-05:00"),
        keys: [subKey, regexKey],
      ),
    ]
    let times = LockIsolated<[Date]>([
      .day(.friday, at: "12:00"), // inactive
      .day(.friday, at: "12:00"), // inactive
      .day(.friday, at: "04:30"), // active
      .day(.friday, at: "04:30"), // active
    ])
    withDependencies {
      $0.date = .init { times.withValue { $0.removeFirst() } }
    } operation: {
      let filter = TestFilter.scenario(userKeychains: [502: keychains])
      var f1 = FilterFlow.test(hostname: "sub.wild.com")
      expect(filter.completedDecision(&f1)).toEqual(.block(.defaultNotAllowed))
      var f2 = FilterFlow.test(hostname: "cdn-42.net")
      expect(filter.completedDecision(&f2)).toEqual(.block(.defaultNotAllowed))
      var f3 = FilterFlow.test(hostname: "sub.wild.com")
      expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(subKey.id)))
      var f4 = FilterFlow.test(hostname: "cdn-42.net")
      expect(filter.completedDecision(&f4)).toEqual(.allow(.permittedByKey(regexKey.id)))
    }
  }

  func testEmptyKeychainMixedWithPopulatedKeychain() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let keychains = [
      RuleKeychain(keys: []),
      RuleKeychain(keys: [key]),
      RuleKeychain(keys: []),
    ]
    let filter = TestFilter.scenario(userKeychains: [502: keychains])
    var flow = FilterFlow.test(hostname: "safe.com")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  // MARK: - multiple users

  func testMultipleUsersWithDifferentKeyTypes() {
    let user1Domain = RuleKey(key: .domain(domain: "one.com", scope: .unrestricted))
    let user1Sub = RuleKey(key: .anySubdomain(domain: "wild.com", scope: .unrestricted))
    let user2Domain = RuleKey(key: .domain(domain: "two.com", scope: .unrestricted))
    let user2Regex = RuleKey(key: .domainRegex(pattern: .init("cdn-*.net")!, scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [
      502: [RuleKeychain(keys: [user1Domain, user1Sub])],
      503: [RuleKeychain(keys: [user2Domain, user2Regex])],
    ])

    var f1 = FilterFlow.test(hostname: "one.com", userId: 502)
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(user1Domain.id)))
    var f2 = FilterFlow.test(hostname: "one.com", userId: 503)
    expect(filter.completedDecision(&f2)).toEqual(.block(.defaultNotAllowed))

    var f3 = FilterFlow.test(hostname: "deep.wild.com", userId: 502)
    expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(user1Sub.id)))
    var f4 = FilterFlow.test(hostname: "deep.wild.com", userId: 503)
    expect(filter.completedDecision(&f4)).toEqual(.block(.defaultNotAllowed))

    var f5 = FilterFlow.test(hostname: "two.com", userId: 503)
    expect(filter.completedDecision(&f5)).toEqual(.allow(.permittedByKey(user2Domain.id)))
    var f6 = FilterFlow.test(hostname: "two.com", userId: 502)
    expect(filter.completedDecision(&f6)).toEqual(.block(.defaultNotAllowed))

    var f7 = FilterFlow.test(hostname: "cdn-42.net", userId: 503)
    expect(filter.completedDecision(&f7)).toEqual(.allow(.permittedByKey(user2Regex.id)))
    var f8 = FilterFlow.test(hostname: "cdn-42.net", userId: 502)
    expect(filter.completedDecision(&f8)).toEqual(.block(.defaultNotAllowed))
  }

  // MARK: - hostname case insensitivity

  func testDomainMatchIsCaseInsensitive() {
    let key = RuleKey(key: .domain(domain: "Safe.COM", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    for hostname in ["safe.com", "SAFE.COM", "Safe.Com", "www.SAFE.com"] {
      var flow = FilterFlow.test(hostname: hostname)
      expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
    }
  }

  func testSubdomainMatchIsCaseInsensitive() {
    let key = RuleKey(key: .anySubdomain(domain: "Safe.COM", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    for hostname in ["CDN.SAFE.COM", "cdn.safe.com", "Deep.Sub.Safe.Com"] {
      var flow = FilterFlow.test(hostname: hostname)
      expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
    }
  }

  // MARK: - many keys stress test

  func testCorrectKeyFoundAmongHundredsOfDomainKeys() {
    var keys: [RuleKey] = (0 ..< 300).map { i in
      RuleKey(key: .domain(domain: Key.Domain("site\(i).example.com")!, scope: .unrestricted))
    }
    let targetKey = RuleKey(key: .domain(domain: "target.example.com", scope: .unrestricted))
    keys.append(targetKey)
    keys.append(contentsOf: (300 ..< 500).map { i in
      RuleKey(key: .domain(domain: Key.Domain("site\(i).example.com")!, scope: .unrestricted))
    })
    let keychains = stride(from: 0, to: keys.count, by: 100).map { start in
      let end = min(start + 100, keys.count)
      return RuleKeychain(keys: Array(keys[start ..< end]))
    }
    let filter = TestFilter.scenario(userKeychains: [502: keychains])

    var f1 = FilterFlow.test(hostname: "target.example.com")
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(targetKey.id)))

    var f2 = FilterFlow.test(hostname: "site0.example.com")
    expect(filter.completedDecision(&f2)).toEqual(.allow(.permittedByKey(keys[0].id)))

    var f3 = FilterFlow.test(hostname: "site499.example.com")
    expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(keys[keys.count - 1].id)))

    var f4 = FilterFlow.test(hostname: "notfound.example.com")
    expect(filter.completedDecision(&f4)).toEqual(.block(.defaultNotAllowed))
  }

  func testCorrectKeyFoundAmongMixedKeyTypes() {
    let domainKeys: [RuleKey] = (0 ..< 200).map { i in
      RuleKey(key: .domain(domain: Key.Domain("d\(i).com")!, scope: .unrestricted))
    }
    let subKeys: [RuleKey] = (0 ..< 50).map { i in
      RuleKey(key: .anySubdomain(domain: Key.Domain("s\(i).net")!, scope: .unrestricted))
    }
    let regexKeys: [RuleKey] = (0 ..< 10).map { i in
      RuleKey(key: .domainRegex(
        pattern: Key.DomainRegexPattern("r\(i)-*.org")!,
        scope: .unrestricted,
      ))
    }
    let allKeys = domainKeys + subKeys + regexKeys
    let keychains = [RuleKeychain(keys: allKeys)]
    let filter = TestFilter.scenario(userKeychains: [502: keychains])

    var f1 = FilterFlow.test(hostname: "d199.com")
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(domainKeys[199].id)))

    var f2 = FilterFlow.test(hostname: "deep.sub.s49.net")
    expect(filter.completedDecision(&f2)).toEqual(.allow(.permittedByKey(subKeys[49].id)))

    var f3 = FilterFlow.test(hostname: "r9-anything.org")
    expect(filter.completedDecision(&f3)).toEqual(.allow(.permittedByKey(regexKeys[9].id)))

    var f4 = FilterFlow.test(hostname: "unknown.com")
    expect(filter.completedDecision(&f4)).toEqual(.block(.defaultNotAllowed))
  }

  // MARK: - subdomain edge cases

  func testSubdomainDoesNotMatchPartialSuffix() {
    let key = RuleKey(key: .anySubdomain(domain: "afe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(hostname: "safe.com")
    expect(filter.completedDecision(&flow)).toEqual(.block(.defaultNotAllowed))
  }

  func testSubdomainMatchesDeeplyNestedSubdomains() {
    let key = RuleKey(key: .anySubdomain(domain: "base.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(hostname: "a.b.c.d.e.base.com")
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  // MARK: - nil hostname / IP-only flows with domain keys

  func testDomainKeysDoNotMatchNilHostname() {
    let key = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(ipAddress: "1.2.3.4", hostname: nil)
    expect(filter.completedDecision(&flow)).toEqual(.block(.defaultNotAllowed))
  }

  func testIpKeyMatchesEvenWhenDomainKeysExist() {
    let domainKey = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let ipKey = RuleKey(key: .ipAddress(ipAddress: .init("1.2.3.4")!, scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: [domainKey, ipKey].into()])
    var flow = FilterFlow.test(ipAddress: "1.2.3.4", hostname: nil)
    expect(filter.completedDecision(&flow)).toEqual(.allow(.permittedByKey(ipKey.id)))
  }

  // MARK: - scoped domain keys across keychains

  func testScopedDomainKeyInOneKeychainUnrestrictedInAnother() {
    let restrictedKey = RuleKey(key: .domain(
      domain: "safe.com",
      scope: .single(.bundleId("com.chrome")),
    ))
    let unrestrictedKey = RuleKey(key: .domain(domain: "safe.com", scope: .unrestricted))
    let keychains = [
      RuleKeychain(keys: [restrictedKey]),
      RuleKeychain(keys: [unrestrictedKey]),
    ]
    let filter = TestFilter.scenario(userKeychains: [502: keychains])
    var flow = FilterFlow.test(hostname: "safe.com", bundleId: "com.xcode")
    let decision = filter.completedDecision(&flow)
    expect(decision).toEqual(.allow(.permittedByKey(unrestrictedKey.id)))
  }

  // MARK: - path keys with domain present

  func testPathKeyDoesNotMatchHostnameAlone() {
    let key = RuleKey(key: .path(path: .init("github.com/allowed")!, scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    var flow = FilterFlow.test(url: "https://github.com/disallowed", hostname: "github.com")
    expect(filter.completedDecision(&flow)).toEqual(.block(.defaultNotAllowed))
  }

  func testPathKeyMatchesAlongsideDomainKeys() {
    let domainKey = RuleKey(key: .domain(domain: "example.com", scope: .unrestricted))
    let pathKey = RuleKey(key: .path(path: .init("github.com/ok")!, scope: .unrestricted))
    let filter = TestFilter.scenario(userKeychains: [502: [domainKey, pathKey].into()])
    var f1 = FilterFlow.test(hostname: "example.com")
    expect(filter.completedDecision(&f1)).toEqual(.allow(.permittedByKey(domainKey.id)))
    var f2 = FilterFlow.test(url: "https://github.com/ok", hostname: "github.com")
    expect(filter.completedDecision(&f2)).toEqual(.allow(.permittedByKey(pathKey.id)))
    var f3 = FilterFlow.test(url: "https://github.com/nope", hostname: "github.com")
    expect(filter.completedDecision(&f3)).toEqual(.block(.defaultNotAllowed))
  }
}

extension FilterDecision.FromFlow {
  var isAllow: Bool {
    switch self {
    case .allow: true
    case .block: false
    }
  }
}
