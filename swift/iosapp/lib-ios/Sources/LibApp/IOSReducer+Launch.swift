import IOSRoute

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
      case codeClaimedNotSupervised(ChildIOSDeviceData_v2)
      case supervisedButNeedsProfile(ChildIOSDeviceData_v2)
      // anomaly: api says "fully supervised", but filter is not running
      case serverClientDisagreement(ChildIOSDeviceData_v2)
    }

    case running(Running)
    case onboardingNeeded
    case filterNoLongerRunning
    case gertrudeSupervisionReboot(SupervisionReboot)
    case configuratorSupervisionFirstLaunch
  }

  func launchState() async throws -> LaunchState {
    let filterRunning = await self.systemExtension.filterRunning()
    let supervisionData = self.sharedStorage.loadPendingSupervisionCode()

    if !filterRunning, let code = supervisionData?.code {
      let supervisionStatus = try await self.api.checkSupervisionStatus(code)
      switch supervisionStatus {
      case .pending:
        return .gertrudeSupervisionReboot(.codeNotClaimed(code: code))
      case .expired:
        return .gertrudeSupervisionReboot(.codeExpired)
      case .notFound:
        return .gertrudeSupervisionReboot(.codeNotFound)
      case .claimed(let conn):
        return .gertrudeSupervisionReboot(.codeClaimedNotSupervised(conn))
      case .missingProfile(let conn):
        return .gertrudeSupervisionReboot(.supervisedButNeedsProfile(conn))
      case .complete(let conn):
        return .gertrudeSupervisionReboot(.serverClientDisagreement(conn))
      }
    }

    let disabledBlockGroups = self.sharedStorage.loadDisabledBlockGroups()
    let connection = self.sharedStorage.loadAccountConnection()

    switch (connection, filterRunning, disabledBlockGroups) {

    case (.some(let conn), /* filter on: */ true, /* groups: */ _):
      return .running(.connected(conn))

    case ( /* conn: */ nil, /* filter on: */ true, /* groups: */ .some):
      return .running(.unconnected)

    case ( /* conn: */ _, /* filter on: */ false, /* groups: */ .none):
      return .onboardingNeeded

    case ( /* conn: */ _, /* filter on: */ false, /* groups: */ .some):
      return .filterNoLongerRunning

    case ( /* conn: */ _, /* filter on: */ true, /* groups: */ .none):
      return .configuratorSupervisionFirstLaunch
    }
  }
}
