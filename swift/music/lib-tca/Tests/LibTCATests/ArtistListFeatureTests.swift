import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct ArtistListFeatureTests {
  @Test
  func artistTapNavigatesToArtistScreen() async {
    let library = ApprovedMusicLibrary.mock
    let artist = library.artists[0]
    let store = TestStore(initialState: .init(artists: library.artists)) {
      ArtistListFeature()
    }

    await store.send(.artistTapped(artist.id)) {
      $0.destination = .artist(.init(
        title: artist.name,
        transitionSourceID: artist.id.rawValue,
      ))
    }
  }
}
