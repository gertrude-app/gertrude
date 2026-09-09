import Foundation
import PairQL
import TypeScriptInterop

enum SuperviseTsCodegenRoute: PairQLTsCodegenRoute {
  static var logName: String {
    "Supervise".magenta.bold
  }

  static var sharedAliases: [Config.Alias] {
    [
      .init(NoInput.self, as: "void"),
      .init(Infallible.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
    ]
  }

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("ClientAuth", ClientAuth.self),
    ]
  }

  static var pairqlPairs: [any PairQL.Pair.Type] {
    [
      GetPendingSupervision.self,
      LogSupervisionEvent.self,
      MarkSupervisionVerified.self,
      RecordDeviceUSBConnection.self,
      ReportSupervisionFailed.self,
    ]
  }
}
