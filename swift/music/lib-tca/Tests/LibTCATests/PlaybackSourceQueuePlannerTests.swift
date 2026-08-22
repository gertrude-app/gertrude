import CustomDump
import Testing

@testable import LibTCA

struct PlaybackSourceQueuePlannerTests {
  @Test
  func selectedEntryWithoutShuffleStartsSelectedAndOmitsPrefix() throws {
    let source = playbackSource(selectedIndex: 1)
    let explicitEntries = playbackExplicitEntries()

    let entries = try #require(PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .selectedEntry,
      explicitEntries: explicitEntries,
      isShuffleEnabled: false,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    ))

    expectNoDifference(entries, [
      .source(source.entries[1]),
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[2]),
      .source(source.entries[3]),
    ])
  }

  @Test
  func selectedEntryWithShuffleKeepsSelectionFirstAndIncludesPrefix() throws {
    let duplicate = playbackItem("duplicate")
    let source = PlaybackSource(
      items: [playbackItem("first"), duplicate, duplicate, playbackItem("last")],
      selectedIndex: 2,
      context: nil,
    )
    let explicitEntries = playbackExplicitEntries()

    let entries = try #require(PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .selectedEntry,
      explicitEntries: explicitEntries,
      isShuffleEnabled: true,
      shuffle: { $0.reverse() },
    ))

    expectNoDifference(entries, [
      .source(source.entries[2]),
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[3]),
      .source(source.entries[1]),
      .source(source.entries[0]),
    ])
  }

  @Test
  func collectionWithoutShuffleStartsAtSourceBeginning() throws {
    let source = playbackSource(selectedIndex: 2)
    let explicitEntries = playbackExplicitEntries()

    let entries = try #require(PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .collection,
      explicitEntries: explicitEntries,
      isShuffleEnabled: false,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    ))

    expectNoDifference(entries, [
      .source(source.entries[0]),
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[1]),
      .source(source.entries[2]),
      .source(source.entries[3]),
    ])
  }

  @Test
  func collectionWithShuffleChoosesFirstEntryFromShuffledOrder() throws {
    let source = playbackSource(selectedIndex: 2)
    let explicitEntries = playbackExplicitEntries()

    let entries = try #require(PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .collection,
      explicitEntries: explicitEntries,
      isShuffleEnabled: true,
      shuffle: { $0.reverse() },
    ))

    expectNoDifference(entries, [
      .source(source.entries[3]),
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[2]),
      .source(source.entries[1]),
      .source(source.entries[0]),
    ])
  }

  @Test
  func startingPlanOmitsRemovedOccurrences() throws {
    var source = playbackSource(selectedIndex: 1)
    source.remove(0)
    source.remove(2)

    let entries = try #require(PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .collection,
      explicitEntries: [],
      isShuffleEnabled: false,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    ))

    expectNoDifference(entries, [
      .source(source.entries[1]),
      .source(source.entries[3]),
    ])
  }

  @Test
  func selectedStartFailsWhenSelectedOccurrenceWasRemoved() {
    var source = playbackSource(selectedIndex: 1)
    source.remove(1)

    let entries = PlaybackSourceQueuePlanner.startingEntries(
      source: source,
      start: .selectedEntry,
      explicitEntries: [],
      isShuffleEnabled: true,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(entries, nil)
  }

  @Test
  func unshuffledSourceCycleUsesRetainedSourceOrder() throws {
    var source = playbackSource(selectedIndex: 2)
    source.remove(1)

    let entries = try #require(PlaybackSourceQueuePlanner.sourceCycleEntries(
      source: source,
      isShuffleEnabled: false,
      avoidingFirstTrackID: source.entries[0].item.id,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    ))

    expectNoDifference(entries, [
      source.entries[0],
      source.entries[2],
      source.entries[3],
    ])
  }

  @Test
  func shuffledSourceCycleAvoidsRepeatingFinalTrackFirst() throws {
    let duplicate = playbackItem("duplicate")
    let source = PlaybackSource(
      items: [duplicate, playbackItem("first"), playbackItem("second"), duplicate],
      selectedIndex: 0,
      context: nil,
    )

    let entries = try #require(PlaybackSourceQueuePlanner.sourceCycleEntries(
      source: source,
      isShuffleEnabled: true,
      avoidingFirstTrackID: duplicate.id,
      shuffle: { $0.reverse() },
    ))

    expectNoDifference(entries, [
      source.entries[2],
      source.entries[3],
      source.entries[1],
      source.entries[0],
    ])
  }

  @Test
  func preparedSourceCycleRequiresEveryRetainedOccurrence() throws {
    var source = playbackSource(selectedIndex: 0)
    source.remove(1)

    let entries = try #require(PlaybackSourceQueuePlanner.sourceCycleEntries(
      source: source,
      entryIDs: [3, 0, 2],
    ))
    let incompleteEntries = PlaybackSourceQueuePlanner.sourceCycleEntries(
      source: source,
      entryIDs: [3, 0],
    )

    expectNoDifference(entries, [
      source.entries[3],
      source.entries[0],
      source.entries[2],
    ])
    expectNoDifference(incompleteEntries, nil)
  }

  @Test
  func enablingShuffleRandomizesOnlyRemainingSourceOccurrences() {
    let source = playbackSource(selectedIndex: 0)
    let explicitEntries = playbackExplicitEntries()

    let entries = PlaybackSourceQueuePlanner.upcomingEntries(
      source: source,
      remainingSourceEntryIDs: [3, 1, 2],
      explicitEntries: explicitEntries,
      isShuffleEnabled: true,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(entries, [
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[2]),
      .source(source.entries[1]),
      .source(source.entries[3]),
    ])
  }

  @Test
  func disablingShuffleRestoresRemainingSourceOrder() {
    let source = playbackSource(selectedIndex: 0)
    let explicitEntries = playbackExplicitEntries()

    let entries = PlaybackSourceQueuePlanner.upcomingEntries(
      source: source,
      remainingSourceEntryIDs: [3, 1, 2],
      explicitEntries: explicitEntries,
      isShuffleEnabled: false,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    )

    expectNoDifference(entries, [
      .explicit(explicitEntries[0]),
      .explicit(explicitEntries[1]),
      .source(source.entries[1]),
      .source(source.entries[2]),
      .source(source.entries[3]),
    ])
  }

  @Test
  func upcomingPlanRetainsDistinctDuplicateTrackOccurrences() {
    let duplicate = playbackItem("duplicate")
    var source = PlaybackSource(
      items: [playbackItem("first"), duplicate, duplicate, playbackItem("last")],
      selectedIndex: 0,
      context: nil,
    )
    source.remove(3)

    let entries = PlaybackSourceQueuePlanner.upcomingEntries(
      source: source,
      remainingSourceEntryIDs: [3, 2, 2, 99, 1],
      explicitEntries: [],
      isShuffleEnabled: false,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    )

    expectNoDifference(entries, [
      .source(source.entries[1]),
      .source(source.entries[2]),
    ])
  }

  @Test
  func infiniteCandidatePlanUsesUniversalSourceRelatedAndOtherPhases() throws {
    let sourceAlbum = ApprovedAlbum(
      id: "source-album",
      title: "Source Album",
      artistName: "Various Artists",
      tracks: [
        ApprovedTrack(id: "source-a", title: "Source A", artistName: "Artist A"),
        ApprovedTrack(id: "source-b", title: "Source B", artistName: "Artist B"),
      ],
    )
    let relatedAAlbum = ApprovedAlbum(
      id: "related-a-album",
      title: "Related A Album",
      artistName: "Artist A",
      tracks: [
        ApprovedTrack(id: "related-a", title: "Related A", artistName: "Artist A"),
      ],
    )
    let duplicateRelatedAAlbum = ApprovedAlbum(
      id: "duplicate-related-a-album",
      title: "Duplicate Related A Album",
      artistName: "Artist A",
      tracks: [
        ApprovedTrack(id: "related-a", title: "Related A", artistName: "Artist A"),
      ],
    )
    let relatedBAlbum = ApprovedAlbum(
      id: "related-b-album",
      title: "Related B Album",
      artistName: "Artist B",
      tracks: [
        ApprovedTrack(id: "related-b", title: "Related B", artistName: "Artist B"),
      ],
    )
    let otherAlbum = ApprovedAlbum(
      id: "other-album",
      title: "Other Album",
      artistName: "Artist C",
      tracks: [
        ApprovedTrack(id: "other", title: "Other", artistName: "Artist C"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [
      sourceAlbum,
      relatedAAlbum,
      duplicateRelatedAAlbum,
      relatedBAlbum,
      otherAlbum,
    ])
    let source = PlaybackSource(
      items: [
        PlaybackItem(
          track: sourceAlbum.tracks[0],
          artworkURL: sourceAlbum.artworkURL,
          albumID: sourceAlbum.id,
        ),
        PlaybackItem(
          track: sourceAlbum.tracks[1],
          artworkURL: sourceAlbum.artworkURL,
          albumID: sourceAlbum.id,
        ),
        PlaybackItem(
          track: sourceAlbum.tracks[0],
          artworkURL: sourceAlbum.artworkURL,
          albumID: sourceAlbum.id,
        ),
      ],
      selectedIndex: 1,
      context: nil,
    )

    let plan = try #require(InfinitePlaybackCandidatePlanner.plan(
      source: source,
      library: library,
    ))

    expectNoDifference(plan, InfinitePlaybackCandidatePlanner.Plan(
      sourceEntries: [source.entries[1], source.entries[2], source.entries[0]],
      relatedItems: [
        PlaybackItem(
          track: relatedAAlbum.tracks[0],
          artworkURL: relatedAAlbum.artworkURL,
          albumID: relatedAAlbum.id,
        ),
        PlaybackItem(
          track: relatedBAlbum.tracks[0],
          artworkURL: relatedBAlbum.artworkURL,
          albumID: relatedBAlbum.id,
        ),
      ],
      otherItems: [
        PlaybackItem(
          track: otherAlbum.tracks[0],
          artworkURL: otherAlbum.artworkURL,
          albumID: otherAlbum.id,
        ),
      ],
    ))
  }

  @Test
  func initialInfinitePlanRandomizesGeneratedPhasesIndependently() {
    let source = playbackSource(selectedIndex: 0)
    let relatedFirst = playbackItem("related-first")
    let relatedSecond = playbackItem("related-second")
    let otherFirst = playbackItem("other-first")
    let otherSecond = playbackItem("other-second")
    let plan = InfinitePlaybackCandidatePlanner.Plan(
      sourceEntries: source.entries,
      relatedItems: [relatedFirst, relatedSecond],
      otherItems: [otherFirst, otherSecond],
    )

    let randomizedPlan = InfinitePlaybackCandidatePlanner.randomizedInitialPlan(
      plan,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(randomizedPlan, InfinitePlaybackCandidatePlanner.Plan(
      sourceEntries: source.entries,
      relatedItems: [relatedSecond, relatedFirst],
      otherItems: [otherSecond, otherFirst],
    ))
  }

  @Test
  func laterInfiniteCycleShufflesEveryUniqueTrackAndAvoidsBoundaryRepeat() {
    let firstAlbum = ApprovedAlbum(
      id: "first-album",
      title: "First Album",
      artistName: "First Artist",
      tracks: [
        ApprovedTrack(id: "first", title: "First", artistName: "First Artist"),
        ApprovedTrack(id: "second", title: "Second", artistName: "First Artist"),
      ],
    )
    let duplicateAlbum = ApprovedAlbum(
      id: "duplicate-album",
      title: "Duplicate Album",
      artistName: "Second Artist",
      tracks: [
        ApprovedTrack(id: "second", title: "Second", artistName: "Second Artist"),
      ],
    )
    let finalAlbum = ApprovedAlbum(
      id: "final-album",
      title: "Final Album",
      artistName: "Final Artist",
      tracks: [
        ApprovedTrack(id: "final", title: "Final", artistName: "Final Artist"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [
      firstAlbum,
      duplicateAlbum,
      finalAlbum,
    ])

    let items = InfinitePlaybackCandidatePlanner.libraryCycleItems(
      library: library,
      avoidingFirstTrackID: finalAlbum.tracks[0].id,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(items, [
      playbackItems(album: firstAlbum)[1],
      playbackItems(album: finalAlbum)[0],
      playbackItems(album: firstAlbum)[0],
    ])
  }

  @Test
  func singleTrackInfiniteCycleAcceptsBoundaryRepeat() {
    let album = ApprovedAlbum(
      id: "only-album",
      title: "Only Album",
      artistName: "Only Artist",
      tracks: [
        ApprovedTrack(id: "only", title: "Only", artistName: "Only Artist"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [album])

    let items = InfinitePlaybackCandidatePlanner.libraryCycleItems(
      library: library,
      avoidingFirstTrackID: album.tracks[0].id,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(items, playbackItems(album: album))
  }

  @Test
  func infiniteLookaheadCapsAtTenAndPrioritizesSourceEntries() {
    let source = playbackSource(selectedIndex: 0)
    let generatedItems = (0 ..< 9).map { playbackItem("generated-\($0)") }

    let entries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: Array(source.entries.prefix(3)),
      generatedItems: generatedItems,
      approvedUniqueTrackCount: 20,
    )

    expectNoDifference(entries, [
      .source(source.entries[0]),
      .source(source.entries[1]),
      .source(source.entries[2]),
      .generated(generatedItems[0]),
      .generated(generatedItems[1]),
      .generated(generatedItems[2]),
      .generated(generatedItems[3]),
      .generated(generatedItems[4]),
      .generated(generatedItems[5]),
      .generated(generatedItems[6]),
    ])
  }

  @Test
  func infiniteLookaheadUsesApprovedUniqueCountAsSmallerTarget() {
    let source = playbackSource(selectedIndex: 0)

    let entries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: source.entries,
      generatedItems: [playbackItem("generated")],
      approvedUniqueTrackCount: 2,
    )

    expectNoDifference(entries, [
      .source(source.entries[0]),
      .source(source.entries[1]),
    ])
  }

  @Test
  func infiniteLookaheadReturnsAvailablePreparedEntriesWhenUnderfilled() {
    let source = playbackSource(selectedIndex: 0)
    let generatedItem = playbackItem("generated")

    let entries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: Array(source.entries.prefix(2)),
      generatedItems: [generatedItem],
      approvedUniqueTrackCount: 10,
    )

    expectNoDifference(entries, [
      .source(source.entries[0]),
      .source(source.entries[1]),
      .generated(generatedItem),
    ])
  }

  @Test
  func infiniteLookaheadDoesNotReplenishWhilePreparedItemsFillTarget() {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 4).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let items = playbackItems(album: album)
    let source = PlaybackSource(
      items: Array(items.prefix(2)),
      selectedIndex: 0,
      context: nil,
    )

    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: source.entries,
      generatedItems: Array(items.suffix(2)),
      library: ApprovedMusicLibrary(albums: [album]),
      previousTrackID: items[0].id,
      shuffle: { _ in Issue.record("shuffle should not be used") },
    )

    expectNoDifference(generatedItems, [items[2], items[3]])
  }

  @Test
  func infiniteLookaheadAppendsWholeCycleWithDistinctVisiblePrefix() {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 5).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let items = playbackItems(album: album)
    let source = PlaybackSource(
      items: [items[0]],
      selectedIndex: 0,
      context: nil,
    )

    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: source.entries,
      generatedItems: [items[1]],
      library: ApprovedMusicLibrary(albums: [album]),
      previousTrackID: items[0].id,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(generatedItems, [
      items[1],
      items[4],
      items[3],
      items[2],
      items[1],
      items[0],
    ])
  }

  @Test
  func infiniteLookaheadReplenishmentUsesPreviousTrackBeforeVisibleDuplicates() {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 4).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let items = playbackItems(album: album)
    let source = PlaybackSource(
      items: [items[2]],
      selectedIndex: 0,
      context: nil,
    )

    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: source.entries,
      generatedItems: [items[1]],
      library: ApprovedMusicLibrary(albums: [album]),
      previousTrackID: items[0].id,
      shuffle: { _ in },
    )

    expectNoDifference(generatedItems, [
      items[1],
      items[3],
      items[0],
      items[1],
      items[2],
    ])
  }

  @Test
  func infiniteLookaheadReplenishmentAcceptsSingleTrackFallback() {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: [
        ApprovedTrack(id: "track", title: "Track", artistName: "Artist"),
      ],
    )
    let item = playbackItems(album: album)[0]

    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: [],
      generatedItems: [],
      library: ApprovedMusicLibrary(albums: [album]),
      previousTrackID: item.id,
      shuffle: { $0.reverse() },
    )

    expectNoDifference(generatedItems, [item])
  }

  @Test
  func exhaustedRepresentedArtistNaturallyHasNoRelatedCandidates() throws {
    let artistAlbum = ApprovedAlbum(
      id: "artist-album",
      title: "Artist Album",
      artistName: "Artist",
      tracks: [
        ApprovedTrack(id: "artist-1", title: "Artist 1", artistName: "Artist"),
        ApprovedTrack(id: "artist-2", title: "Artist 2", artistName: "Artist"),
      ],
    )
    let otherAlbum = ApprovedAlbum(
      id: "other-album",
      title: "Other Album",
      artistName: "Other Artist",
      tracks: [
        ApprovedTrack(id: "other", title: "Other", artistName: "Other Artist"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [artistAlbum, otherAlbum])
    let source = PlaybackSource(
      items: artistAlbum.tracks.map {
        PlaybackItem(
          track: $0,
          artworkURL: artistAlbum.artworkURL,
          albumID: artistAlbum.id,
        )
      },
      selectedIndex: 0,
      context: nil,
    )

    let plan = try #require(InfinitePlaybackCandidatePlanner.plan(
      source: source,
      library: library,
    ))

    expectNoDifference(plan, InfinitePlaybackCandidatePlanner.Plan(
      sourceEntries: source.entries,
      relatedItems: [],
      otherItems: [
        PlaybackItem(
          track: otherAlbum.tracks[0],
          artworkURL: otherAlbum.artworkURL,
          albumID: otherAlbum.id,
        ),
      ],
    ))
  }
}

private func playbackSource(selectedIndex: Int) -> PlaybackSource {
  PlaybackSource(
    items: (0 ..< 4).map { playbackItem("source-\($0)") },
    selectedIndex: selectedIndex,
    context: nil,
  )
}

private func playbackExplicitEntries() -> [PlaybackQueueEntry] {
  [
    PlaybackQueueEntry(
      id: "explicit-1",
      item: playbackItem("explicit-1").withQueueRole(.queued),
      viewID: "explicit-view-1",
    ),
    PlaybackQueueEntry(
      id: "explicit-2",
      item: playbackItem("explicit-2").withQueueRole(.queued),
      viewID: "explicit-view-2",
    ),
  ]
}
