import ComposableArchitecture
import CustomDump
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct PlaylistDetailFeatureTests {
  @Test
  func duplicateRowTapStartsAtExactOccurrence() async {
    let playlist = self.musicPlaylist()
    let state = PlaylistDetailFeature.State(playlist: playlist)
    let items = state.playbackItems
    let store = TestStore(initialState: state) {
      PlaylistDetailFeature()
    }

    await store.send(.trackTapped(playlist.entries[1].id))
    await store.receive(.delegate(.playNow(items: items, startIndex: 1)))

    expectNoDifference(items.map(\.playlistSource), [
      PlaylistPlaybackSource(
        playlistID: playlist.id.rawValue,
        entryID: playlist.entries[0].id.rawValue,
      ),
      PlaylistPlaybackSource(
        playlistID: playlist.id.rawValue,
        entryID: playlist.entries[1].id.rawValue,
      ),
    ])
  }

  @Test
  func currentDuplicateRowTogglesPlayback() async {
    let playlist = self.musicPlaylist()
    let store = TestStore(initialState: PlaylistDetailFeature.State(
      playlist: playlist,
      playStatus: .playing,
      currentEntryID: playlist.entries[1].id,
    )) {
      PlaylistDetailFeature()
    }

    await store.send(.trackTapped(playlist.entries[1].id))
    await store.receive(.delegate(.togglePlayPause))
  }

  @Test
  func manuallyQueuedEntryHighlightsWithoutClaimingPlaylistContext() async {
    let playlist = self.musicPlaylist()
    let state = PlaylistDetailFeature.State(playlist: playlist)
    let item = state.playbackItems[0].withQueueRole(.queued)
    var synchronizedState = state
    synchronizedState.setPlaybackSession(
      .init(currentItem: item),
      activeContext: nil,
    )

    #expect(synchronizedState.currentEntryID == playlist.entries[0].id)
    #expect(synchronizedState.isCurrentTrackPlaying)
    #expect(!synchronizedState.isPlaying)

    let store = TestStore(initialState: synchronizedState) {
      PlaylistDetailFeature()
    }
    await store.send(.playTapped)
    await store.receive(.delegate(.playNow(
      items: state.playbackItems,
      startIndex: 0,
    )))
  }

  @Test
  func albumPlaybackHighlightsTrackWithoutClaimingPlaylistContext() {
    let playlist = self.musicPlaylist()
    var state = PlaylistDetailFeature.State(playlist: playlist)
    state.setPlaybackSession(
      .init(currentItem: playbackItem("duplicate").withQueueRole(.context)),
      activeContext: PlaybackContext(
        identity: .init(kind: .album, id: "album"),
        title: "Album",
      ),
    )

    #expect(state.currentEntryID == playlist.entries[0].id)
    #expect(state.isCurrentTrackPlaying)
    #expect(!state.isPlaying)
  }

  @Test
  func playbackFailureActionsDelegateToApp() async {
    let store = TestStore(initialState: PlaylistDetailFeature.State(
      playlist: self.musicPlaylist(),
      playbackFailure: .musicAccessDenied,
    )) {
      PlaylistDetailFeature()
    }

    await store.send(.playbackFailureActionTapped)
    await store.receive(.delegate(.playbackFailureActionTapped))
    await store.send(.playbackFailureDismissed)
    await store.receive(.delegate(.dismissPlaybackFailure))
  }

  @Test
  func reorderRequiresEveryOccurrenceExactlyOnce() async {
    let playlist = self.musicPlaylist()
    let store = TestStore(initialState: PlaylistDetailFeature.State(playlist: playlist)) {
      PlaylistDetailFeature()
    }

    await store.send(.reorderSubmitted([
      playlist.entries[1].id,
      playlist.entries[0].id,
    ]))
    await store.receive(.delegate(.reorder([
      playlist.entries[1].id,
      playlist.entries[0].id,
    ])))

    await store.send(.reorderSubmitted([
      playlist.entries[0].id,
      playlist.entries[0].id,
    ]))
  }

  private func musicPlaylist() -> MusicPlaylist {
    let track = ApprovedTrack(
      id: "duplicate",
      title: "Duplicate",
      artistName: "Artist",
      albumID: "album",
    )
    return MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Duplicates",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
      entries: [
        .init(id: .init(rawValue: UUID(2)), track: track),
        .init(id: .init(rawValue: UUID(3)), track: track),
      ],
    )
  }
}
