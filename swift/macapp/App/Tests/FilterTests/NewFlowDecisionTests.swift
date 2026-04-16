import Core
import Gertie
import XCTest
import XExpect

@testable import Filter

final class NewFlowDecisionTests: XCTestCase {
  // the blocking of these requests caused the SystemUIServer daemon to repeatedly crash
  // causing the menu bar to hide/delete/flash, do crazy stuff every few seconds
  func testSystemUiServerAllowedToTalkToPrivateIps() throws {
    let privateIps = [
      "10.0.1.1",
      "192.168.3.5",
      "100.64.3.3",
      "192.0.0.3",
      "172.16.0.0",
      "172.28.111.111",
      "172.31.255.255",
    ]
    for ip in privateIps {
      let flow = FilterFlow(ipAddress: ip, bundleId: ".com.apple.systemuiserver")
      expect(TestFilter().newFlowDecision(flow)).toEqual(.allow(.systemUiServerInternal))
    }
  }

  func testDecisionIsNilWhenNoKeyAllowsAndUrlIsMissing() {
    let flow = FilterFlow.test(url: nil, hostname: "unknown.com", bundleId: "com.foo.bar")
    expect(TestFilter.scenario().newFlowDecision(flow)).toBeNil()
  }

  func testAwolMacappBlocked() {
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: "abc123.com", bundleId: "com.foo")
    let key = RuleKey(key: .skeleton(scope: .bundleId("com.foo")))
    let filter = TestFilter.scenario(
      userKeychains: [502: key.into()], // <-- we would normally permit by this key...
      macappsAliveUntil: [:], // <-- but the macapp is awol
    )
    expect(filter.newFlowDecision(flow)).toEqual(.block(.macappAWOL(502)))
  }

  func testDecisionIsBlockWhenNoKeyAllowsAndUrlIsPresent() {
    let flow = FilterFlow.test(
      url: "https://unknown.com/foo",
      hostname: "unknown.com",
      bundleId: "com.foo.bar",
    )
    expect(TestFilter.scenario().newFlowDecision(flow)).toEqual(.block(.defaultNotAllowed))
  }

  func testFilteringDisabledUserBlockedWhenMacappAWOL() {
    let flow = FilterFlow.test(hostname: "example.com")
    let filter = TestFilter.scenario(
      userKeychains: [:],
      macappsAliveUntil: [:],
      filteringDisabledUsers: [502],
    )
    expect(filter.newFlowDecision(flow)).toEqual(.block(.macappAWOL(502)))
  }

  func testFilterSuspensionAllowNotGrantedIfMacappAppearsAWOL() {
    let flow = FilterFlow.test(url: nil, hostname: "unknown.com")
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      macappsAliveUntil: [:], // <-- macapp is awol!
      suspensions: [502: .init(scope: .unrestricted, duration: 100)],
    )
    expect(filter.newFlowDecision(flow)).toEqual(.block(.macappAWOL(502)))
  }

  func testFlowAllowedForAppWithUnrestrictedScope() {
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: "abc123.com", bundleId: "com.foo")
    let key = RuleKey(key: .skeleton(scope: .bundleId("com.foo")))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testUdpFlowAllowedForAppWithUnrestrictedScope() {
    let flow = FilterFlow.test(
      ipAddress: "4.4.4.4",
      hostname: "abc123.com",
      bundleId: "com.foo",
      port: .other(333),
      ipProtocol: .udp(Int32(IPPROTO_UDP)),
    )
    let key = RuleKey(key: .skeleton(scope: .bundleId("com.foo")))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testAllKeysChecked() {
    let key1 = RuleKey(key: .skeleton(scope: .bundleId("com.foo")))
    let key2 = RuleKey(key: .domain(domain: "bar.com", scope: .webBrowsers))
    let filter = TestFilter.scenario(userKeychains: [502: [key1, key2].into()])
    expect(filter.newFlowDecision(.test(hostname: "bar.com")))
      .toEqual(.allow(.permittedByKey(key2.id)))
  }

  func testFlowAllowedForAppWithUnrestrictedScopeNoHostname() {
    let key = RuleKey(key: .skeleton(scope: .identifiedAppSlug("chrome")))
    let filter = TestFilter.scenario(userKeychains: [502: key.into()])
    let flow = FilterFlow.test(ipAddress: "4.4.4.4", hostname: nil)
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.permittedByKey(key.id)))
  }

  func testDnsUdpRequestsAlwaysAllowed() {
    let flow = FilterFlow(port: .dns(53), ipProtocol: .udp(Int32(IPPROTO_UDP)))
    let filter = TestFilter.scenario()
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.dnsRequest))
  }

  func testFlowRejectedWhenNoKeys() {
    let filter = TestFilter.scenario(userKeychains: [:])
    expect(filter.newFlowDecision(.test())).toEqual(.block(.noUserKeys))
  }

  func testDoesNotBlockOwnRequests() {
    let cases: [(
      ip: String?,
      hostname: String?,
      url: String?,
      bundleId: String,
      decision: FilterDecision.FromFlow?,
    )] =
      [
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp),
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp),
        ),
        (
          ip: "1.2.3.4",
          hostname: "foo.com",
          url: "https://foo.com/bar",
          bundleId: "WFN83LM943.com.netrivet.gertrude.app",
          decision: .allow(.fromGertrudeApp),
        ),
        (
          ip: nil,
          hostname: nil,
          url: nil,
          bundleId: "gertrude.app.imposter",
          decision: nil,
        ),
      ]
    for (ip, hostname, url, bundleId, decision) in cases {
      let filter = TestFilter.scenario()
      let flow = FilterFlow.test(url: url, ipAddress: ip, hostname: hostname, bundleId: bundleId)
      expect(filter.newFlowDecision(flow)).toEqual(decision)
    }
  }

  func testOwnRequestStillAllowedWhenKeychainsMissing() {
    let filter = TestFilter.scenario(userKeychains: [:])
    expect(filter.newFlowDecision(.test(bundleId: "com.netrivet.gertrude.app")))
      .toEqual(.allow(.fromGertrudeApp))
  }

  // MARK: Always Blocked flow-stage tests

  func testAlwaysBlockedRuleBeatsAllowKey() {
    let key = RuleKey(key: .domain(domain: "evil.com", scope: .unrestricted))
    let filter = TestFilter.scenario(
      userKeychains: [502: key.into()],
      userAlwaysBlocked: [502: [.hostnameContains(value: "evil")]],
    )
    let flow = FilterFlow.test(hostname: "evil.com")
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.alwaysBlocked(.hostnameContains(value: "evil"))))
  }

  func testAlwaysBlockedRuleBlocksDuringFilterSuspension() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(hostname: "evil.com")
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.alwaysBlocked(.hostnameEndsWith(value: "evil.com"))))
  }

  func testAlwaysBlockedRuleBlocksForFilteringDisabledUser() {
    let filter = TestFilter.scenario(
      userKeychains: [:],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      filteringDisabledUsers: [502],
    )
    let flow = FilterFlow.test(hostname: "evil.com")
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.alwaysBlocked(.hostnameEndsWith(value: "evil.com"))))
  }

  func testFilteringDisabledUserAllowedWhenAlwaysBlockedDoesNotMatch() {
    let filter = TestFilter.scenario(
      userKeychains: [:],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      filteringDisabledUsers: [502],
    )
    let flow = FilterFlow.test(hostname: "example.com")
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.filteringDisabled(502)))
  }

  func testFilterSuspendedUserAllowedWhenAlwaysBlockedDoesNotMatch() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(hostname: "example.com")
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.filterSuspended))
  }

  func testAlwaysBlockedEvaluatedBeforeKeychainAllow() {
    // same keychain would allow, but AB blocks first
    let key = RuleKey(key: .skeleton(scope: .bundleId("com.evil.app")))
    let filter = TestFilter.scenario(
      userKeychains: [502: key.into()],
      userAlwaysBlocked: [502: [.bundleIdContains(value: "com.evil")]],
    )
    let flow = FilterFlow.test(hostname: "anything.com", bundleId: "com.evil.app")
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.alwaysBlocked(.bundleIdContains(value: "com.evil"))))
  }

  func testAwolMacappBlockedWhenOnlyAlwaysBlockedAssigned() {
    // AWOL blocking should fire even when the user has *only* always-blocked rules
    // (no keychains, not filtering-disabled)
    let filter = TestFilter.scenario(
      userKeychains: [:],
      userAlwaysBlocked: [502: [.hostnameContains(value: "evil")]],
      macappsAliveUntil: [:],
    )
    let flow = FilterFlow.test(hostname: "example.com")
    expect(filter.newFlowDecision(flow)).toEqual(.block(.macappAWOL(502)))
  }

  func testAlwaysBlockedForOtherUserDoesNotAffectThisUser() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [503: [.hostnameContains(value: "evil")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(hostname: "evil.com")
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.filterSuspended))
  }

  // regression: Chrome flows arrive at new-flow time with nil hostname (SNI
  // isn't parsed until peek). if a suspended user has AB rules, we must defer
  // rather than early-allow, so the peek round-trip gets a chance to match.
  func testSuspendedChromeFlowDefersWhenAlwaysBlockedNeedsHostname() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(hostname: nil, bundleId: "com.google.Chrome")
    expect(filter.newFlowDecision(flow)).toBeNil()
  }

  func testFilteringDisabledChromeFlowDefersWhenAlwaysBlockedNeedsHostname() {
    let filter = TestFilter.scenario(
      userKeychains: [:],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      filteringDisabledUsers: [502],
    )
    let flow = FilterFlow.test(hostname: nil, bundleId: "com.google.Chrome")
    expect(filter.newFlowDecision(flow)).toBeNil()
  }

  // after peek populates hostname via SNI, the completed-flow path must block.
  func testSuspendedChromeFlowBlockedByAlwaysBlockedAfterSniParsed() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    var flow = FilterFlow.test(hostname: "api.evil.com", bundleId: "com.google.Chrome")
    expect(filter.completedDecision(&flow))
      .toEqual(.block(.alwaysBlocked(.hostnameEndsWith(value: "evil.com"))))
  }

  // QUIC ClientHello is encrypted, so SNI can't be parsed. when a user with
  // AB rules would otherwise fall through to a blind allow, block QUIC so
  // the client retries over TCP+TLS and SNI becomes visible.
  func testSuspendedQuicFlowBlockedWhenAlwaysBlockedNeedsHostname() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(
      hostname: nil,
      bundleId: "com.google.Chrome",
      port: .https(443),
      ipProtocol: .udp(Int32(IPPROTO_UDP)),
    )
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.quicBlockedForAlwaysBlocked(502)))
  }

  func testFilteringDisabledQuicFlowBlockedWhenAlwaysBlockedNeedsHostname() {
    let filter = TestFilter.scenario(
      userKeychains: [:],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      filteringDisabledUsers: [502],
    )
    let flow = FilterFlow.test(
      hostname: nil,
      bundleId: "com.google.Chrome",
      port: .https(443),
      ipProtocol: .udp(Int32(IPPROTO_UDP)),
    )
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.quicBlockedForAlwaysBlocked(502)))
  }

  // QUIC block only fires when the user has AB rules — no rules, no block.
  func testSuspendedQuicFlowAllowedWhenNoAlwaysBlockedRules() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(
      hostname: nil,
      bundleId: "com.google.Chrome",
      port: .https(443),
      ipProtocol: .udp(Int32(IPPROTO_UDP)),
    )
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.filterSuspended))
  }

  // QUIC with hostname already present (rare, but possible) should run the
  // AB rule check normally rather than force a downgrade.
  func testSuspendedQuicFlowWithHostnameDoesNotForceDowngrade() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.hostnameEndsWith(value: "evil.com")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(
      hostname: "example.com",
      bundleId: "com.google.Chrome",
      port: .https(443),
      ipProtocol: .udp(Int32(IPPROTO_UDP)),
    )
    expect(filter.newFlowDecision(flow)).toEqual(.allow(.filterSuspended))
  }

  // AB rules that don't need hostname (e.g. bundleIdContains) must still
  // resolve at new-flow time — no deferral, no extra peek round-trip.
  func testSuspendedFlowWithBundleIdAlwaysBlockedRuleResolvesAtNewFlow() {
    let filter = TestFilter.scenario(
      userKeychains: [502: [.mock]],
      userAlwaysBlocked: [502: [.bundleIdContains(value: "com.apple.Spotlight")]],
      suspensions: [502: .init(scope: .unrestricted, duration: 1000)],
    )
    let flow = FilterFlow.test(hostname: nil, bundleId: "com.apple.Spotlight")
    expect(filter.newFlowDecision(flow))
      .toEqual(.block(.alwaysBlocked(.bundleIdContains(value: "com.apple.Spotlight"))))
  }
}

// helpers

extension RuleKey {
  func into() -> [RuleKeychain] {
    [RuleKeychain(keys: [self])]
  }
}

extension [RuleKey] {
  func into() -> [RuleKeychain] {
    [RuleKeychain(keys: self)]
  }
}

extension FilterFlow {
  static func test(
    url: String? = nil,
    ipAddress: String? = nil,
    hostname: String? = nil,
    bundleId: String? = "com.chrome",
    remoteEndpoint: String? = nil,
    userId: uid_t? = 502,
    port: Core.Port? = nil,
    ipProtocol: IpProtocol? = nil,
    flowType: FlowType? = nil,
  ) -> Self {
    FilterFlow(
      url: url,
      ipAddress: ipAddress,
      hostname: hostname,
      bundleId: bundleId,
      remoteEndpoint: remoteEndpoint,
      userId: userId,
      port: port,
      ipProtocol: ipProtocol,
      flowType: flowType,
    )
  }
}
