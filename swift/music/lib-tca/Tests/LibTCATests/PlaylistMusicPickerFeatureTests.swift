import ComposableArchitecture
import CustomDump
import Foundation
import MusicRoute
import Testing

@testable import LibTCA

@MainActor
struct PlaylistMusicPickerFeatureTests {
  @Test
  func duplicateSingleSongUsesSimpleAddAgainPrompt() async {
    let library = ApprovedMusicLibrary.mock
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Road Trip",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
    let search = MusicLibrarySearch(library: library)
    let results = search.results(query: "Brewed")
    let songID = MusicSearchResult.ID.song("1641851259")
    let confirmation = MusicPlaylistBatchDuplicateConfirmation(
      playlistId: playlist.id.rawValue,
      duplicates: [.init(trackId: "1641851259", title: "Brewed", existingCount: 1)],
    )
    let store = TestStore(initialState: PlaylistMusicPickerFeature.State(
      playlist: playlist,
      library: library,
    )) {
      PlaylistMusicPickerFeature()
    }

    await store.send(.queryChanged("Brewed")) {
      $0.query = "Brewed"
      $0.results = results
    }
    await store.send(.resultTapped(songID)) {
      $0.selectedResultIDs = [songID]
    }
    await store.send(.duplicateConfirmationReceived(confirmation)) {
      $0.duplicateConfirmation = confirmation
    }
    expectNoDifference(store.state.duplicatePrompt, .track(title: "Brewed"))
    await store.send(.duplicateResolutionSelected(.addAll)) {
      $0.duplicateConfirmation = nil
    }
    await store.receive(.delegate(.addRequested(
      sources: [.track(trackId: "1641851259", albumId: "1641851258")],
      duplicateResolution: .addAll,
    )))
  }

  @Test
  func selectsSongsAndAlbumsThenDelegatesTheBatchInSelectionOrder() async {
    let library = ApprovedMusicLibrary.mock
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Road Trip",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
    let search = MusicLibrarySearch(library: library)
    let elementResults = search.results(query: "Elements")
    let brewedResults = search.results(query: "Brewed")
    let albumID = MusicSearchResult.ID.album("1682152618")
    let songID = MusicSearchResult.ID.song("1641851259")
    let store = TestStore(initialState: PlaylistMusicPickerFeature.State(
      playlist: playlist,
      library: library,
    )) {
      PlaylistMusicPickerFeature()
    }

    await store.send(.queryChanged("Elements")) {
      $0.query = "Elements"
      $0.results = elementResults
    }
    await store.send(.resultTapped(albumID)) {
      $0.selectedResultIDs = [albumID]
    }
    await store.send(.queryChanged("Brewed")) {
      $0.query = "Brewed"
      $0.results = brewedResults
    }
    await store.send(.resultTapped(songID)) {
      $0.selectedResultIDs = [albumID, songID]
    }
    await store.send(.addButtonTapped)
    await store.receive(.delegate(.addRequested(
      sources: [
        .album(albumId: "1682152618"),
        .track(trackId: "1641851259", albumId: "1641851258"),
      ],
      duplicateResolution: .requestConfirmation,
    )))
  }
}
