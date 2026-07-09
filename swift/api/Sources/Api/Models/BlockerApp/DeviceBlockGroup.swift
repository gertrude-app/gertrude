import DuetSQL
import GertieBlocker

extension BlockerApp {
  @DuetModel(schema: "blocker_app", table: "device_block_groups")
  struct DeviceBlockGroup: Codable, Sendable {
    var id: Id
    var deviceId: IOSDevice.Id
    var blockGroupId: BlockGroup.Id
    var createdAt = Date()

    init(id: Id = .init(), deviceId: IOSDevice.Id, blockGroupId: BlockGroup.Id) {
      self.id = id
      self.deviceId = deviceId
      self.blockGroupId = blockGroupId
    }
  }
}
