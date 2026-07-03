import Dependencies
import Foundation
import LibClients
import LibCore

public protocol FinishableBroadcast: Sendable {
  func finishWithError(_ error: any Error)
}

let failedToSave: any Error = NSError(
  domain: "com.netrivet.gertrude-ios.app.recorder.finishWithError",
  code: 1111,
  userInfo: [NSLocalizedDescriptionKey: "Failed to save screenshot to device."],
)

public struct Frame: Sendable, Equatable {
  public var jpeg: Data
  public var width: Int
  public var height: Int
  public var unchanged: Bool

  public init(jpeg: Data, width: Int, height: Int, unchanged: Bool) {
    self.jpeg = jpeg
    self.width = width
    self.height = height
    self.unchanged = unchanged
  }
}

public struct SampleHandlerProxy {
  struct Deps: Sendable {
    @Dependency(\.date.now) var now
    @Dependency(\.sharedStorage) var storage
    @Dependency(\.screenshotRepo) var repo
    @Dependency(\.recorderEvents) var events
    @Dependency(\.osLog) var logger
  }

  let deps = Deps()
  let finisher: any FinishableBroadcast
  var lastSampleTime: Date?

  public init(finisher: any FinishableBroadcast) {
    self.finisher = finisher
    self.deps.logger.setPrefix("RECORDER")
  }

  public func broadcastStarted() {
    self.deps.logger.log("broadcast started")
    Witness.recorderStart.emit()
    self.deps.events.emit(.broadcastStarted)
  }

  public func broadcastPaused() {
    self.deps.events.emit(.broadcastPaused)
  }

  public func broadcastResumed() {
    self.deps.events.emit(.broadcastResumed)
  }

  public func broadcastFinished() {
    self.deps.logger.log("broadcast finished")
    Witness.recorderStop.emit()
    self.deps.storage
      .saveScreenshotLastSaved(self.deps.now - RecordingSuspension.livenessWindow)
    self.deps.events.emit(.broadcastFinished)
  }

  public mutating func shouldProcessBuffer() -> Bool {
    guard let lastTime = self.lastSampleTime else {
      self.lastSampleTime = self.deps.now
      return true
    }
    if self.deps.now.timeIntervalSince(lastTime) >= RecordingSuspension.screenshotInterval {
      self.lastSampleTime = self.deps.now
      return true
    }
    return false
  }

  public func processFrame(_ frame: Frame) {
    if frame.unchanged {
      self.deps.logger.debug("ignoring unchanged screen")
      self.deps.storage.saveScreenshotLastSaved(self.deps.now)
      return
    }
    let saved = self.deps.repo.save(.init(
      data: frame.jpeg,
      width: frame.width,
      height: frame.height,
      createdAt: self.deps.now,
    ))
    if saved {
      self.deps.logger.log("saved screenshot for upload: \(frame.width)x\(frame.height)")
      Witness.recorderScreenshotSaved.emit("\(frame.width)x\(frame.height)")
      self.deps.storage.saveScreenshotLastSaved(self.deps.now)
    } else {
      self.finisher.finishWithError(failedToSave)
    }
  }
}
