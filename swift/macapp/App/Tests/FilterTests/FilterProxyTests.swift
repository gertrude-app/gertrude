import ConcurrencyExtras
import Core
import Dependencies
import NetworkExtension
import TestSupport
import XCTest
import XExpect

@testable import Filter

final class FilterProxyTests: XCTestCase {
  func testEarlyDecisionBlockBecomesDropWithNoLog() {
    let proxy = FilterProxy(earlyDecision: .block(.missingUserId))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    // this is current behavior, but i'm not certain we don't want to log here
    // as i'm not sure if this ever happens in practice
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // <-- not logged
  }

  func testEarlyDecisionAllowBecomesAllowWithNoLog() {
    let proxy = FilterProxy(earlyDecision: .allow(.systemUser(501)))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // current behavior
  }

  func testUrlMessagePassedToStore() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.reference)
    } operation: {
      let proxy = FilterProxy(flowDecision: .block(.urlMessage(.alive(501))))
      let verdict = proxy.handleNewFlow(.mock)
      // 1) flow is dropped (it was just an xpc message)
      expect(verdict.isDrop).toBeTrue()
      // 2) the store received the message
      expect(proxy.store.state.macappsAliveUntil).toEqual([501: .reference + .seconds(150)])
    }
  }

  func testEarlyDecisionAllowingGertrudeDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.gertrude)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:])
  }

  func testEarlyDecisionAllowingSystemUIServerInternalDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.init(description: """
      sourceAppIdentifier = .com.apple.systemuiserver
      remoteEndpoint = 192.168.0.1:8080
    """))
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual([:])
  }

  func testEarlyDecisionBlockingDuringDowntime() {
    let proxy = FilterProxy(earlyDecision: .blockDuringDowntime(501))
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.store.state.logs.bundleIds).toEqual([:]) // current behavior
  }

  func testBlockedNewFlowWithoutPeekingBytesDropsAndLogs() {
    let proxy = FilterProxy(
      earlyDecision: .none(501),
      flowDecision: .block(.defaultNotAllowed),
    )
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  @MainActor
  func testBlockedNewFlowSendsDecisionIfSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(
        earlyDecision: .none(501),
        flowDecision: .block(.defaultNotAllowed),
      ) {
        $0.blockListeners[501] = .distantFuture
      }
      proxy.sendingBlockDecisions = true // <-- sending decisions
      let verdict = proxy.handleNewFlow(.mock)
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual(["com.acme.app"])
    }
  }

  @MainActor
  func testAlwaysBlockedNewFlowDoesNotSendDecisionEvenWhenSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(
        earlyDecision: .none(501),
        flowDecision: .block(.alwaysBlocked(.targetContains(value: "giphy.com"))),
      ) {
        $0.blockListeners[501] = .distantFuture
      }
      proxy.sendingBlockDecisions = true
      let verdict = proxy.handleNewFlow(.mock)
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual([]) // <-- always-blocked hits are not surfaced
    }
  }

  func testAllowedNewFlowWithoutPeekingBytesAllowsAndLogs() {
    let proxy = FilterProxy(
      earlyDecision: .none(501),
      flowDecision: .allow(.permittedByKey(.init())),
    )
    let verdict = proxy.handleNewFlow(.mock)
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  func testApiReqFromGertrudeAppAllowedAndSetsAlive() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
    } operation: {
      let proxy = FilterProxy(
        earlyDecision: .none(501), // <-- we know the user id is 501
        flowDecision: .allow(.fromGertrudeApp), // <-- so count any api req as an alive
      )
      let verdict = proxy.handleNewFlow(.mock)
      expect(verdict.isDrop).toBeFalse()
      expect(proxy.store.state.macappsAliveUntil).toEqual([501: .reference + .seconds(150)])
    }
  }

  func testDeferredNewFlowLogsAndSetsUserId() {
    let proxy = FilterProxy(flowDecision: .some(.none))
    let flow = NEFilterFlow.DTO.mock
    let verdict = proxy.handleNewFlow(flow)
    expect(verdict.isExamineBytes).toBeTrue()
    expect(proxy.deferredOutboundFlows[flow.identifier]?.userId).toEqual(501)
    expect(proxy.store.state.logs.bundleIds).toEqual(["com.acme.app": 1])
  }

  func testOutboundFlowDecisionBlock() {
    let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed))
    let flow = NEFilterFlow.DTO.mock
    proxy.deferredOutboundFlows[flow.identifier] = .init(
      userId: 501,
      round: 0,
      accumulatedReadBytes: .init(),
    )

    let verdict = proxy.handleOutboundData(from: flow, readBytesStartOffset: 0, readBytes: .init())
    expect(verdict.isDrop).toBeTrue()
    expect(proxy.deferredOutboundFlows).toEqual([:]) // removes the flow
  }

  func testOutboundFlowDecisionAllow() {
    let proxy = FilterProxy(flowDecision: .allow(.permittedByKey(.init())))
    let flow = NEFilterFlow.DTO.mock
    proxy.deferredOutboundFlows[flow.identifier] = .init(
      userId: 501,
      round: 0,
      accumulatedReadBytes: .init(),
    )

    let verdict = proxy.handleOutboundData(from: flow, readBytesStartOffset: 0, readBytes: .init())
    expect(verdict.isDrop).toBeFalse()
    expect(proxy.deferredOutboundFlows).toEqual([:]) // removes the flow
  }

  func testOutboundFlowRequestsSingleRetryWhenParserNeedsMoreBytes() {
    let proxy = FilterProxy(flowDecision: .some(.none))
    let flow = NEFilterFlow.DTO.mock
    let data = makeTLSClientHello(serverName: "www.google.com")
    let prefixLength = 20
    proxy.deferredOutboundFlows[flow.identifier] = .init(
      userId: 501,
      round: 0,
      accumulatedReadBytes: .init(),
    )

    let verdict = proxy.handleOutboundData(
      from: flow,
      readBytesStartOffset: 0,
      readBytes: Data(data.prefix(prefixLength)),
    )

    expect(verdict.isInspectMoreData).toBeTrue()
    expect(verdict.passBytes).toEqual(prefixLength)
    expect(verdict.peekBytes).toEqual(data.count - prefixLength)
    expect(proxy.deferredOutboundFlows[flow.identifier]?.round).toEqual(1)
    expect(proxy.deferredOutboundFlows[flow.identifier]?.accumulatedReadBytes)
      .toEqual(Data(data.prefix(prefixLength)))
  }

  func testOutboundFlowCompletesAfterRetryUsingAccumulatedBytes() {
    let proxy = FilterProxy(flowDecision: .some(.none))
    let flow = NEFilterFlow.DTO.mock
    let data = makeTLSClientHello(serverName: "www.google.com")
    let prefixLength = 20
    proxy.deferredOutboundFlows[flow.identifier] = .init(
      userId: 501,
      round: 1,
      accumulatedReadBytes: Data(data.prefix(prefixLength)),
    )

    let verdict = proxy.handleOutboundData(
      from: flow,
      readBytesStartOffset: prefixLength,
      readBytes: Data(data.dropFirst(prefixLength)),
    )

    expect(verdict.isDrop).toBeTrue()
    expect(proxy.deferredOutboundFlows).toEqual([:])
  }

  func testOutboundFlowStillNeedingMoreBytesAfterRetryFallsThroughToDecision() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed))
      let flow = NEFilterFlow.DTO.mock
      let data = makeTLSClientHello(serverName: "www.google.com")
      let prefixLength = 20
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 1,
        accumulatedReadBytes: Data(data.prefix(prefixLength)),
      )

      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: prefixLength,
        readBytes: Data(data.dropFirst(prefixLength).prefix(1)),
      )

      expect(verdict.isDrop).toBeTrue()
      expect(verdict.isInspectMoreData).toBeFalse()
      expect(proxy.deferredOutboundFlows[flow.identifier]).toBeNil()
      expect(proxy.store.state.logs.events[.init(id: "outboundRetryStillInsufficient")]).toEqual(1)
    }
  }

  func testOutboundFlowAtCapacityPreservesOtherDeferredRetries() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .allow(.permittedByKey(.init())))
      let preservedId = UUID()
      let preservedData = Data([0x16, 0x03, 0x01])
      proxy.deferredOutboundFlows[preservedId] = .init(
        userId: 501,
        round: 1,
        accumulatedReadBytes: preservedData,
      )
      for _ in 0 ..< 99 {
        proxy.deferredOutboundFlows[UUID()] = .init(
          userId: 501,
          round: 1,
          accumulatedReadBytes: Data(),
        )
      }

      let flow = NEFilterFlow.DTO.mock
      let data = makeTLSClientHello(serverName: "www.google.com")
      let prefixLength = 20

      _ = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: Data(data.prefix(prefixLength)),
      )

      expect(proxy.deferredOutboundFlows.count).toEqual(100)
      expect(proxy.deferredOutboundFlows[preservedId]?.round).toEqual(1)
      expect(proxy.deferredOutboundFlows[preservedId]?.accumulatedReadBytes).toEqual(preservedData)
      expect(proxy.deferredOutboundFlows[flow.identifier]).toBeNil()
      expect(proxy.store.state.logs.events[.init(id: "outboundRetryCapacityExhausted")]).toEqual(1)
    }
  }

  func testLogsOutboundBytesGapDetection() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed))
      let flow = NEFilterFlow.DTO.mock
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 1,
        accumulatedReadBytes: Data([0x16, 0x03, 0x01]),
      )

      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 5,
        readBytes: Data([0x00]),
      )

      expect(verdict.isDrop).toBeTrue()
      expect(proxy.store.state.logs.events[.init(id: "outboundBytesGapDetected")]).toEqual(1)
    }
  }

  func testLogsRetryClampToMax() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .some(.none))
      let flow = NEFilterFlow.DTO.mock
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 0,
        accumulatedReadBytes: .init(),
      )

      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: Data([0x16, 0x03, 0x01, 0xFF, 0xFF]),
      )

      expect(verdict.isInspectMoreData).toBeTrue()
      expect(proxy.store.state.logs.events[.init(id: "outboundRetryClampedToMax")]).toEqual(1)
    }
  }

  func testLogsEncryptedClientHelloSampledX100() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .allow(.permittedByKey(.init())))
      proxy.encryptedClientHelloSamplingCounter = FilterProxy.encryptedClientHelloSampleRate - 1
      let flow = NEFilterFlow.DTO.mock
      let data = makeTLSClientHello(
        serverName: "www.google.com",
        extraExtensions: [(type: 0xFE0D, payload: Data([0x01]))],
      )
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 1,
        accumulatedReadBytes: .init(),
      )

      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: data,
      )

      expect(verdict.isDrop).toBeFalse()
      expect(proxy.store.state.logs.events[.init(
        id: "sawEncryptedClientHello_x100",
        detail: "bundleId=com.acme.app outerSNI=www.google.com",
      )]).toEqual(1)
    }
  }

  func testLogsEncryptedClientHelloSampledX100WithoutOuterSNI() {
    withDependencies {
      $0.filterExtension.version = { "2.6.0" }
    } operation: {
      let proxy = FilterProxy(flowDecision: .allow(.permittedByKey(.init())))
      proxy.encryptedClientHelloSamplingCounter = FilterProxy.encryptedClientHelloSampleRate - 1
      let flow = NEFilterFlow.DTO.mock
      let data = makeTLSClientHello(
        serverName: nil,
        extraExtensions: [(type: 0xFE0D, payload: Data([0x01]))],
      )
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 1,
        accumulatedReadBytes: .init(),
      )

      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: data,
      )

      expect(verdict.isDrop).toBeFalse()
      expect(proxy.store.state.logs.events[.init(
        id: "sawEncryptedClientHello_x100",
        detail: "bundleId=com.acme.app outerSNI=nil",
      )]).toEqual(1)
    }
  }

  @MainActor
  func testBlockedDataFlowSendsDecisionIfSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(flowDecision: .block(.defaultNotAllowed)) {
        $0.blockListeners[501] = .distantFuture
      }
      let flow = NEFilterFlow.DTO.mock
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 0,
        accumulatedReadBytes: .init(),
      )
      proxy.sendingBlockDecisions = true // <-- sending decisions
      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: .init(),
      )
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual(["com.acme.app"])
    }
  }

  @MainActor
  func testAlwaysBlockedDataFlowDoesNotSendDecisionEvenWhenSending() async {
    let sent = LockIsolated<[String]>([])
    await withDependencies {
      $0.filterExtension.version = { "2.6.0" }
      $0.date = .constant(.init(timeIntervalSinceReferenceDate: 0))
      $0.uuid = .incrementing
      $0.xpc.sendBlockedRequest = { _, req in
        sent.withValue { $0.append(req.app.bundleId) }
      }
    } operation: {
      let proxy = FilterProxy(
        flowDecision: .block(.alwaysBlocked(.targetContains(value: "giphy.com"))),
      ) {
        $0.blockListeners[501] = .distantFuture
      }
      let flow = NEFilterFlow.DTO.mock
      proxy.deferredOutboundFlows[flow.identifier] = .init(
        userId: 501,
        round: 0,
        accumulatedReadBytes: .init(),
      )
      proxy.sendingBlockDecisions = true
      let verdict = proxy.handleOutboundData(
        from: flow,
        readBytesStartOffset: 0,
        readBytes: .init(),
      )
      expect(verdict.isDrop).toBeTrue()
      await Task.megaYield()
      expect(sent.value).toEqual([]) // <-- always-blocked hits are not surfaced
    }
  }
}

// helpers

extension NEFilterFlow.DTO {
  static var mock: Self {
    .init(description: "sourceAppIdentifier = com.acme.app")
  }

  static var gertrude: Self {
    .init(description: "sourceAppIdentifier = com.netrivet.gertrude.app")
  }
}

extension FilterProxy {
  convenience init(
    earlyDecision: FilterDecision.FromUserId = .none(501),
    flowDecision: FilterDecision.FromFlow?? = .some(.some(.block(.defaultNotAllowed))),
    config: (inout Filter.State) -> Void = { _ in },
  ) {
    var state = Filter.State()
    config(&state)
    self.init(store: .init(initialState: state))
    self.store.__TEST_MOCK_EARLY_DECISION = earlyDecision
    self.store.__TEST_MOCK_FLOW_DECISION = flowDecision
  }
}

extension NEFilterDataVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }

  var isInspectMoreData: Bool {
    !self.isDrop && self.description.contains("peekBytes")
  }

  var passBytes: Int? {
    self.intValue(for: "passBytes = ")
  }

  var peekBytes: Int? {
    self.intValue(for: "peekBytes = ")
  }

  private func intValue(for prefix: String) -> Int? {
    guard let range = self.description.range(of: prefix) else {
      return nil
    }
    let suffix = self.description[range.upperBound...]
    let digits = suffix.prefix { $0.isNumber }
    guard !digits.isEmpty else {
      return nil
    }
    return Int(digits)
  }
}

extension NEFilterNewFlowVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }

  var isExamineBytes: Bool {
    !self.isDrop && self.description.contains("filterOutbound = YES")
  }
}

private func makeTLSClientHello(
  serverName: String?,
  extraExtensions: [(type: UInt16, payload: Data)] = [],
) -> Data {
  var clientHello = Data()
  clientHello.append(contentsOf: [0x03, 0x03])
  clientHello.append(Data(repeating: 0x11, count: 32))
  clientHello.append(0x00)
  clientHello.append(contentsOf: [0x00, 0x02])
  clientHello.append(contentsOf: [0x13, 0x01])
  clientHello.append(0x01)
  clientHello.append(0x00)

  var extensions = Data()
  if let serverName {
    let hostname = Data(serverName.utf8)
    var serverNameExtension = Data()
    let listLength = UInt16(1 + 2 + hostname.count)
    serverNameExtension.append(uint16Bytes(listLength))
    serverNameExtension.append(0x00)
    serverNameExtension.append(uint16Bytes(UInt16(hostname.count)))
    serverNameExtension.append(hostname)

    extensions.append(uint16Bytes(0x0000))
    extensions.append(uint16Bytes(UInt16(serverNameExtension.count)))
    extensions.append(serverNameExtension)
  }
  for extraExtension in extraExtensions {
    extensions.append(uint16Bytes(extraExtension.type))
    extensions.append(uint16Bytes(UInt16(extraExtension.payload.count)))
    extensions.append(extraExtension.payload)
  }

  clientHello.append(uint16Bytes(UInt16(extensions.count)))
  clientHello.append(extensions)

  var handshake = Data([0x01])
  handshake.append(uint24Bytes(clientHello.count))
  handshake.append(clientHello)

  var record = Data([0x16, 0x03, 0x01])
  record.append(uint16Bytes(UInt16(handshake.count)))
  record.append(handshake)
  return record
}

private func uint16Bytes(_ value: UInt16) -> Data {
  Data([UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
}

private func uint24Bytes(_ value: Int) -> Data {
  Data([
    UInt8((value >> 16) & 0xFF),
    UInt8((value >> 8) & 0xFF),
    UInt8(value & 0xFF),
  ])
}
