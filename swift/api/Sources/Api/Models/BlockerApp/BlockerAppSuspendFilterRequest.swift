import DuetSQL
import Gertie
import TaggedTime

extension BlockerApp {
  struct SuspendFilterRequest: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
    var status: RequestStatus
    var duration: Seconds<Int>
    var requestComment: String?
    var responseComment: String?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: IOSDevice.Id,
      status: RequestStatus,
      duration: Seconds<Int>,
      requestComment: String? = nil,
      responseComment: String? = nil,
      createdAt: Date = Date(),
      updatedAt: Date = Date(),
    ) {
      self.id = id
      self.deviceId = deviceId
      self.status = status
      self.duration = duration
      self.requestComment = requestComment
      self.responseComment = responseComment
      self.createdAt = createdAt
      self.updatedAt = updatedAt
    }
  }
}
