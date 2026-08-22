import SwiftUI
import Testing

@testable import LibViews

@Test
func playlistArtworkURLsAreDeduplicatedInEntryOrder() {
  let first = URL(string: "https://example.com/first.jpg")!
  let second = URL(string: "https://example.com/second.jpg")!
  let playlist = PlaylistData(
    id: "playlist",
    name: "Playlist",
    entries: [first, first, second, first].enumerated().map { index, url in
      PlaylistEntryData(
        id: "entry-\(index)",
        track: TrackData(
          id: "track-\(index)",
          title: "Track \(index)",
          artist: "Artist",
          artworkUrl: url,
        ),
      )
    },
  )

  #expect(playlist.artworkUrls == [first, second])
}

@Test
func albumDetailUsesOnlyRealCatalogTrackNumbers() {
  let missing = TrackData(id: "missing", title: "Missing", artist: "Artist")
  let numbered = TrackData(
    id: "numbered",
    title: "Numbered",
    artist: "Artist",
    discNumber: 2,
    trackNumber: 7,
  )

  #expect(missing.albumDetailNumber(includesDisc: false) == nil)
  #expect(numbered.albumDetailNumber(includesDisc: false) == "7")
  #expect(numbered.albumDetailNumber(includesDisc: true) == "2.7")
}

@Test
func queueSectionsAreConditional() {
  let queued = PlaybackQueueEntryData(
    id: "queued",
    title: "Queued",
    artist: "Artist",
    artworkURL: nil,
  )
  let context = PlaybackQueueEntryData(
    id: "context",
    title: "Context",
    artist: "Artist",
    artworkURL: nil,
  )

  #expect(PlaybackQueueListRow.makeRows(
    queuedEntries: [queued],
    contextTitle: "Album",
    contextEntries: [],
  ).map(\.id) == [.entry("queued")])
  #expect(PlaybackQueueListRow.makeRows(
    queuedEntries: [],
    contextTitle: "Album",
    contextEntries: [context],
  ).map(\.id) == [.contextHeader, .entry("context")])
}

@Test
func queueShowsAllExplicitEntriesAndOnlyTenContextEntries() {
  let queuedEntries = (1 ... 3).map { queueEntry("queued-\($0)") }
  let contextEntries = (1 ... 12).map { queueEntry("context-\($0)") }
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: queuedEntries,
    contextTitle: "Album",
    contextEntries: contextEntries,
  )
  let visibleRows = PlaybackQueueListRow.visibleRows(rows)

  #expect(visibleRows.map(\.id) == [
    .entry("queued-1"),
    .entry("queued-2"),
    .entry("queued-3"),
    .contextHeader,
    .entry("context-1"),
    .entry("context-2"),
    .entry("context-3"),
    .entry("context-4"),
    .entry("context-5"),
    .entry("context-6"),
    .entry("context-7"),
    .entry("context-8"),
    .entry("context-9"),
    .entry("context-10"),
  ])
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [visibleRows.count - 1],
    toOffset: 0,
  ) == PlaybackQueueOrder(
    entryIDs: ["context-10"]
      + queuedEntries.map(\.id)
      + (1 ... 9).map { "context-\($0)" }
      + ["context-11", "context-12"],
    queuedEntryCount: 4,
  ))
}

@Test
func queueReorderingPreservesSectionsWhenItemsStayWithinThem() {
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: [queueEntry("queued-1"), queueEntry("queued-2")],
    contextTitle: "Album",
    contextEntries: [queueEntry("context-1"), queueEntry("context-2")],
  )

  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [1],
    toOffset: 0,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-2", "queued-1", "context-1", "context-2"],
    queuedEntryCount: 2,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [0],
    toOffset: 2,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-2", "queued-1", "context-1", "context-2"],
    queuedEntryCount: 2,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [4],
    toOffset: 3,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-1", "queued-2", "context-2", "context-1"],
    queuedEntryCount: 2,
  ))
}

@Test
func crossingQueueSectionBoundaryChangesOnlyMovedItemPersistence() {
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: [queueEntry("queued-1"), queueEntry("queued-2")],
    contextTitle: "Album",
    contextEntries: [queueEntry("context-1"), queueEntry("context-2")],
  )

  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [1],
    toOffset: 2,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-1", "queued-2", "context-1", "context-2"],
    queuedEntryCount: 2,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [1],
    toOffset: 3,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-1", "queued-2", "context-1", "context-2"],
    queuedEntryCount: 1,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [3],
    toOffset: 2,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-1", "queued-2", "context-1", "context-2"],
    queuedEntryCount: 3,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [4],
    toOffset: 1,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-1", "context-2", "queued-2", "context-1"],
    queuedEntryCount: 3,
  ))
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [0],
    toOffset: rows.count,
  ) == PlaybackQueueOrder(
    entryIDs: ["queued-2", "context-1", "context-2", "queued-1"],
    queuedEntryCount: 1,
  ))
}

@Test
func movingAboveOnlyContextHeaderCreatesQueuedSection() {
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: [],
    contextTitle: "Album",
    contextEntries: [queueEntry("context-1"), queueEntry("context-2")],
  )

  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [1],
    toOffset: 0,
  ) == PlaybackQueueOrder(
    entryIDs: ["context-1", "context-2"],
    queuedEntryCount: 1,
  ))
}

@Test
func queueReorderingAcceptsEveryDestinationForEveryEntry() {
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: [queueEntry("queued-1"), queueEntry("queued-2")],
    contextTitle: "Album",
    contextEntries: [queueEntry("context-1"), queueEntry("context-2")],
  )
  let entryIndices = rows.indices.filter {
    if case .entry = rows[$0] { return true }
    return false
  }
  let expectedEntryIDs = Set(["queued-1", "queued-2", "context-1", "context-2"])

  for entryIndex in entryIndices {
    for destination in 0 ... rows.count {
      let order = PlaybackQueueListRow.order(
        rows: rows,
        moving: [entryIndex],
        toOffset: destination,
      )
      #expect(order != nil, "source \(entryIndex), destination \(destination)")
      #expect(Set(order?.entryIDs ?? []) == expectedEntryIDs)
      #expect((0 ... expectedEntryIDs.count).contains(order?.queuedEntryCount ?? -1))
    }
  }
}

@Test
func queueReorderingRejectsHeadersAndInvalidDestinations() {
  let rows = PlaybackQueueListRow.makeRows(
    queuedEntries: [queueEntry("queued")],
    contextTitle: "Album",
    contextEntries: [queueEntry("context")],
  )

  #expect(PlaybackQueueListRow.order(rows: rows, moving: [], toOffset: 0) == nil)
  #expect(PlaybackQueueListRow.order(rows: rows, moving: [1], toOffset: 2) == nil)
  #expect(PlaybackQueueListRow.order(
    rows: rows,
    moving: [0],
    toOffset: rows.count + 1,
  ) == nil)
}

private func queueEntry(_ id: String) -> PlaybackQueueEntryData {
  PlaybackQueueEntryData(
    id: id,
    title: id,
    artist: "Artist",
    artworkURL: nil,
  )
}

@MainActor
@Test
func packageLoads() {
  _ = MusicSetupView(state: .checking)
}
