import BlockerRoute

extension IOSReducer.Deps {
  enum LaunchState {
    enum Running {
      case unconnected
      case connected(ChildIOSDeviceData_v2)
    }

    enum SupervisionReboot {
      case codeNotClaimed(code: Int)
      case codeExpired
      case codeNotFound
      case requiresSubscription(ChildIOSDeviceData_v2)
      case codeClaimedNotSupervised(ChildIOSDeviceData_v2)
      case supervisedButNeedsProfile(ChildIOSDeviceData_v2)
      // anomaly: api says "fully supervised", but filter is not running
      case serverClientDisagreement(ChildIOSDeviceData_v2)
      case networkError
    }

    case running(Running)
    case onboardingNeeded
    case filterNoLongerRunning
    case profileRemovedRecovery(ChildIOSDeviceData_v2)
    case gertrudeSupervisionReboot(SupervisionReboot)
    case configuratorSupervisionFirstLaunch
  }

  func launchState() async -> LaunchState {
    let filterRunning = await self.systemExtension.filterRunning()
    let supervisionData = self.sharedStorage.loadPendingSupervisionCode()

    if !filterRunning, let code = supervisionData?.code {
      for attempt in 0 ..< 4 {
        if attempt > 0 {
          try? await self.clock.sleep(for: .seconds(2))
        }
        guard let status = try? await self.api.checkSupervisionFlowStatus(code) else {
          continue
        }
        switch status {
        case .pending:
          return .gertrudeSupervisionReboot(.codeNotClaimed(code: code))
        case .expired:
          return .gertrudeSupervisionReboot(.codeExpired)
        case .notFound:
          return .gertrudeSupervisionReboot(.codeNotFound)
        case .requiresSubscription(let conn):
          return .gertrudeSupervisionReboot(.requiresSubscription(conn))
        case .claimed(let conn):
          return .gertrudeSupervisionReboot(.codeClaimedNotSupervised(conn))
        case .missingProfile(let conn):
          return .gertrudeSupervisionReboot(.supervisedButNeedsProfile(conn))
        case .complete(let conn):
          return .gertrudeSupervisionReboot(.serverClientDisagreement(conn))
        }
      }
      return .gertrudeSupervisionReboot(.networkError)
    }

    let disabledBlockGroupIds = self.sharedStorage.loadDisabledBlockGroupIds()
    let connection = self.sharedStorage.loadAccountConnection()

    switch (connection, filterRunning, disabledBlockGroupIds) {

    case (.some(let conn), /* filter on: */ true, /* groups: */ _):
      return .running(.connected(conn))

    case ( /* conn: */ nil, /* filter on: */ true, /* groups: */ .some):
      return .running(.unconnected)

    case ( /* conn: */ _, /* filter on: */ false, /* groups: */ .none):
      return .onboardingNeeded

    case (.some(let conn), /* filter on: */ false, /* groups: */ .some)
      where conn.supervisedByGertrude:
      return .profileRemovedRecovery(conn)

    case ( /* conn: */ _, /* filter on: */ false, /* groups: */ .some):
      return .filterNoLongerRunning

    case ( /* conn: */ _, /* filter on: */ true, /* groups: */ .none):
      return .configuratorSupervisionFirstLaunch
    }
  }
}
