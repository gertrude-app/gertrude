import Dependencies
import DependenciesMacros
import Foundation
import LibCore
import os.log

public struct ScreenshotData: Sendable, Equatable {
  public var id: String
  public var data: Data
  public var width: Int
  public var height: Int
  public var createdAt: Date

  public init(
    id: String = UUID().uuidString,
    data: Data,
    width: Int,
    height: Int,
    createdAt: Date,
  ) {
    self.id = id
    self.data = data
    self.width = width
    self.height = height
    self.createdAt = createdAt
  }
}

@DependencyClient
public struct ScreenshotRepoClient: Sendable {
  public var save: @Sendable (ScreenshotData) -> Bool = { _ in true }
  public var nextUnprocessed: @Sendable () -> ScreenshotData? = { nil }
  public var markProcessed: @Sendable (_ id: String) -> Void
  public var pendingCount: @Sendable () -> Int = { 0 }
}

struct ScreenshotMetaData: Sendable, Codable {
  let width: Int
  let height: Int
  let createdAt: Date

  var filename: String {
    "screenshot-\(self.createdAt.timeIntervalSinceReferenceDate)-\(UUID()).jpg"
  }
}

extension ScreenshotRepoClient: DependencyKey {
  public static var liveValue: ScreenshotRepoClient {
    .init(
      save: { screenshot in
        guard let dir = URL.screenshotsDir, ensureDirExists(dir) else {
          return false
        }
        let metaData = ScreenshotMetaData(
          width: screenshot.width,
          height: screenshot.height,
          createdAt: screenshot.createdAt,
        )
        let filename = metaData.filename
        do {
          try screenshot.data.write(to: dir.appendingPathComponent(filename))
        } catch {
          return false
        }
        @Dependency(\.groupDefaults) var defaults
        if let encoded = try? JSONEncoder().encode(metaData) {
          defaults.setData(data: encoded, forKey: filename)
        }
        return true
      },
      nextUnprocessed: { nextUnprocessedFile(depth: 0) },
      markProcessed: { filename in
        guard let dir = URL.screenshotsDir else { return }
        @Dependency(\.groupDefaults) var defaults
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
        defaults.remove(forKey: filename)
      },
      pendingCount: {
        guard let dir = URL.screenshotsDir else { return 0 }
        let files = try? FileManager.default
          .contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        return files?.count ?? 0
      },
    )
  }
}

private func ensureDirExists(_ dir: URL) -> Bool {
  let fm = FileManager.default
  if fm.fileExists(atPath: dir.path) {
    return true
  }
  do {
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    return true
  } catch {
    return false
  }
}

private func nextUnprocessedFile(depth: Int) -> ScreenshotData? {
  guard let dir = URL.screenshotsDir, depth < 50 else {
    return nil
  }
  let fm = FileManager.default
  var files: [URL]
  do {
    files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
  } catch {
    return nil
  }
  files.sort { $0.lastPathComponent < $1.lastPathComponent }
  guard let file = files.first else {
    return nil
  }

  @Dependency(\.groupDefaults) var defaults
  guard let imageData = try? Data(contentsOf: file),
        let metaEncoded = defaults.data(forKey: file.lastPathComponent),
        let metaData = try? JSONDecoder().decode(ScreenshotMetaData.self, from: metaEncoded) else {
    os_log("[G•] failed to load screenshot data for file: %{public}s", file.path)
    try? fm.removeItem(at: file)
    defaults.remove(forKey: file.lastPathComponent)
    return nextUnprocessedFile(depth: depth + 1)
  }

  return ScreenshotData(
    id: file.lastPathComponent,
    data: imageData,
    width: metaData.width,
    height: metaData.height,
    createdAt: metaData.createdAt,
  )
}

extension ScreenshotRepoClient: TestDependencyKey {
  public static let testValue = ScreenshotRepoClient()
}

public extension ScreenshotRepoClient {
  static func inMemory(_ store: LockIsolated<[ScreenshotData]>) -> ScreenshotRepoClient {
    .init(
      save: { screenshot in
        store.withValue { $0.append(screenshot) }
        return true
      },
      nextUnprocessed: {
        store.value.min { $0.createdAt < $1.createdAt }
      },
      markProcessed: { id in
        store.withValue { $0.removeAll { $0.id == id } }
      },
      pendingCount: { store.value.count },
    )
  }
}

@Sendable public func uploadPendingScreenshots() async {
  @Dependency(\.sharedStorage) var storage
  @Dependency(\.api) var api
  @Dependency(\.screenshotRepo) var repo
  @Dependency(\.osLog) var logger
  guard let connection = storage.loadAccountConnection() else {
    logger.log("no account connection, skipping screenshot upload")
    return
  }
  await api.setAccountConnection(connection)
  var uploaded = 0
  while let screenshot = repo.nextUnprocessed(), uploaded < 500 {
    do {
      try await api.uploadScreenshot(screenshot)
      repo.markProcessed(id: screenshot.id)
      uploaded += 1
    } catch {
      logger.log("failed to upload screenshot: \(String(reflecting: error))")
      break
    }
  }
}

public extension DependencyValues {
  var screenshotRepo: ScreenshotRepoClient {
    get { self[ScreenshotRepoClient.self] }
    set { self[ScreenshotRepoClient.self] = newValue }
  }
}

extension URL {
  static var screenshotsDir: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: .gertrudeGroupId)?
      .appendingPathComponent("screenshots")
  }
}
