import BlockerRoute
import ComposableArchitecture
import Testing

@testable import LibApp
@testable import LibClients

@MainActor
@Test func generatesCodeThenConnectsOnPoll() async throws {
  let clock = TestClock()
  let childData = ChildIOSDeviceData_v2(
    childId: UUID(1),
    token: UUID(2),
    deviceId: UUID(3),
    childName: "Franny",
    supervised: nil,
  )

  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.continuousClock = clock
    $0.api.createBlockerClaimCode = { .init(code: 123_456, expiresAt: .reference) }
    $0.api.checkBlockerConnectionStatus = { @Sendable code in
      #expect(code == 123_456) // polls with the just-generated code
      return .connected(childData)
    }
  }

  await store.send(.onAppear) // already .generatingCode, no state change
  await store.receive(.codeResponse(code: 123_456)) {
    $0.screen = .showingCode(code: 123_456)
  }
  await clock.advance(by: .seconds(5)) // first poll tick
  await store.receive(.polled(.connected(childData)))
  await store.receive(.connectionSucceeded(childData: childData))
}

@MainActor
@Test func pendingPollThenConnects() async throws {
  let clock = TestClock()
  let pollCount = LockIsolated(0)
  let childData = ChildIOSDeviceData_v2(
    childId: UUID(1),
    token: UUID(2),
    deviceId: UUID(3),
    childName: "Bob",
    supervised: nil,
  )

  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.continuousClock = clock
    $0.api.createBlockerClaimCode = { .init(code: 555_111, expiresAt: .reference) }
    $0.api.checkBlockerConnectionStatus = { @Sendable _ in
      pollCount.withValue { $0 += 1 }
      return pollCount.value == 1 ? .pending : .connected(childData)
    }
  }

  await store.send(.onAppear)
  await store.receive(.codeResponse(code: 555_111)) {
    $0.screen = .showingCode(code: 555_111)
  }
  await clock.advance(by: .seconds(5))
  await store.receive(.polled(.pending)) // still waiting, no state change
  await clock.advance(by: .seconds(5))
  await store.receive(.polled(.connected(childData)))
  await store.receive(.connectionSucceeded(childData: childData))
}

@MainActor
@Test func reappearWhileShowingCodeDoesNotRestart() async throws {
  let clock = TestClock()
  let pollCount = LockIsolated(0)
  let childData = ChildIOSDeviceData_v2(
    childId: UUID(1),
    token: UUID(2),
    deviceId: UUID(3),
    childName: "Roo",
    supervised: nil,
  )

  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.continuousClock = clock
    $0.api.createBlockerClaimCode = { .init(code: 123_456, expiresAt: .reference) }
    $0.api.checkBlockerConnectionStatus = { @Sendable _ in
      pollCount.withValue { $0 += 1 }
      return pollCount.value == 1 ? .pending : .connected(childData)
    }
  }

  await store.send(.onAppear)
  await store.receive(.codeResponse(code: 123_456)) {
    $0.screen = .showingCode(code: 123_456)
  }
  await clock.advance(by: .seconds(5))
  await store.receive(.polled(.pending))
  await store.send(.onAppear) // re-appear while showing code: no-op, no fresh code
  await clock.advance(by: .seconds(5))
  await store.receive(.polled(.connected(childData)))
  await store.receive(.connectionSucceeded(childData: childData))
}

@MainActor
@Test func terminalPollFailureShowsRetryScreen() async throws {
  let clock = TestClock()

  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.continuousClock = clock
    $0.api.createBlockerClaimCode = { .init(code: 123_456, expiresAt: .reference) }
    $0.api.checkBlockerConnectionStatus = { @Sendable _ in .expired }
  }

  await store.send(.onAppear)
  await store.receive(.codeResponse(code: 123_456)) {
    $0.screen = .showingCode(code: 123_456)
  }
  await clock.advance(by: .seconds(5)) // poll tick returns a terminal failure
  await store.receive(.polled(.expired)) {
    $0.screen = .codeGenerationFailed // cancels poll, offers regenerate
  }
}

@MainActor
@Test func codeGenerationFailureShowsRetryScreen() async throws {
  let store = TestStore(initialState: ConnectAccount.State()) {
    ConnectAccount()
  } withDependencies: {
    $0.api.createBlockerClaimCode = { @Sendable in
      struct TestError: Error {}
      throw TestError()
    }
  }

  await store.send(.onAppear)
  await store.receive(.codeGenerationFailed) {
    $0.screen = .codeGenerationFailed
  }
}
