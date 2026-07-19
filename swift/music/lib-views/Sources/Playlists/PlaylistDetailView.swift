import SwiftUI

public struct PlaylistDetailView: View {
  private let playlist: PlaylistData
  private let isPlaying: Bool
  private let isLoading: Bool
  private let currentEntryID: String?
  private let isMutating: Bool
  private let onAddMusicTap: @MainActor @Sendable () -> Void
  private let onAddToQueue: @MainActor @Sendable () -> Void
  private let onDelete: @MainActor @Sendable () -> Void
  private let onPlayNext: @MainActor @Sendable () -> Void
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onRemoveEntry: @MainActor @Sendable (String) -> Void
  private let onRename: @MainActor @Sendable (String) -> Void
  private let onReorder: @MainActor @Sendable ([String]) -> Void
  private let onTrackAddToPlaylist: @MainActor @Sendable (String) -> Void
  private let onTrackAddToQueue: @MainActor @Sendable (String) -> Void
  private let onTrackPlayNext: @MainActor @Sendable (String) -> Void
  private let onTrackTap: @MainActor @Sendable (String) -> Void

  @State private var isDeleteConfirmationPresented = false
  @State private var isRenamePromptPresented = false
  @State private var renameText = ""

  public init(
    playlist: PlaylistData,
    isPlaying: Bool = false,
    isLoading: Bool = false,
    currentEntryID: String? = nil,
    isMutating: Bool = false,
    onAddMusicTap: @MainActor @escaping @Sendable () -> Void = {},
    onAddToQueue: @MainActor @escaping @Sendable () -> Void = {},
    onDelete: @MainActor @escaping @Sendable () -> Void = {},
    onPlayNext: @MainActor @escaping @Sendable () -> Void = {},
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onRemoveEntry: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onRename: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReorder: @MainActor @escaping @Sendable ([String]) -> Void = { _ in },
    onTrackAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackAddToQueue: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackPlayNext: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.playlist = playlist
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.currentEntryID = currentEntryID
    self.isMutating = isMutating
    self.onAddMusicTap = onAddMusicTap
    self.onAddToQueue = onAddToQueue
    self.onDelete = onDelete
    self.onPlayNext = onPlayNext
    self.onPlayTap = onPlayTap
    self.onRemoveEntry = onRemoveEntry
    self.onRename = onRename
    self.onReorder = onReorder
    self.onTrackAddToPlaylist = onTrackAddToPlaylist
    self.onTrackAddToQueue = onTrackAddToQueue
    self.onTrackPlayNext = onTrackPlayNext
    self.onTrackTap = onTrackTap
  }

  public var body: some View {
    GeometryReader { proxy in
      List {
        self.heroContent(containerWidth: proxy.size.width)
          .frame(maxWidth: .infinity)
          .padding(.top, proxy.safeAreaInsets.top + 18)
          .padding(.bottom, 30)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)

        if self.playlist.entries.isEmpty {
          self.emptyContent
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
          ForEach(Array(self.playlist.entries.enumerated()), id: \.element.id) { index, entry in
            PlaylistTrackRowView(
              number: index + 1,
              entry: entry,
              isCurrent: entry.id == self.currentEntryID,
              isPlaying: self.isPlaying && entry.id == self.currentEntryID,
              onTap: { self.onTrackTap(entry.id) },
            )
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
            .playbackQueueContextMenu(
              onPlayNext: { self.onTrackPlayNext(entry.id) },
              onAddToQueue: { self.onTrackAddToQueue(entry.id) },
              onAddToPlaylist: { self.onTrackAddToPlaylist(entry.id) },
            )
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                self.onRemoveEntry(entry.id)
              } label: {
                Label("Remove from Playlist", systemImage: "trash")
                  .labelStyle(.iconOnly)
              }
              .tint(.red)
              .disabled(self.isMutating)
              .accessibilityLabel("Remove from Playlist")
            }
            .moveDisabled(self.isMutating)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }
          .onMove(perform: self.move)
        }

        Color.clear
          .frame(height: 112)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .accessibilityHidden(true)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(.background)
      .ignoresSafeArea(edges: .top)
    }
    .navigationTitle("")
    .detailNavigationBarBackground()
    .toolbar {
      ToolbarItem(placement: self.menuPlacement) {
        if self.isMutating {
          ProgressView()
            .controlSize(.small)
            .tint(.primary)
            .accessibilityLabel("Saving playlist")
        } else {
          Menu {
            Button(action: self.onPlayNext) {
              Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.primary)
            .disabled(self.playlist.entries.isEmpty)

            Button(action: self.onAddToQueue) {
              Label("Add to Queue", systemImage: "text.badge.plus")
            }
            .tint(.primary)
            .disabled(self.playlist.entries.isEmpty)

            Divider()

            Button(action: self.renameButtonTapped) {
              Label("Rename Playlist", systemImage: "pencil")
            }
            .tint(.primary)

            Button(role: .destructive) {
              self.isDeleteConfirmationPresented = true
            } label: {
              Label("Delete Playlist", systemImage: "trash")
            }
            .tint(.red)
          } label: {
            Label("Playlist Actions", systemImage: "ellipsis")
          }
          .tint(.primary)
        }
      }
    }
    .alert("Rename Playlist", isPresented: self.$isRenamePromptPresented) {
      TextField("Playlist Name", text: self.$renameText)
        .onSubmit(self.renamePromptSubmitted)
      Button("Cancel", role: .cancel, action: self.renamePromptCancelled)
        .tint(.primary)
      Button("Save", action: self.renamePromptSubmitted)
        .tint(.white)
        .keyboardShortcut(.defaultAction)
        .disabled(!self.renameText.isValidPlaylistName)
    } message: {
      Text("Enter a new name for this playlist.")
    }
    .alert("Delete “\(self.playlist.name)”?", isPresented: self.$isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive, action: self.onDelete)
    } message: {
      Text("This removes the playlist, but not its approved music.")
    }
  }

  private var menuPlacement: ToolbarItemPlacement {
    #if os(iOS)
      .topBarTrailing
    #else
      .automatic
    #endif
  }

  private func renameButtonTapped() {
    self.renameText = self.playlist.name
    self.isRenamePromptPresented = true
  }

  private func renamePromptCancelled() {
    self.isRenamePromptPresented = false
  }

  private func renamePromptSubmitted() {
    guard self.renameText.isValidPlaylistName else { return }
    self.isRenamePromptPresented = false
    self.onRename(self.renameText)
  }

  @ViewBuilder
  private func heroContent(containerWidth: CGFloat) -> some View {
    if containerWidth >= 800 {
      let artworkSize = min(300, max(220, (containerWidth - 96) * 0.38))
      HStack(spacing: 36) {
        PlaylistArtworkView(
          playlist: self.playlist,
          size: artworkSize,
          cornerRadius: 16,
        )

        VStack(spacing: 18) {
          self.metadata
          self.playButton
            .frame(maxWidth: 440)
        }
        .frame(maxWidth: 440)
      }
      .frame(maxWidth: 900)
      .padding(.horizontal, 32)
    } else {
      VStack(spacing: 16) {
        PlaylistArtworkView(
          playlist: self.playlist,
          size: max(1, min(320, containerWidth - 64)),
          cornerRadius: 16,
        )

        self.metadata
          .frame(maxWidth: 560)
          .padding(.horizontal, 28)

        self.playButton
          .frame(maxWidth: 520)
          .padding(.horizontal, 20)
          .padding(.top, 4)
      }
    }
  }

  private var metadata: some View {
    VStack(spacing: 5) {
      Text(self.playlist.name)
        .font(.system(size: 26, weight: .bold, design: .rounded))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(3)

      Text(self.trackCountText)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.secondary)
    }
  }

  private var playButton: some View {
    AlbumDetailPlayButton(
      isPlaying: self.isPlaying,
      isLoading: self.isLoading,
      palette: nil,
      colorOverride: .init(
        background: .gertrudeBrandAccent,
        foreground: .white,
      ),
      onTap: self.onPlayTap,
    )
    .disabled(self.playlist.entries.isEmpty)
    .opacity(self.playlist.entries.isEmpty ? 0.55 : 1)
  }

  private var emptyContent: some View {
    VStack(spacing: 12) {
      Image(systemName: "music.note.list")
        .font(.system(size: 28, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("This playlist is empty")
        .font(.headline)

      Text("Add approved songs or albums from your library.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Browse Library", action: self.onAddMusicTap)
        .buttonStyle(.borderedProminent)
        .tint(Color.gertrudeBrandAccent)
    }
    .padding(28)
    .frame(maxWidth: .infinity)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
  }

  private var trackCountText: String {
    self.playlist.trackCount == 1 ? "1 song" : "\(self.playlist.trackCount) songs"
  }

  private func move(fromOffsets: IndexSet, toOffset: Int) {
    guard !self.isMutating else { return }
    var entryIDs = self.playlist.entries.map(\.id)
    entryIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
    self.onReorder(entryIDs)
  }
}

#if DEBUG
  #Preview("Playlist detail") {
    NavigationStack {
      PlaylistDetailView(playlist: .previewRoadTrip)
    }
  }

  #Preview("Playlist detail playing duplicate") {
    NavigationStack {
      PlaylistDetailView(
        playlist: .previewRoadTrip,
        isPlaying: true,
        currentEntryID: "entry-3",
      )
    }
  }

  #Preview("Empty playlist") {
    NavigationStack {
      PlaylistDetailView(playlist: .init(id: "empty", name: "New Playlist"))
    }
  }
#endif

private struct PlaylistTrackRowView: View {
  let number: Int
  let entry: PlaylistEntryData
  let isCurrent: Bool
  let isPlaying: Bool
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 12) {
        Group {
          if self.isCurrent {
            PlaybackWaveformView(
              isPlaying: self.isPlaying,
              color: .gertrudeBrandAccent,
              barCount: 4,
              barWidth: 3,
              barSpacing: 2,
              minimumBarHeight: 4,
              maximumBarHeight: 16,
              containerWidth: 24,
              containerHeight: 24,
              alignment: .center,
              phaseStep: 0.85,
              minimumInterval: nil,
            )
          } else {
            Text(self.number, format: .number)
              .font(.system(size: 14, weight: .semibold, design: .rounded))
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
        .frame(width: 24, alignment: .trailing)

        PlaylistTrackArtworkView(url: self.entry.track.artworkUrl)

        VStack(alignment: .leading, spacing: 3) {
          Text(self.entry.track.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(self.isCurrent ? Color.gertrudeBrandAccent : .primary)
            .lineLimit(2)

          Text(self.entry.track.artist)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background {
        if self.isCurrent {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.gertrudeBrandAccent.opacity(0.10))
            .padding(.horizontal, 10)
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      "\(self.playbackPrefix)\(self.number). \(self.entry.track.title), \(self.entry.track.artist)",
    )
  }

  private var playbackPrefix: String {
    if self.isPlaying { return "Playing, " }
    if self.isCurrent { return "Paused, " }
    return ""
  }
}

private struct PlaylistTrackArtworkView: View {
  let url: URL?

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
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
  }
}
