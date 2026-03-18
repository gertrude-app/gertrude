import PairQL

public enum UnauthedRoute: PairRoute {
  case logPodcastEvent(LogPodcastEvent.Input)
  case logPodcastEvent_v2(LogPodcastEvent_v2.Input)
  case logPodcastEvent_v3(LogPodcastEvent_v3.Input)
  case podcastProducts
  case createDatabaseUpload(CreateDatabaseUpload.Input)
  case verifyPromoCode(VerifyPromoCode.Input)
  case verifyDbDownload(VerifyDbDownload.Input)
  case migratePodcastVendorId(MigratePodcastVendorId.Input)
}

public extension UnauthedRoute {
  nonisolated(unsafe) static let router: AnyParserPrinter<URLRequestData, UnauthedRoute> = OneOf {
    Route(.case(Self.logPodcastEvent)) {
      Operation(LogPodcastEvent.self)
      Body(.json(LogPodcastEvent.Input.self))
    }
    Route(.case(Self.logPodcastEvent_v2)) {
      Operation(LogPodcastEvent_v2.self)
      Body(.json(LogPodcastEvent_v2.Input.self))
    }
    Route(.case(Self.logPodcastEvent_v3)) {
      Operation(LogPodcastEvent_v3.self)
      Body(.json(LogPodcastEvent_v3.Input.self))
    }
    Route(.case(Self.podcastProducts)) {
      Operation(PodcastProducts.self)
    }
    Route(.case(Self.createDatabaseUpload)) {
      Operation(CreateDatabaseUpload.self)
      Body(.json(CreateDatabaseUpload.Input.self))
    }
    Route(.case(Self.verifyPromoCode)) {
      Operation(VerifyPromoCode.self)
      Body(.json(VerifyPromoCode.Input.self))
    }
    Route(.case(Self.verifyDbDownload)) {
      Operation(VerifyDbDownload.self)
      Body(.json(VerifyDbDownload.Input.self))
    }
    Route(.case(Self.migratePodcastVendorId)) {
      Operation(MigratePodcastVendorId.self)
      Body(.json(MigratePodcastVendorId.Input.self))
    }
  }
  .eraseToAnyParserPrinter()
}
