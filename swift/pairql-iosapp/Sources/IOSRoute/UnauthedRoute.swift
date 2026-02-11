import PairQL

public enum UnauthedRoute: PairRoute {
  case blockRules(BlockRules.Input)
  case blockRules_v2(BlockRules_v2.Input)
  case checkSupervisionFlowStatus(CheckSupervisionFlowStatus.Input)
  case connectDevice_v2(ConnectDevice_v2.Input)
  case createSupervisionClaimCode(CreateSupervisionClaimCode.Input)
  case defaultBlockRules(DefaultBlockRules.Input)
  case logIOSEvent(LogIOSEvent.Input)
  case logIOSEvent_v2(LogIOSEvent_v2.Input)
  case recoveryDirective(RecoveryDirective.Input)
  case recoveryDirective_v2(RecoveryDirective_v2.Input)
  case connectAccountFeatureFlag
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.blockRules)) {
      Operation(BlockRules.self)
      Body(.json(BlockRules.Input.self))
    }
    Route(.case(Self.blockRules_v2)) {
      Operation(BlockRules_v2.self)
      Body(.json(BlockRules_v2.Input.self))
    }
    Route(.case(Self.checkSupervisionFlowStatus)) {
      Operation(CheckSupervisionFlowStatus.self)
      Body(.json(CheckSupervisionFlowStatus.Input.self))
    }
    Route(.case(Self.connectDevice_v2)) {
      Operation(ConnectDevice_v2.self)
      Body(.json(ConnectDevice_v2.Input.self))
    }
    Route(.case(Self.createSupervisionClaimCode)) {
      Operation(CreateSupervisionClaimCode.self)
      Body(.json(CreateSupervisionClaimCode.Input.self))
    }
    Route(.case(Self.defaultBlockRules)) {
      Operation(DefaultBlockRules.self)
      Body(.json(DefaultBlockRules.Input.self))
    }
    Route(.case(Self.logIOSEvent)) {
      Operation(LogIOSEvent.self)
      Body(.json(LogIOSEvent.Input.self))
    }
    Route(.case(Self.logIOSEvent_v2)) {
      Operation(LogIOSEvent_v2.self)
      Body(.json(LogIOSEvent_v2.Input.self))
    }
    Route(.case(Self.recoveryDirective)) {
      Operation(RecoveryDirective.self)
      Body(.json(RecoveryDirective.Input.self))
    }
    Route(.case(Self.recoveryDirective_v2)) {
      Operation(RecoveryDirective_v2.self)
      Body(.json(RecoveryDirective_v2.Input.self))
    }
    Route(.case(Self.connectAccountFeatureFlag)) {
      Operation(ConnectAccountFeatureFlag.self)
    }
  }
  .eraseToAnyParserPrinter()
}
