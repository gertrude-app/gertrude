import Dependencies
import Foundation
import LibCore
import os.log
import XCore

public final class ScreenshotUploader: NSObject, @unchecked Sendable {
  public static let shared = ScreenshotUploader()

  struct UploadFailed: Error {}

  private struct State {
    var continuations: [Int: CheckedContinuation<Void, any Error>] = [:]
    var onEventsFinished: (@Sendable () -> Void)?
  }

  private let state = Mutex(State())

  private lazy var session: URLSession = {
    let config = URLSessionConfiguration
      .background(withIdentifier: "com.netrivet.gertrude-ios.app.screenshot-uploads")
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    return URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }()

  func upload(_ screenshot: ScreenshotData, to uploadUrl: URL) async throws {
    var request = URLRequest(url: uploadUrl, cachePolicy: .reloadIgnoringCacheData)
    request.httpMethod = "PUT"
    request.addValue("public-read", forHTTPHeaderField: "x-amz-acl")
    request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    let fileUrl = try self.stageFile(for: screenshot)
    let task = self.session.uploadTask(with: request, fromFile: fileUrl)
    task.taskDescription = screenshot.id
    Witness.appUploadEnqueued.emit("id=\(screenshot.id)")
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Void, any Error>) in
      self.state.withLock { $0.continuations[task.taskIdentifier] = continuation }
      task.resume()
    }
  }

  public func handleBackgroundSessionEvents(
    completionHandler: @escaping @Sendable () -> Void,
  ) {
    self.state.withLock { $0.onEventsFinished = completionHandler }
    _ = self.session
  }

  private func stageFile(for screenshot: ScreenshotData) throws -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("screenshot-uploads")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let fileUrl = dir.appendingPathComponent(screenshot.id)
    try screenshot.data.write(to: fileUrl)
    return fileUrl
  }

  private func stagedFileUrl(id: String) -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("screenshot-uploads")
      .appendingPathComponent(id)
  }
}

extension ScreenshotUploader: URLSessionTaskDelegate {
  public func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: (any Error)?,
  ) {
    let status = (task.response as? HTTPURLResponse)?.statusCode ?? 500
    let success = error == nil && status < 300
    if let id = task.taskDescription {
      try? FileManager.default.removeItem(at: self.stagedFileUrl(id: id))
    }
    let continuation = self.state.withLock {
      $0.continuations.removeValue(forKey: task.taskIdentifier)
    }
    Witness.appUploadCompleted.emit({
      let id = task.taskDescription ?? "(nil)"
      return "id=\(id) ok=\(success) status=\(status) stranded=\(continuation == nil)"
    }())
    if let continuation {
      if success {
        continuation.resume()
      } else {
        continuation.resume(throwing: error ?? UploadFailed())
      }
    } else if success, let id = task.taskDescription {
      // no awaiting caller: transfer outlived a terminated app process
      os_log("[G•] UPLOADER completing stranded screenshot upload: %{public}s", id)
      @Dependency(\.screenshotRepo) var repo
      repo.markProcessed(id: id)
    }
  }

  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    Witness.appBgSessionWake.emit()
    let handler = self.state.withLock { state in
      let handler = state.onEventsFinished
      state.onEventsFinished = nil
      return handler
    }
    Task { @MainActor in
      handler?()
    }
    Task {
      await uploadPendingScreenshots()
    }
  }
}
