import Foundation

final class TelemetryBag: @unchecked Sendable {
  private let lock = NSLock()
  private var _parentId: Parent.Id?

  var parentId: Parent.Id? {
    get { self.lock.withLock { self._parentId } }
    set { self.lock.withLock { self._parentId = newValue } }
  }
}
