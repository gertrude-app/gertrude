import Vapor

public extension Configure {
  static func jobs(_ app: Application) throws {
    app.queues.use(.fluent())
    app.queues.configuration.workerCount = 1
    app.queues.configuration.refreshInterval = .seconds(300)

    app.queues.schedule(CleanupJob()).daily().at(2, 30, .am)
    app.queues.schedule(SubscriptionManager()).daily().at(6, 30, .am)
    app.queues.schedule(DiskSpaceJob()).hourly().at(0)
    app.queues.schedule(ScheduledMarketingCampaignJob()).daily().at(10, 30, .am)
    app.queues.schedule(CrashReporterJob()).hourly().at(25)

    // sync job runs twice hourly to preserve inferred new rating granularity
    app.queues.schedule(AppStoreSyncJob()).hourly().at(05)
    app.queues.schedule(AppStoreSyncJob()).hourly().at(35)

    for offset in stride(from: 0, to: 60, by: 10) {
      app.queues.schedule(AnalyticsJob()).hourly().at(.init(integerLiteral: offset))
    }

    for offset in stride(from: 0, to: 60, by: 10) {
      app.queues.schedule(AppStoreVersionPollJob()).hourly().at(.init(integerLiteral: offset))
    }

    try app.queues.startScheduledJobs()

    #if DEBUG
      app.asyncCommands.use(ResetCommand(), as: "reset")
    #endif
    app.asyncCommands.use(SyncStagingDataCommand(), as: "sync-staging-data")
  }
}
