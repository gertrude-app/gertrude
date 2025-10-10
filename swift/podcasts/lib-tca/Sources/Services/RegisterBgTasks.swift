import ConcurrencyExtras
import Dependencies
import Foundation
import LibCore
import SQLiteData

func initBgTasks() {
  registerBgTasks()
  scheduleFeedRefresh()
}

func registerBgTasks() {
  BGTaskScheduler.shared.register(
    forTaskWithIdentifier: BgTaskId.refreshFeed.rawValue,
    using: nil,
    launchHandler: { task in
      bgRefreshFeeds(task: task as! BGAppRefreshTask)
    }
  )
  BGTaskScheduler.shared.register(
    forTaskWithIdentifier: BgTaskId.downloadEpisodes.rawValue,
    using: nil,
    launchHandler: { task in
      bgDownloadEpisodes(task: task as! BGProcessingTask)
    }
  )
}

func bgRefreshFeeds(task: BGAppRefreshTask) {
  scheduleFeedRefresh()

  let operation = BgRefreshFeedsOperation()

  task.expirationHandler = {
    operation.cancel()
  }

  let wrapped = UncheckedSendable(task)
  operation.completionBlock = {
    wrapped.value.setTaskCompleted(success: !operation.isCancelled)
  }

  operationQueue.addOperation(operation)
}

func bgDownloadEpisodes(task: BGProcessingTask) {
  let operation = BgDownloadEpisodesOperation()

  task.expirationHandler = {
    operation.cancel()
  }

  let wrapped = UncheckedSendable(task)
  operation.completionBlock = {
    wrapped.value.setTaskCompleted(success: !operation.isCancelled)
  }

  operationQueue.addOperation(operation)
}

func scheduleFeedRefresh() {
  let request = BGAppRefreshTaskRequest(identifier: BgTaskId.refreshFeed.rawValue)
  #if DEBUG
    request.earliestBeginDate = .now + .minutes(2)
  #else
    request.earliestBeginDate = .now + .minutes(60)
  #endif
  do {
    try BGTaskScheduler.shared.submit(request)
  } catch {
    unexpected(id: "23be3c77", "\(error)")
  }
}

func scheduleEpisodeDownloads() {
  let request = BGProcessingTaskRequest(identifier: BgTaskId.downloadEpisodes.rawValue)
  request.requiresNetworkConnectivity = true
  #if DEBUG
    request.earliestBeginDate = .now + .minutes(1)
  #else
    request.earliestBeginDate = .now + .minutes(2)
  #endif
  do {
    try BGTaskScheduler.shared.submit(request)
  } catch {
    unexpected(id: "d99cfd5a", "\(error)")
  }
}

final class BgRefreshFeedsOperation: AsyncOperation, @unchecked Sendable {
  private var task: Task<Void, Never>?
  @Dependency(\.db) private var database

  override func main() {
    self.task = Task {
      let start = Date()
      let newEpisodes = await updateFeeds()
      if !newEpisodes.isEmpty {
        scheduleEpisodeDownloads()
      }
      let duration = Date().timeIntervalSince(start)
      let detail = "time: \(String(format: "%.1f", duration))s"
      self.database.insertEvent(name: "bg-feed-refresh", detail: detail)
      self.finish()
    }
  }
}

final class BgDownloadEpisodesOperation: AsyncOperation, @unchecked Sendable {
  private var task: Task<Void, Never>?

  @Dependency(\.db) var database

  override func main() {
    self.task = Task {
      let start = Date()
      let episodes = self.database.tryRead { db in
        try #sql(
          """
          WITH RankedEpisodes AS (
            SELECT *, ROW_NUMBER() OVER(
              PARTITION BY \(Episode.col.showId)
              ORDER BY \(Episode.col.pubDate) DESC
            ) AS rn
            FROM \(Episode.self)
          )
          SELECT \(Episode.columns)
          FROM RankedEpisodes as \(Episode.self)
          WHERE rn <= 3 AND \(Episode.col.downloadedAt) IS NULL;
          """,
          as: Episode.self
        )
        .fetchAll(db)
      }

      await withTaskGroup(of: Void.self) { group in
        for episode in episodes {
          group.addTask {
            _ = await trackedDownload(episode: episode)
          }
        }
        await group.waitForAll()
      }

      let duration = Date().timeIntervalSince(start)
      let timing = "in: \(String(format: "%.1f", duration))s"
      self.database.insertEvent(
        name: "bg-download-episodes -> end",
        detail: "downloaded \(episodes.count) episodes \(timing)"
      )
      self.finish()
    }
  }
}

// NB: keep in sync with project.yml
enum BgTaskId: String {
  case refreshFeed = "com.netrivet.gertrude.am.refresh-feed"
  case downloadEpisodes = "com.netrivet.gertrude.am.download-episodes"
}

class AsyncOperation: Operation, @unchecked Sendable {
  private let _isExecuting = AtomicBool(false)
  private let _isFinished = AtomicBool(false)

  override var isAsynchronous: Bool {
    true
  }

  override var isExecuting: Bool {
    self._isExecuting.value
  }

  override var isFinished: Bool {
    self._isFinished.value
  }

  override func start() {
    if self.isCancelled {
      self.finish()
      return
    }

    willChangeValue(forKey: "isExecuting")
    self._isExecuting.value = true
    self.didChangeValue(forKey: "isExecuting")

    self.main()
  }

  func finish() {
    self.willChangeValue(forKey: "isExecuting")
    self.willChangeValue(forKey: "isFinished")

    self._isExecuting.value = false
    self._isFinished.value = true

    self.didChangeValue(forKey: "isExecuting")
    self.didChangeValue(forKey: "isFinished")
  }
}

private class AtomicBool {
  private let lock = NSLock()
  private var _value: Bool

  init(_ value: Bool) {
    self._value = value
  }

  var value: Bool {
    get {
      self.lock.lock()
      defer { lock.unlock() }
      return self._value
    }
    set {
      self.lock.lock()
      self._value = newValue
      self.lock.unlock()
    }
  }
}

private let operationQueue = OperationQueue()
