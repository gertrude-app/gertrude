import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

extension View {
  func libraryPresentations(store: StoreOf<LibraryFeature>) -> some View {
    self.modifier(LibraryPresentationModifier(store: store))
  }
}

private struct LibraryPresentationModifier: ViewModifier {
  @Bindable var store: StoreOf<LibraryFeature>

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: self.addToPlaylistBinding) {
        AddToPlaylistSheet(
          playlists: self.playlists,
          duplicatePrompt: self.duplicatePrompt,
          errorMessage: self.store.playlistMutationFailure?.message,
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
          onSelectPlaylist: {
            guard let id = UUID(uuidString: $0) else { return }
            self.store.send(.addToPlaylistDestinationSelected(.init(rawValue: id)))
          },
        )
      }
      .alert("Couldn’t Update Playlist", isPresented: self.mutationFailureBinding) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(self.store.playlistMutationFailure?.message ?? "Please try again.")
      }
  }

  private var addToPlaylistBinding: Binding<Bool> {
    Binding(
      get: { self.store.addToPlaylist != nil },
      set: { isPresented in
        if !isPresented {
          self.store.send(.addToPlaylistCancelled)
        }
      },
    )
  }

  private var mutationFailureBinding: Binding<Bool> {
    Binding(
      get: {
        self.store.addToPlaylist == nil
          && self.store.playlistMutationFailure != nil
      },
      set: { isPresented in
        if !isPresented {
          self.store.send(.playlistMutationFailureDismissed)
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

private extension LibraryFeature.PlaylistMutationFailure {
  var message: String {
    switch self {
    case .conflict:
      "This playlist changed on another device. The latest version is now shown."
    case .failed:
      "Your change wasn’t saved. Please try again."
    }
  }
}
