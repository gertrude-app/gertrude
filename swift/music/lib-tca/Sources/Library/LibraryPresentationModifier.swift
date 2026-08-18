import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

extension View {
  func libraryPresentations(
    store: StoreOf<LibraryFeature>,
    isEnabled: Bool = true,
  ) -> some View {
    self.modifier(LibraryPresentationModifier(
      store: store,
      isEnabled: isEnabled,
    ))
  }
}

private struct LibraryPresentationModifier: ViewModifier {
  @Bindable var store: StoreOf<LibraryFeature>
  let isEnabled: Bool

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: self.addToPlaylistBinding) {
        AddToPlaylistSheet(
          playlists: self.playlists,
          duplicatePrompt: self.duplicatePrompt,
          errorMessage: self.store.playlistMutationFailure?.addToPlaylistMessage,
          errorTitle: self.store.playlistMutationFailure?.addMusicTitle ?? "Couldn’t add music",
          errorTone: self.store.playlistMutationFailure?.tone ?? .error,
          isMutating: self.store.isPlaylistMutationInFlight,
          onCancel: { self.store.send(.addToPlaylistCancelled) },
          onCreatePlaylist: { self.store.send(.addToPlaylistCreateSubmitted($0)) },
          onDuplicateCancel: { self.store.send(.addToPlaylistDuplicateCancelled) },
          onDuplicateChoice: { choice in
            switch choice {
            case .addAgain:
              self.store.send(.addToPlaylistDuplicateResolutionSelected(.addAgain))
            case .addAll:
              self.store.send(.addToPlaylistDuplicateResolutionSelected(.addAll))
            case .addOnlyNew:
              self.store.send(.addToPlaylistDuplicateResolutionSelected(.addOnlyNew))
            }
          },
          onErrorDismissTap: {
            self.store.send(.playlistMutationFailureDismissed)
          },
          onSelectPlaylist: {
            guard let id = UUID(uuidString: $0) else { return }
            self.store.send(.addToPlaylistDestinationSelected(.init(rawValue: id)))
          },
        )
      }
      .sheet(item: self.playlistMusicPickerBinding) { store in
        PlaylistMusicPickerViewContainer(
          store: store,
          errorMessage: self.store.playlistMutationFailure?.musicPickerMessage,
          errorTitle: self.store.playlistMutationFailure?.addMusicTitle ?? "Couldn’t add music",
          errorTone: self.store.playlistMutationFailure?.tone ?? .error,
          isMutating: self.store.isPlaylistMutationInFlight,
          onErrorDismissTap: {
            self.store.send(.playlistMutationFailureDismissed)
          },
        )
      }
  }

  private var addToPlaylistBinding: Binding<Bool> {
    Binding(
      get: { self.isEnabled && self.store.addToPlaylist != nil },
      set: { isPresented in
        if !isPresented {
          self.store.send(.addToPlaylistCancelled)
        }
      },
    )
  }

  private var playlistMusicPickerBinding: Binding<StoreOf<PlaylistMusicPickerFeature>?> {
    let binding = self.$store.scope(
      state: \.playlistMusicPicker,
      action: \.playlistMusicPicker,
    )
    return Binding(
      get: { self.isEnabled ? binding.wrappedValue : nil },
      set: { store in
        if self.isEnabled {
          binding.wrappedValue = store
        }
      },
    )
  }

  private var playlists: [PlaylistData] {
    guard case .loaded(let library) = self.store.status else { return [] }
    return library.playlists.map(PlaylistData.init)
  }

  private var duplicatePrompt: PlaylistDuplicatePrompt? {
    guard case .loaded(let library) = self.store.status,
          let confirmation = self.store.addToPlaylist?.confirmation else { return nil }
    switch confirmation {
    case .track(let playlistID, let duplicate):
      guard let playlist = library.playlist(id: .init(rawValue: playlistID)) else { return nil }
      return .track(trackTitle: duplicate.title, playlistName: playlist.name)
    case .album(let playlistID, _, let duplicates):
      guard let playlist = library.playlist(id: .init(rawValue: playlistID)) else { return nil }
      return .album(playlistName: playlist.name, duplicateCount: duplicates.count)
    }
  }
}

extension LibraryFeature.PlaylistMutationFailure {
  var addToPlaylistMessage: String {
    switch self {
    case .conflict:
      self.message
    case .failed:
      "The music wasn’t added. Please try again."
    }
  }

  var musicPickerMessage: String {
    switch self {
    case .conflict:
      self.message
    case .failed:
      "Your selection is still here. Try adding it again."
    }
  }

  var addMusicTitle: String {
    switch self {
    case .conflict:
      self.title
    case .failed:
      "Couldn’t add music"
    }
  }

  var message: String {
    switch self {
    case .conflict:
      "This playlist changed on another device. The latest version is now shown."
    case .failed:
      "Your change wasn’t saved. Please try again."
    }
  }

  var title: String {
    switch self {
    case .conflict:
      "Playlist changed"
    case .failed:
      "Couldn’t update playlist"
    }
  }

  var tone: NoticeBannerTone {
    switch self {
    case .conflict:
      .information
    case .failed:
      .error
    }
  }
}
