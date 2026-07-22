import SwiftUI

public enum PlaylistDuplicatePrompt: Equatable, Sendable {
  case album(playlistName: String, duplicateCount: Int)
  case track(trackTitle: String, playlistName: String)
}

public enum PlaylistDuplicateChoice: Equatable, Sendable {
  case addAgain
  case addAll
  case addOnlyNew
}

struct PlaylistNamePrompt: View {
  @Binding private var name: String
  @FocusState private var isNameFocused: Bool

  private let title: String
  private let actionTitle: String
  private let onCancel: @MainActor @Sendable () -> Void
  private let onSubmit: @MainActor @Sendable () -> Void

  init(
    title: String,
    actionTitle: String,
    name: Binding<String>,
    onCancel: @MainActor @escaping @Sendable () -> Void,
    onSubmit: @MainActor @escaping @Sendable () -> Void,
  ) {
    self.title = title
    self.actionTitle = actionTitle
    self._name = name
    self.onCancel = onCancel
    self.onSubmit = onSubmit
  }

  var body: some View {
    #if os(iOS)
      self.promptContent
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    #else
      self.promptContent
        .frame(minWidth: 380, minHeight: 190)
    #endif
  }

  private var promptContent: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(self.title)
        .font(.title2.bold())

      TextField("Playlist Name", text: self.$name)
        .textFieldStyle(.roundedBorder)
        .focused(self.$isNameFocused)
        .onSubmit(self.submitButtonTapped)

      HStack(spacing: 12) {
        Button(action: self.onCancel) {
          Text("Cancel")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.primary)

        Button(action: self.submitButtonTapped) {
          Text(self.actionTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.gertrudeBrandAccent)
        .disabled(!self.name.isValidPlaylistName)
      }
      .controlSize(.large)
    }
    .padding(24)
    .onAppear { self.isNameFocused = true }
  }

  private func submitButtonTapped() {
    guard self.name.isValidPlaylistName else { return }
    self.onSubmit()
  }
}

public struct AddToPlaylistSheet: View {
  private let playlists: [PlaylistData]
  private let duplicatePrompt: PlaylistDuplicatePrompt?
  private let errorMessage: String?
  private let isMutating: Bool
  private let onCancel: @MainActor @Sendable () -> Void
  private let onCreatePlaylist: @MainActor @Sendable (String) -> Void
  private let onDuplicateCancel: @MainActor @Sendable () -> Void
  private let onDuplicateChoice: @MainActor @Sendable (PlaylistDuplicateChoice) -> Void
  private let onSelectPlaylist: @MainActor @Sendable (String) -> Void

  @State private var isNamePromptPresented = false
  @State private var newPlaylistName = ""

  public init(
    playlists: [PlaylistData],
    duplicatePrompt: PlaylistDuplicatePrompt? = nil,
    errorMessage: String? = nil,
    isMutating: Bool = false,
    onCancel: @MainActor @escaping @Sendable () -> Void = {},
    onCreatePlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDuplicateCancel: @MainActor @escaping @Sendable () -> Void = {},
    onDuplicateChoice: @MainActor @escaping @Sendable (PlaylistDuplicateChoice) -> Void = { _ in },
    onSelectPlaylist: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.playlists = playlists
    self.duplicatePrompt = duplicatePrompt
    self.errorMessage = errorMessage
    self.isMutating = isMutating
    self.onCancel = onCancel
    self.onCreatePlaylist = onCreatePlaylist
    self.onDuplicateCancel = onDuplicateCancel
    self.onDuplicateChoice = onDuplicateChoice
    self.onSelectPlaylist = onSelectPlaylist
  }

  public var body: some View {
    NavigationStack {
      List {
        if let errorMessage = self.errorMessage {
          Section {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
          }
        }

        Section {
          Button(action: self.newPlaylistButtonTapped) {
            Label("New Playlist", systemImage: "plus.circle.fill")
              .font(.body.weight(.semibold))
          }
          .tint(.primary)

          ForEach(self.playlists) { playlist in
            Button {
              self.onSelectPlaylist(playlist.id)
            } label: {
              HStack(spacing: 12) {
                PlaylistArtworkView(
                  playlist: playlist,
                  size: 48,
                  cornerRadius: 8,
                )

                VStack(alignment: .leading, spacing: 2) {
                  Text(playlist.name)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                  Text(self.trackCountText(for: playlist))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        } header: {
          Text("Choose a Playlist")
        } footer: {
          if self.playlists.isEmpty {
            Text("Create a playlist to add this music.")
          }
        }
      }
      .navigationTitle("Add to Playlist")
      .disabled(self.isMutating)
      .overlay {
        if self.isMutating {
          ProgressView("Adding")
            .padding(20)
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: self.onCancel)
            .tint(.primary)
            .disabled(self.isMutating)
        }
      }
      .sheet(isPresented: self.$isNamePromptPresented) {
        PlaylistNamePrompt(
          title: "New Playlist",
          actionTitle: "Create",
          name: self.$newPlaylistName,
          onCancel: self.namePromptCancelled,
          onSubmit: self.namePromptSubmitted,
        )
      }
      .alert(self.duplicateTitle, isPresented: self.duplicateBinding) {
        self.duplicateActions
      } message: {
        Text(self.duplicateMessage)
      }
    }
    .interactiveDismissDisabled(self.isMutating)
  }

  private func namePromptCancelled() {
    self.isNamePromptPresented = false
  }

  private func namePromptSubmitted() {
    self.isNamePromptPresented = false
    self.onCreatePlaylist(self.newPlaylistName)
  }

  private func newPlaylistButtonTapped() {
    self.newPlaylistName = ""
    self.isNamePromptPresented = true
  }

  private var duplicateBinding: Binding<Bool> {
    Binding(
      get: { self.duplicatePrompt != nil },
      set: { isPresented in
        if !isPresented {
          self.onDuplicateCancel()
        }
      },
    )
  }

  @ViewBuilder
  private var duplicateActions: some View {
    switch self.duplicatePrompt {
    case .track:
      Button("Cancel", role: .cancel, action: self.onDuplicateCancel)
      Button("Add Again") {
        self.onDuplicateChoice(.addAgain)
      }
    case .album:
      Button("Cancel", role: .cancel, action: self.onDuplicateCancel)
      Button("Add All") {
        self.onDuplicateChoice(.addAll)
      }
      Button("Add Only New Songs") {
        self.onDuplicateChoice(.addOnlyNew)
      }
    case nil:
      EmptyView()
    }
  }

  private var duplicateTitle: String {
    switch self.duplicatePrompt {
    case .track:
      "Song Already Added"
    case .album:
      "Some Songs Are Already Added"
    case nil:
      "Add to Playlist"
    }
  }

  private var duplicateMessage: String {
    switch self.duplicatePrompt {
    case .track(let trackTitle, let playlistName):
      return "“\(trackTitle)” is already in “\(playlistName)”. Add it again?"
    case .album(let playlistName, let duplicateCount):
      let songs = duplicateCount == 1 ? "song is" : "songs are"
      return "\(duplicateCount) \(songs) already in “\(playlistName)”."
    case nil:
      return ""
    }
  }

  private func trackCountText(for playlist: PlaylistData) -> String {
    playlist.trackCount == 1 ? "1 song" : "\(playlist.trackCount) songs"
  }
}

#if DEBUG
  #Preview("Add to playlist") {
    AddToPlaylistSheet(playlists: [
      .init(
        id: "favorites",
        name: "Favorites",
        entries: [
          .init(
            id: "entry",
            track: .init(id: "song", title: "Song", artist: "Artist"),
          ),
        ],
      ),
      .init(id: "road-trip", name: "Road Trip"),
    ])
  }

  #Preview("Duplicate album") {
    AddToPlaylistSheet(
      playlists: [.init(id: "favorites", name: "Favorites")],
      duplicatePrompt: .album(playlistName: "Favorites", duplicateCount: 3),
    )
  }

  #Preview("Playlist name prompt") {
    @Previewable @State var name = "Road Trip"
    PlaylistNamePrompt(
      title: "Rename Playlist",
      actionTitle: "Save",
      name: $name,
      onCancel: {},
      onSubmit: {},
    )
    .preferredColorScheme(.dark)
  }
#endif
