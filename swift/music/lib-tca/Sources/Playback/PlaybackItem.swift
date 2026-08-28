import Foundation
import Tagged

struct PlaylistPlaybackSource: Codable, Equatable, Sendable {
  let playlistID: UUID
  let entryID: UUID
}

struct PlaybackContext: Codable, Equatable, Sendable {
  enum ArtistSource: String, Codable, Equatable, Sendable {
    case discography
    case topSongs
  }

  let identity: LibraryCollectionIdentity
  let title: String
  let artistSource: ArtistSource?

  init(
    identity: LibraryCollectionIdentity,
    title: String,
    artistSource: ArtistSource? = nil,
  ) {
    self.identity = identity
    self.title = title
    self.artistSource = artistSource
  }
}

enum PlaybackStartIntent: Equatable, Sendable {
  case collection
  case selectedEntry(index: Int)
}

struct PlaybackSource: Codable, Equatable, Sendable {
  struct Entry: Codable, Equatable, Identifiable, Sendable {
    typealias ID = Int

    let id: ID
    let item: PlaybackItem
  }

  let entries: [Entry]
  let selectedEntryID: Entry.ID
  let context: PlaybackContext?
  var removedEntryIDs: Set<Entry.ID>

  init(
    items: [PlaybackItem],
    selectedIndex: Int,
    context: PlaybackContext?,
    removedEntryIDs: Set<Entry.ID> = [],
  ) {
    precondition(items.indices.contains(selectedIndex))
    self.entries = items.enumerated().map { index, item in
      Entry(id: index, item: item.withQueueRole(nil))
    }
    self.selectedEntryID = self.entries[selectedIndex].id
    self.context = context
    self.removedEntryIDs = removedEntryIDs
  }

  var artistNames: Set<String> {
    Set(self.entries.map(\.item.artistName))
  }

  var isValid: Bool {
    !self.entries.isEmpty
      && Set(self.entries.map(\.id)).count == self.entries.count
      && self.entries.contains(where: { $0.id == self.selectedEntryID })
      && self.removedEntryIDs.isSubset(of: Set(self.entries.map(\.id)))
  }

  mutating func remove(_ entryID: Entry.ID) {
    guard self.entries.contains(where: { $0.id == entryID }) else { return }
    self.removedEntryIDs.insert(entryID)
  }

  mutating func removeTracks(notIn approvedTrackIDs: Set<ApprovedTrack.ID>) {
    self.removedEntryIDs.formUnion(
      self.entries.lazy.filter {
        !approvedTrackIDs.contains($0.item.id)
      }.map(\.id),
    )
  }
}

enum PlaybackQueueRole: String, Codable, Equatable, Sendable {
  case context
  case queued
}

struct PlaybackItem: Codable, Equatable, Identifiable, Sendable {
  let id: ApprovedTrack.ID
  let title: String
  let artistName: String
  let artworkURL: URL?
  let albumID: ApprovedAlbum.ID?
  let albumTitle: String?
  let duration: TimeInterval?
  let playlistSource: PlaylistPlaybackSource?
  let queueRole: PlaybackQueueRole?

  init(
    id: ApprovedTrack.ID,
    title: String,
    artistName: String,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
    albumTitle: String? = nil,
    duration: TimeInterval? = nil,
    playlistSource: PlaylistPlaybackSource? = nil,
    queueRole: PlaybackQueueRole? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkURL = artworkURL?.normalizedArtworkURL
    self.albumID = albumID
    self.albumTitle = albumTitle
    self.duration = duration
    self.playlistSource = playlistSource
    self.queueRole = queueRole
  }

  init(
    track: ApprovedTrack,
    artworkURL: URL?,
    albumID: ApprovedAlbum.ID? = nil,
  ) {
    self.init(
      id: track.id,
      title: track.title,
      artistName: track.artistName,
      artworkURL: artworkURL,
      albumID: albumID ?? track.albumID,
      albumTitle: track.albumTitle,
      duration: track.durationInMillis.map { TimeInterval($0) / 1000 },
    )
  }

  func withAlbumID(_ albumID: ApprovedAlbum.ID?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: self.playlistSource,
      queueRole: self.queueRole,
    )
  }

  func withArtworkURL(_ artworkURL: URL?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: self.playlistSource,
      queueRole: self.queueRole,
    )
  }

  func withPlaylistSource(_ playlistSource: PlaylistPlaybackSource?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: playlistSource,
      queueRole: self.queueRole,
    )
  }

  func withQueueRole(_ queueRole: PlaybackQueueRole?) -> Self {
    Self(
      id: self.id,
      title: self.title,
      artistName: self.artistName,
      artworkURL: self.artworkURL,
      albumID: self.albumID,
      albumTitle: self.albumTitle,
      duration: self.duration,
      playlistSource: self.playlistSource,
      queueRole: queueRole,
    )
  }
}

private extension URL {
  var normalizedArtworkURL: URL {
    guard self.scheme?.lowercased() == "musickit",
          let fallbackValue = URLComponents(
            url: self,
            resolvingAgainstBaseURL: false,
          )?.queryItems?.first(where: { $0.name == "fat" })?.value,
          let fallbackURL = URL(string: fallbackValue),
          ["http", "https"].contains(fallbackURL.scheme?.lowercased()) else { return self }
    return fallbackURL
  }
}

struct PlaybackQueueEntry: Equatable, Identifiable, Sendable {
  let id: String
  let item: PlaybackItem
  let sourceEntryID: PlaybackSource.Entry.ID?
  let viewID: String

  init(
    id: String,
    item: PlaybackItem,
    sourceEntryID: PlaybackSource.Entry.ID? = nil,
    viewID: String? = nil,
  ) {
    self.id = id
    self.item = item
    self.sourceEntryID = sourceEntryID
    self.viewID = viewID ?? id
  }

  var role: PlaybackQueueRole {
    self.item.queueRole ?? .queued
  }
}

enum PlaybackSourceQueuePlanEntry: Equatable, Sendable {
  case explicit(PlaybackQueueEntry)
  case generated(PlaybackItem)
  case source(PlaybackSource.Entry)

  var item: PlaybackItem {
    switch self {
    case .explicit(let entry):
      entry.item
    case .generated(let item):
      item.withQueueRole(.context)
    case .source(let entry):
      entry.item.withQueueRole(.context)
    }
  }

  var sourceEntryID: PlaybackSource.Entry.ID? {
    guard case .source(let entry) = self else { return nil }
    return entry.id
  }
}

enum InfinitePlaybackCandidatePlanner {
  struct Plan: Equatable, Sendable {
    let sourceEntries: [PlaybackSource.Entry]
    let relatedItems: [PlaybackItem]
    let otherItems: [PlaybackItem]
  }

  static func plan(
    source: PlaybackSource,
    library: ApprovedMusicLibrary,
  ) -> Plan? {
    guard source.isValid else { return nil }
    let retainedSourceEntries = source.entries.filter {
      !source.removedEntryIDs.contains($0.id)
    }
    guard let selectedIndex = retainedSourceEntries.firstIndex(where: {
      $0.id == source.selectedEntryID
    }) else { return nil }
    let sourceEntries = Array(retainedSourceEntries[selectedIndex...])
      + Array(retainedSourceEntries[..<selectedIndex])
    let sourceTrackIDs = Set(source.entries.map(\.item.id))
    let representedArtistNames = source.artistNames
    var relatedItems: [PlaybackItem] = []
    var otherItems: [PlaybackItem] = []

    for item in self.uniqueApprovedItems(in: library) {
      guard !sourceTrackIDs.contains(item.id) else { continue }
      if representedArtistNames.contains(item.artistName) {
        relatedItems.append(item)
      } else {
        otherItems.append(item)
      }
    }

    return Plan(
      sourceEntries: sourceEntries,
      relatedItems: relatedItems,
      otherItems: otherItems,
    )
  }

  static func randomizedInitialPlan(
    _ plan: Plan,
    shuffle: (inout [PlaybackItem]) -> Void,
  ) -> Plan {
    var relatedItems = plan.relatedItems
    var otherItems = plan.otherItems
    if relatedItems.count > 1 {
      shuffle(&relatedItems)
    }
    if otherItems.count > 1 {
      shuffle(&otherItems)
    }
    return Plan(
      sourceEntries: plan.sourceEntries,
      relatedItems: relatedItems,
      otherItems: otherItems,
    )
  }

  static func libraryCycleItems(
    library: ApprovedMusicLibrary,
    avoidingFirstTrackID: ApprovedTrack.ID?,
    shuffle: (inout [PlaybackItem]) -> Void,
  ) -> [PlaybackItem] {
    var items = self.uniqueApprovedItems(in: library)
    shuffle(&items)
    if let avoidingFirstTrackID,
       items.first?.id == avoidingFirstTrackID,
       let replacementIndex = items.firstIndex(where: {
         $0.id != avoidingFirstTrackID
       }) {
      items.swapAt(items.startIndex, replacementIndex)
    }
    return items
  }

  static func uniqueApprovedItems(
    in library: ApprovedMusicLibrary,
  ) -> [PlaybackItem] {
    var trackIDs = Set<ApprovedTrack.ID>()
    return library.albums.flatMap { album in
      album.tracks.compactMap { track in
        guard trackIDs.insert(track.id).inserted else { return nil }
        return PlaybackItem(
          track: track,
          artworkURL: album.artworkURL,
          albumID: album.id,
        )
      }
    }
  }
}

struct InfinitePlaybackPlan: Codable, Equatable, Sendable {
  var remainingSourceEntryIDs: [PlaybackSource.Entry.ID]
  var generatedItems: [PlaybackItem]
}

enum InfinitePlaybackLookaheadEntry: Equatable, Sendable {
  case source(PlaybackSource.Entry)
  case generated(PlaybackItem)

  var item: PlaybackItem {
    switch self {
    case .source(let entry):
      entry.item.withQueueRole(.context)
    case .generated(let item):
      item.withQueueRole(.context)
    }
  }

  var sourceEntryID: PlaybackSource.Entry.ID? {
    guard case .source(let entry) = self else { return nil }
    return entry.id
  }
}

enum InfinitePlaybackLookaheadPlanner {
  static func entries(
    remainingSourceEntries: [PlaybackSource.Entry],
    generatedItems: [PlaybackItem],
    approvedUniqueTrackCount: Int,
  ) -> [InfinitePlaybackLookaheadEntry] {
    let targetCount = min(10, max(0, approvedUniqueTrackCount))
    let sourceEntries = remainingSourceEntries.prefix(targetCount)
    let generatedCount = targetCount - sourceEntries.count
    return sourceEntries.map(InfinitePlaybackLookaheadEntry.source)
      + generatedItems.prefix(generatedCount).map(InfinitePlaybackLookaheadEntry.generated)
  }

  static func replenishedGeneratedItems(
    remainingSourceEntries: [PlaybackSource.Entry],
    generatedItems: [PlaybackItem],
    library: ApprovedMusicLibrary,
    previousTrackID: ApprovedTrack.ID?,
    additionalVisibleTrackIDs: Set<ApprovedTrack.ID> = [],
    shuffle: (inout [PlaybackItem]) -> Void,
  ) -> [PlaybackItem] {
    let targetCount = min(10, library.approvedTrackIDs.count)
    let visibleSourceEntries = remainingSourceEntries.prefix(targetCount)
    let generatedTargetCount = targetCount - visibleSourceEntries.count
    guard generatedItems.count < generatedTargetCount else { return generatedItems }

    var visibleTrackIDs = additionalVisibleTrackIDs
    visibleTrackIDs.formUnion(visibleSourceEntries.map(\.item.id))
    visibleTrackIDs.formUnion(
      generatedItems.prefix(generatedTargetCount).map(\.id),
    )
    let cycleItems = InfinitePlaybackCandidatePlanner.libraryCycleItems(
      library: library,
      avoidingFirstTrackID: previousTrackID,
      shuffle: shuffle,
    )
    let nonconflictingItems = cycleItems.filter {
      $0.id != previousTrackID && !visibleTrackIDs.contains($0.id)
    }
    let previousItems = cycleItems.filter {
      $0.id == previousTrackID && !visibleTrackIDs.contains($0.id)
    }
    let conflictingItems = cycleItems.filter {
      visibleTrackIDs.contains($0.id)
    }
    return generatedItems + nonconflictingItems + previousItems + conflictingItems
  }
}

enum PlaybackSourceQueuePlanner {
  enum Start: Equatable, Sendable {
    case collection
    case selectedEntry
  }

  static func startingEntries(
    source: PlaybackSource,
    start: Start,
    explicitEntries: [PlaybackQueueEntry],
    isShuffleEnabled: Bool,
    shuffle: (inout [PlaybackSource.Entry]) -> Void,
  ) -> [PlaybackSourceQueuePlanEntry]? {
    guard source.isValid else { return nil }
    var sourceEntries = source.entries.filter {
      !source.removedEntryIDs.contains($0.id)
    }

    switch start {
    case .collection:
      if isShuffleEnabled {
        shuffle(&sourceEntries)
      }

    case .selectedEntry:
      guard let selectedIndex = sourceEntries.firstIndex(where: {
        $0.id == source.selectedEntryID
      }) else { return nil }
      if isShuffleEnabled {
        let selectedEntry = sourceEntries.remove(at: selectedIndex)
        shuffle(&sourceEntries)
        sourceEntries.insert(selectedEntry, at: 0)
      } else {
        sourceEntries = Array(sourceEntries[selectedIndex...])
      }
    }

    guard let currentEntry = sourceEntries.first else { return nil }
    return [.source(currentEntry)]
      + explicitEntries.map { .explicit($0) }
      + sourceEntries.dropFirst().map { .source($0) }
  }

  static func sourceCycleEntries(
    source: PlaybackSource,
    isShuffleEnabled: Bool,
    avoidingFirstTrackID: ApprovedTrack.ID?,
    shuffle: (inout [PlaybackSource.Entry]) -> Void,
  ) -> [PlaybackSource.Entry]? {
    guard source.isValid else { return nil }
    var entries = source.entries.filter {
      !source.removedEntryIDs.contains($0.id)
    }
    guard !entries.isEmpty else { return nil }
    if isShuffleEnabled {
      shuffle(&entries)
      if let avoidingFirstTrackID,
         entries.first?.item.id == avoidingFirstTrackID,
         let replacementIndex = entries.firstIndex(where: {
           $0.item.id != avoidingFirstTrackID
         }) {
        entries.swapAt(entries.startIndex, replacementIndex)
      }
    }
    return entries
  }

  static func sourceCycleEntries(
    source: PlaybackSource,
    entryIDs: [PlaybackSource.Entry.ID],
  ) -> [PlaybackSource.Entry]? {
    guard source.isValid else { return nil }
    let retainedEntries = source.entries.filter {
      !source.removedEntryIDs.contains($0.id)
    }
    let entries = self.remainingSourceEntries(
      source: source,
      entryIDs: entryIDs,
    )
    guard !entries.isEmpty,
          entries.count == retainedEntries.count,
          Set(entries.map(\.id)) == Set(retainedEntries.map(\.id)) else { return nil }
    return entries
  }

  static func upcomingEntries(
    source: PlaybackSource,
    remainingSourceEntryIDs: [PlaybackSource.Entry.ID],
    explicitEntries: [PlaybackQueueEntry],
    isShuffleEnabled: Bool,
    shuffle: (inout [PlaybackSource.Entry]) -> Void,
  ) -> [PlaybackSourceQueuePlanEntry] {
    guard source.isValid else {
      return explicitEntries.map { .explicit($0) }
    }
    var sourceEntries = self.remainingSourceEntries(
      source: source,
      entryIDs: remainingSourceEntryIDs,
    )
    if isShuffleEnabled {
      shuffle(&sourceEntries)
    } else {
      let remainingEntryIDs = Set(sourceEntries.map(\.id))
      sourceEntries = source.entries.filter {
        remainingEntryIDs.contains($0.id)
      }
    }
    return explicitEntries.map { .explicit($0) }
      + sourceEntries.map { .source($0) }
  }

  private static func remainingSourceEntries(
    source: PlaybackSource,
    entryIDs: [PlaybackSource.Entry.ID],
  ) -> [PlaybackSource.Entry] {
    let entriesByID = Dictionary(
      uniqueKeysWithValues: source.entries.map { ($0.id, $0) },
    )
    var retainedEntryIDs: Set<PlaybackSource.Entry.ID> = []
    return entryIDs.compactMap { entryID in
      guard retainedEntryIDs.insert(entryID).inserted,
            !source.removedEntryIDs.contains(entryID) else { return nil }
      return entriesByID[entryID]
    }
  }
}

enum PlaybackQueueInsertionPosition: Equatable, Sendable {
  case next
  case tail
}

enum PlaybackQueueInsertionTarget: Equatable, Sendable {
  case before(PlaybackQueueEntry)
  case next
  case tail
}

struct PlaybackSnapshot: Equatable, Sendable {
  let entries: [PlaybackQueueEntry]
  let currentEntryID: String?
  let playStatus: PlaybackFeature.PlayStatus
  let progress: PlaybackProgress

  static let empty = Self(
    entries: [],
    currentEntryID: nil,
    playStatus: .paused,
    progress: .zero,
  )

  func hasSameSession(as other: Self) -> Bool {
    self.entries == other.entries
      && self.currentEntryID == other.currentEntryID
      && self.playStatus == other.playStatus
  }
}

enum PlaybackMetadataHintMatcher {
  struct Occurrence: Equatable, Sendable {
    var item: PlaybackItem
    var retainedEntryID: PlaybackQueueEntry.ID?
    var sourceEntryID: PlaybackSource.Entry.ID?

    init(
      item: PlaybackItem,
      retainedEntryID: PlaybackQueueEntry.ID? = nil,
      sourceEntryID: PlaybackSource.Entry.ID? = nil,
    ) {
      self.item = item
      self.retainedEntryID = retainedEntryID
      self.sourceEntryID = sourceEntryID
    }
  }

  static func match(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:],
  ) -> [PlaybackQueueEntry.ID: PlaylistPlaybackSource] {
    self.match(
      plan: plan,
      entries: entries,
      existing: existing,
      value: { $0.playlistSource },
    )
  }

  static func match<Value>(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: Value] = [:],
    value: (PlaybackItem) -> Value?,
  ) -> [PlaybackQueueEntry.ID: Value] {
    self.match(
      plan: plan,
      entries: entries,
      existing: existing,
      occurrenceValue: { value($0.item) },
    )
  }

  static func matchSourceEntries(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: PlaybackSource.Entry.ID] = [:],
  ) -> [PlaybackQueueEntry.ID: PlaybackSource.Entry.ID] {
    self.match(
      plan: plan,
      entries: entries,
      existing: existing,
      occurrenceValue: \.sourceEntryID,
    )
  }

  static func hasMaterializedAllRequiredMetadata(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
  ) -> Bool {
    let matchedOccurrenceIndices = Set(self.alignment(plan: plan, entries: entries).values)
    return plan.indices.allSatisfy { index in
      let occurrence = plan[index]
      guard occurrence.retainedEntryID == nil,
            occurrence.item.albumID != nil
            || occurrence.item.artworkURL != nil
            || occurrence.item.playlistSource != nil
            || occurrence.item.queueRole != nil
            || occurrence.sourceEntryID != nil else { return true }
      return matchedOccurrenceIndices.contains(index)
    }
  }

  private static func match<Value>(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
    existing: [PlaybackQueueEntry.ID: Value],
    occurrenceValue: (Occurrence) -> Value?,
  ) -> [PlaybackQueueEntry.ID: Value] {
    let currentEntryIDs = Set(entries.map(\.id))
    var matched = existing.filter { currentEntryIDs.contains($0.key) }
    for (entryID, occurrenceIndex) in self.alignment(plan: plan, entries: entries) {
      matched[entryID] = occurrenceValue(plan[occurrenceIndex])
    }
    return matched
  }

  private static func alignment(
    plan: [Occurrence],
    entries: [PlaybackQueueEntry],
  ) -> [PlaybackQueueEntry.ID: Int] {
    let entriesByID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    var matchedOccurrenceByEntryID: [PlaybackQueueEntry.ID: Int] = [:]
    var matchedOccurrenceIndices = Set<Int>()

    for index in plan.indices {
      let occurrence = plan[index]
      guard let retainedEntryID = occurrence.retainedEntryID,
            let entry = entriesByID[retainedEntryID],
            entry.item.id == occurrence.item.id else { continue }
      matchedOccurrenceByEntryID[retainedEntryID] = index
      matchedOccurrenceIndices.insert(index)
    }

    var nextOccurrenceIndex = plan.startIndex
    for entry in entries where matchedOccurrenceByEntryID[entry.id] == nil {
      guard let occurrenceIndex = (nextOccurrenceIndex ..< plan.endIndex).first(where: {
        !matchedOccurrenceIndices.contains($0)
          && plan[$0].item.id == entry.item.id
      }) else { continue }
      matchedOccurrenceByEntryID[entry.id] = occurrenceIndex
      matchedOccurrenceIndices.insert(occurrenceIndex)
      nextOccurrenceIndex = plan.index(after: occurrenceIndex)
    }

    return matchedOccurrenceByEntryID
  }
}
