import DuetSQL
import GertieApp
import IOSAppsRoute

@DuetModel(schema: "child", table: "ios_device_transitions")
struct IOSDeviceTransition: Codable, Sendable, Equatable {
  var id: Id = .init()
  var oldDeviceId: IOSDevice.Id
  var newDeviceId: IOSDevice.Id
  var kind: ReportIdentityTransition.Kind
  var app: GertrudeIOSApp
  var verified: Bool
  var createdAt = Date()
}
