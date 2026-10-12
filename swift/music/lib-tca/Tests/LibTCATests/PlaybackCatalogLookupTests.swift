import Dependencies
import Foundation
import Testing

@testable import LibTCA

struct PlaybackCatalogLookupTests {
  @Test(arguments: [0, 300, 301, 601])
  func batchesRequestsAndRetainsEveryResult(songCount: Int) async throws {
    let songIDs = (0 ..< songCount).map { ApprovedTrack.ID("track-\($0)") }
    let batches = LockIsolated<[[ApprovedTrack.ID]]>([])

    let songs = try await PlaybackClient.catalogSongs(for: songIDs) { batch in
      batches.withValue { $0.append(batch) }
      return Dictionary(uniqueKeysWithValues: batch.map { ($0.rawValue, $0.rawValue) })
    }

    #expect(Set(songs.keys) == Set(songIDs.map(\.rawValue)))
    #expect(batches.value.count == (songCount + 299) / 300)
    #expect(batches.value.allSatisfy { !$0.isEmpty && $0.count <= 300 })
    #expect(batches.value.flatMap(\.self) == songIDs)
  }

  @Test
  func deduplicatesAcrossBatchesAndMergesResultsByID() async throws {
    let uniqueIDs = (0 ..< 301).map { ApprovedTrack.ID("track-\($0)") }
    let songIDs = uniqueIDs + uniqueIDs.reversed()
    let batches = LockIsolated<[[ApprovedTrack.ID]]>([])

    let songs = try await PlaybackClient.catalogSongs(for: songIDs) { batch in
      batches.withValue { $0.append(batch) }
      return Dictionary(uniqueKeysWithValues: batch.reversed().map {
        ($0.rawValue, "song-\($0.rawValue)")
      })
    }

    #expect(batches.value.map(\.count) == [300, 1])
    #expect(batches.value.flatMap(\.self) == uniqueIDs)
    #expect(songs == Dictionary(uniqueKeysWithValues: uniqueIDs.map {
      ($0.rawValue, "song-\($0.rawValue)")
    }))
  }

  @Test
  func laterBatchFailureStopsLookupWithoutReturningPartialResults() async {
    let songIDs = (0 ..< 601).map { ApprovedTrack.ID("track-\($0)") }
    let batchCount = LockIsolated(0)

    await #expect(throws: TestError.self) {
      try await PlaybackClient.catalogSongs(for: songIDs) { batch in
        let count = batchCount.withValue {
          $0 += 1
          return $0
        }
        if count == 2 { throw TestError() }
        return Dictionary(uniqueKeysWithValues: batch.map { ($0.rawValue, $0.rawValue) })
      }
    }
    #expect(batchCount.value == 2)
  }

  @Test
  func cancellationDuringResponseStopsLookup() async {
    let songIDs = (0 ..< 601).map { ApprovedTrack.ID("track-\($0)") }
    let batchCount = LockIsolated(0)
    let task = Task {
      try await PlaybackClient.catalogSongs(for: songIDs) { batch in
        batchCount.withValue { $0 += 1 }
        withUnsafeCurrentTask { $0?.cancel() }
        return Dictionary(uniqueKeysWithValues: batch.map { ($0.rawValue, $0.rawValue) })
      }
    }

    await #expect(throws: CancellationError.self) {
      try await task.value
    }
    #expect(batchCount.value == 1)
  }
}
