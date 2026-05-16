import Cocoa
import Core
import CoreGraphics
import Dependencies
import Foundation

typealias ScreenshotData = (data: Data, width: Int, height: Int, createdAt: Date)

@Sendable func takeScreenshot(width: Int) async throws {
  @Dependency(\.device) var device
  @Dependency(\.date.now) var now
  guard device.currentUserHasScreen(), !device.screensaverRunning() else {
    return
  }

  guard screenshotFloor.admit(at: now) else {
    return
  }

  // see reverted commit 05fa044 for ScreenCaptureKit alt implementation
  // removed because it didn't fix sequoia's misleading bypass warning
  guard let fullsize = CGWindowListCreateImage(
    CGRect.infinite,
    .optionAll,
    kCGNullWindowID,
    .nominalResolution,
  ) else {
    throw ScreenshotError.createImageFailed
  }

  guard !fullsize.isBlank else {
    return
  }

  defer {
    lastImage.replace(with: fullsize)
  }

  let isNearlyIdentical = lastImage.withValue { lastImage in
    lastImage?.isNearlyIdenticalTo(fullsize) == true
  }

  guard !isNearlyIdentical else {
    return
  }

  let tmpFilename = ".\(Date().timeIntervalSince1970).png"
  let tmpFullsizePngUrl = diskUrl(filename: tmpFilename)

  guard writeCGImage(fullsize, to: tmpFullsizePngUrl) else {
    throw ScreenshotError.writeToDiskFailed
  }

  defer {
    try? FileManager.default.removeItem(at: tmpFullsizePngUrl)
  }

  guard let jpegData = downsampleToJpeg(imageAt: tmpFullsizePngUrl, to: CGFloat(width)) else {
    throw ScreenshotError.downsampleFailed
  }

  let height = Int(Double(fullsize.height) * (Double(width) / Double(fullsize.width)))

  let screenshot = (data: jpegData, width: width, height: height, createdAt: now)
  await screenshotBuffer.append(screenshot)
}

enum ScreenshotError: Error {
  case createImageFailed
  case writeToDiskFailed
  case downsampleFailed
}

// this technique should be reliable for all supported os's, (including catalina)
// and does not cause a system prompt for screen recording permission
// @see https://www.ryanthomson.net/articles/screen-recording-permissions-catalina-mess/
@Sendable func isScreenRecordingPermissionGranted() -> Bool {
  guard let windowList = CGWindowListCopyWindowInfo(.excludeDesktopElements, kCGNullWindowID)
    as NSArray? else { return false }

  for case let windowInfo as NSDictionary in windowList {
    // Ignore windows owned by this application
    let windowPID = windowInfo[kCGWindowOwnerPID] as? pid_t
    if windowPID == NSRunningApplication.current.processIdentifier {
      continue
    }
    // Ignore system UI elements
    if windowInfo[kCGWindowOwnerName] as? String == "Window Server" {
      continue
    }

    if windowInfo[kCGWindowName] != nil {
      return true
    }
  }

  return false
}

// helpers

private func diskUrl(filename: String) -> URL {
  let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  return docsDir.appendingPathComponent(filename)
}

private func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
  guard
    let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil)
  else {
    return false
  }
  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination)
}

private func downsampleToJpeg(imageAt imageURL: URL, to maxDimension: CGFloat) -> Data? {
  let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
  guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
    return nil
  }

  let options = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceThumbnailMaxPixelSize: maxDimension,
  ] as CFDictionary

  guard let cgImg = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
    return nil
  }

  let bitmap = NSBitmapImageRep(cgImage: cgImg)
  let props: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.7]
  return bitmap.representation(using: .jpeg, properties: props)
}

private let lastImage = Mutex<CGImage?>(nil)

private let minScreenshotIntervalSec: TimeInterval = 10
private let screenshotFloor = ScreenshotFloor(minInterval: minScreenshotIntervalSec)

private final class ScreenshotFloor: @unchecked Sendable {
  private let lock = NSLock()
  private let minInterval: TimeInterval
  private var last: Date?

  init(minInterval: TimeInterval) {
    self.minInterval = minInterval
  }

  func admit(at now: Date) -> Bool {
    self.lock.lock()
    defer { self.lock.unlock() }
    if let last = self.last, now.timeIntervalSince(last) < self.minInterval {
      return false
    }
    self.last = now
    return true
  }
}

actor ScreenshotTimerController {
  private var task: Task<Void, Never>?
  private var currentIntervalSec: Int?
  private var generation = 0

  func reconfigure(
    intervalSec: Int,
    scheduler: AnySchedulerOf<DispatchQueue>,
    fire: @escaping @Sendable () async -> Void,
  ) async {
    if self.currentIntervalSec == intervalSec, self.task != nil {
      return
    }
    self.generation &+= 1
    let myGeneration = self.generation
    self.task?.cancel()
    await self.task?.value
    guard myGeneration == self.generation else {
      return
    }
    self.currentIntervalSec = intervalSec
    let ticks = scheduler.timer(interval: .seconds(intervalSec))
    let task = Task {
      for await _ in ticks {
        await fire()
      }
    }
    self.task = task
    await task.value
  }

  func stop() async {
    self.generation &+= 1
    let myGeneration = self.generation
    self.currentIntervalSec = nil
    self.task?.cancel()
    await self.task?.value
    guard myGeneration == self.generation else {
      return
    }
    self.task = nil
  }
}

extension DependencyValues {
  var screenshotTimer: ScreenshotTimerController {
    get { self[ScreenshotTimerControllerKey.self] }
    set { self[ScreenshotTimerControllerKey.self] = newValue }
  }
}

private enum ScreenshotTimerControllerKey: DependencyKey {
  static let liveValue = ScreenshotTimerController()
  static var testValue: ScreenshotTimerController { ScreenshotTimerController() }
}

actor ScreenshotBuffer {
  private var buffer: [ScreenshotData] = []

  func append(_ screenshot: ScreenshotData) {
    if self.buffer.count > 100 {
      self.buffer.removeFirst()
    }
    self.buffer.append(screenshot)
  }

  func removeAll() -> [ScreenshotData] {
    defer { buffer.removeAll() }
    return self.buffer
  }
}

let screenshotBuffer = ScreenshotBuffer()
