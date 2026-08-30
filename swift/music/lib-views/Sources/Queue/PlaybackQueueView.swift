import Foundation
import GertieUI
import OSLog
import SwiftUI

private let queueArtworkLogger = Logger(
  subsystem: "com.netrivet.gertrude.music",
  category: "QueueArtwork",
)

public struct PlaybackQueueEntryData: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkURL: URL?

  public init(
    id: String,
    title: String,
    artist: String,
    artworkURL: URL?,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkURL = artworkURL
  }
}

public struct PlaybackQueueOrder: Equatable, Sendable {
  public let entryIDs: [String]
  public let queuedEntryCount: Int

  public init(
    entryIDs: [String],
    queuedEntryCount: Int,
  ) {
    self.entryIDs = entryIDs
    self.queuedEntryCount = queuedEntryCount
  }
}

public struct PlaybackQueueView: View {
  private let currentEntry: PlaybackQueueEntryData
  private let isPlaying: Bool
  private let hasQueuedEntries: Bool
  private let rows: [PlaybackQueueListRow]
  private let displayRows: [PlaybackQueueDisplayRow]
  private let onClearQueue: @MainActor @Sendable () -> Void
  private let onRemove: @MainActor @Sendable (String) -> Void
  private let onReorder: @MainActor @Sendable (PlaybackQueueOrder) -> Void

  public init(
    currentEntry: PlaybackQueueEntryData,
    queuedEntries: [PlaybackQueueEntryData],
    contextTitle: String?,
    contextEntries: [PlaybackQueueEntryData],
    isPlaying: Bool = false,
    onClearQueue: @MainActor @escaping @Sendable () -> Void = {},
    onRemove: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReorder: @MainActor @escaping @Sendable (PlaybackQueueOrder) -> Void = { _ in },
  ) {
    let rows = PlaybackQueueListRow.makeRows(
      queuedEntries: queuedEntries,
      contextTitle: contextTitle,
      contextEntries: contextEntries,
    )
    self.currentEntry = currentEntry
    self.isPlaying = isPlaying
    self.hasQueuedEntries = !queuedEntries.isEmpty
    self.rows = rows
    self.displayRows = PlaybackQueueDisplayRow.makeRows(
      PlaybackQueueListRow.visibleRows(rows),
    )
    self.onClearQueue = onClearQueue
    self.onRemove = onRemove
    self.onReorder = onReorder
  }

  public var body: some View {
    List {
      PlaybackQueueSectionHeader(title: "Now Playing")
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

      PlaybackQueueRow(
        entry: self.currentEntry,
        number: nil,
        isCurrent: true,
        isPlaying: self.isPlaying,
      )
      .equatable()
      .listRowInsets(EdgeInsets())
      .listRowSeparator(.hidden)
      .listRowBackground(Color.clear)

      if !self.displayRows.isEmpty {
        if self.hasQueuedEntries {
          PlaybackQueueSectionHeader(title: "Next in queue")
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }

        ForEach(self.displayRows) { displayRow in
          switch displayRow.row {
          case .contextHeader(let title):
            PlaybackQueueSectionHeader(title: "Next from: \(title)")
              .listRowInsets(EdgeInsets())
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)

          case .entry(let entry):
            PlaybackQueueRow(
              entry: entry,
              number: displayRow.number,
              isCurrent: false,
              isPlaying: false,
            )
            .equatable()
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                self.onRemove(entry.id)
              } label: {
                Label("Remove from Queue", systemImage: "trash")
                  .labelStyle(.iconOnly)
              }
              .tint(.red)
              .accessibilityLabel("Remove from Queue")
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
        }
        .onMove(perform: self.move)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(.background)
    .navigationTitle("Queue")
    .tint(.primary)
    .toolbar {
      if self.hasQueuedEntries {
        Button(role: .destructive, action: self.onClearQueue) {
          Label("Clear queue", systemImage: "trash")
        }
        .tint(.primary)
      }
    }
    .task(id: self.missingArtworkDiagnostic) {
      guard !self.missingArtworkDiagnostic.isEmpty else { return }
      queueArtworkLogger.notice(
        "Queue entries missing artwork metadata: \(self.missingArtworkDiagnostic, privacy: .public)",
      )
    }
  }

  private var missingArtworkDiagnostic: String {
    ([self.currentEntry] + self.rows.compactMap { row in
      guard case .entry(let entry) = row else { return nil }
      return entry
    })
    .filter { $0.artworkURL == nil }
    .map { "\($0.id)|\($0.title)|\($0.artist)" }
    .joined(separator: "; ")
  }

  private func move(fromOffsets: IndexSet, toOffset: Int) {
    guard let order = PlaybackQueueListRow.order(
      rows: self.rows,
      moving: fromOffsets,
      toOffset: toOffset,
    ) else { return }
    self.onReorder(order)
  }
}

enum PlaybackQueueListRow: Equatable, Identifiable {
  private static let maximumVisibleContextEntries = 10

  enum ID: Hashable {
    case contextHeader
    case entry(String)
  }

  case contextHeader(String)
  case entry(PlaybackQueueEntryData)

  var id: ID {
    switch self {
    case .contextHeader:
      .contextHeader
    case .entry(let entry):
      .entry(entry.id)
    }
  }

  static func makeRows(
    queuedEntries: [PlaybackQueueEntryData],
    contextTitle: String?,
    contextEntries: [PlaybackQueueEntryData],
  ) -> [Self] {
    var rows = queuedEntries.map(Self.entry)
    if !contextEntries.isEmpty {
      rows.append(.contextHeader(contextTitle ?? "Your selection"))
      rows.append(contentsOf: contextEntries.map(Self.entry))
    }
    return rows
  }

  static func visibleRows(_ rows: [Self]) -> [Self] {
    guard let contextHeaderIndex = rows.firstIndex(where: {
      if case .contextHeader = $0 { return true }
      return false
    }) else { return rows }
    return Array(rows.prefix(
      contextHeaderIndex + 1 + Self.maximumVisibleContextEntries,
    ))
  }

  static func order(
    rows: [Self],
    moving offsets: IndexSet,
    toOffset: Int,
  ) -> PlaybackQueueOrder? {
    guard !offsets.isEmpty,
          (0 ... rows.count).contains(toOffset),
          offsets.allSatisfy({ offset in
            guard rows.indices.contains(offset), case .entry = rows[offset] else { return false }
            return true
          }) else { return nil }
    var reorderedRows = rows
    reorderedRows.move(fromOffsets: offsets, toOffset: toOffset)
    let contextStartIndex = reorderedRows.firstIndex(where: {
      if case .contextHeader = $0 { return true }
      return false
    }) ?? reorderedRows.endIndex
    return PlaybackQueueOrder(
      entryIDs: reorderedRows.compactMap(\.entryID),
      queuedEntryCount: reorderedRows[..<contextStartIndex].compactMap(\.entryID).count,
    )
  }

  private var entryID: String? {
    guard case .entry(let entry) = self else { return nil }
    return entry.id
  }
}

private struct PlaybackQueueDisplayRow: Identifiable {
  let row: PlaybackQueueListRow
  let number: String?

  var id: PlaybackQueueListRow.ID { self.row.id }

  static func makeRows(_ rows: [PlaybackQueueListRow]) -> [Self] {
    var entryNumber = 0
    return rows.map { row in
      switch row {
      case .contextHeader:
        return Self(row: row, number: nil)
      case .entry:
        entryNumber += 1
        return Self(row: row, number: String(entryNumber))
      }
    }
  }
}

private struct PlaybackQueueSectionHeader: View {
  let title: String

  var body: some View {
    Text(self.title)
      .font(.title3.weight(.bold))
      .foregroundStyle(.primary)
      .accessibilityAddTraits(.isHeader)
      .padding(.horizontal, 20)
      .frame(maxWidth: 800, alignment: .leading)
      .frame(maxWidth: .infinity)
      .padding(.top, 28)
      .padding(.bottom, 8)
  }
}

private struct PlaybackQueueRow: Equatable, View {
  let entry: PlaybackQueueEntryData
  let number: String?
  let isCurrent: Bool
  let isPlaying: Bool

  var body: some View {
    TrackRowView(
      number: self.number,
      track: TrackData(
        id: self.entry.id,
        title: self.entry.title,
        artist: self.entry.artist,
        artworkUrl: self.entry.artworkURL,
      ),
      showsArtwork: true,
      isCurrent: self.isCurrent,
      isPlaying: self.isPlaying,
      palette: nil,
      retainsPreviousArtwork: true,
    )
    .frame(maxWidth: 800)
    .frame(maxWidth: .infinity)
  }
}

#if DEBUG
  #Preview("Queue") {
    NavigationStack {
      PlaybackQueueView(
        currentEntry: .init(
          id: "current",
          title: "Ninos vaggvisa",
          artist: "Spöket i Köket",
          artworkURL: nil,
        ),
        queuedEntries: [
          .init(id: "queued-1", title: "Vintergatan", artist: "Spöket i Köket", artworkURL: nil),
          .init(id: "queued-2", title: "Medvind", artist: "Spöket i Köket", artworkURL: nil),
        ],
        contextTitle: "Mångata",
        contextEntries: [
          .init(id: "context-1", title: "Månskensvisa", artist: "Spöket i Köket", artworkURL: nil),
          .init(id: "context-2", title: "Polska", artist: "Spöket i Köket", artworkURL: nil),
        ],
        isPlaying: true,
      )
    }
  }
#endif
