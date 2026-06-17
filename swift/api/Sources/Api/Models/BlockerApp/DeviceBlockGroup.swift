import Duet
import GertieBlocker

extension BlockerApp {
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
