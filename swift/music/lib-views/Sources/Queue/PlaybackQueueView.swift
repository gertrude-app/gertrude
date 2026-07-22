import Foundation
import SwiftUI

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

public struct PlaybackQueueView: View {
  private let currentEntry: PlaybackQueueEntryData
  private let upcomingEntries: [PlaybackQueueEntryData]
  private let onClearUpcoming: @MainActor @Sendable () -> Void
  private let onRemove: @MainActor @Sendable (String) -> Void
  private let onReorder: @MainActor @Sendable ([String]) -> Void

  public init(
    currentEntry: PlaybackQueueEntryData,
    upcomingEntries: [PlaybackQueueEntryData],
    onClearUpcoming: @MainActor @escaping @Sendable () -> Void = {},
    onRemove: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReorder: @MainActor @escaping @Sendable ([String]) -> Void = { _ in },
  ) {
    self.currentEntry = currentEntry
    self.upcomingEntries = upcomingEntries
    self.onClearUpcoming = onClearUpcoming
    self.onRemove = onRemove
    self.onReorder = onReorder
  }

  public var body: some View {
    List {
      Section("Now Playing") {
        PlaybackQueueRow(entry: self.currentEntry, isCurrent: true)
      }

      if !self.upcomingEntries.isEmpty {
        Section("Up Next") {
          ForEach(self.upcomingEntries) { entry in
            PlaybackQueueRow(entry: entry, isCurrent: false)
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
          }
          .onMove(perform: self.move)
        }
      }
    }
    .navigationTitle("Queue")
    .tint(.primary)
    .toolbar {
      if !self.upcomingEntries.isEmpty {
        Button("Clear", role: .destructive, action: self.onClearUpcoming)
          .tint(.red)
      }
    }
  }

  private func move(fromOffsets: IndexSet, toOffset: Int) {
    var entryIDs = self.upcomingEntries.map(\.id)
    entryIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
    self.onReorder(entryIDs)
  }
}

private struct PlaybackQueueRow: View {
  let entry: PlaybackQueueEntryData
  let isCurrent: Bool

  var body: some View {
    HStack(spacing: 12) {
      CachedArtworkImageView(url: self.entry.artworkURL) { image in
        image
          .resizable()
          .scaledToFill()
          .frame(width: 44, height: 44)
          .clipShape(.rect(cornerRadius: 8, style: .continuous))
      } placeholder: {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.gertrudeBrandAccent.opacity(0.14))
          .frame(width: 44, height: 44)
          .overlay {
            Image(systemName: "music.note")
              .foregroundStyle(Color.gertrudeBrandAccent)
          }
      }
      .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 3) {
        Text(self.entry.title)
          .font(.body.weight(self.isCurrent ? .semibold : .regular))
          .lineLimit(2)

        Text(self.entry.artist)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 0)

      if self.isCurrent {
        Image(systemName: "speaker.wave.2.fill")
          .foregroundStyle(Color.gertrudeBrandAccent)
          .accessibilityHidden(true)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      self.isCurrent
        ? "Now playing, \(self.entry.title), \(self.entry.artist)"
        : "\(self.entry.title), \(self.entry.artist)",
    )
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
        upcomingEntries: [
          .init(id: "next-1", title: "Vintergatan", artist: "Spöket i Köket", artworkURL: nil),
          .init(id: "next-2", title: "Medvind", artist: "Spöket i Köket", artworkURL: nil),
        ],
      )
    }
  }
#endif
