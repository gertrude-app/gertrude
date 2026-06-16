import Testing

@testable import LibTCA

@MainActor
struct ApprovedMusicClientTests {
  @Test
  func mockLibraryIsUsable() async throws {
    let library = try await ApprovedMusicClient.mock.loadApprovedLibrary()

    #expect(!library.isEmpty)
    #expect(Set(library.albums.map(\.id)).count == library.albums.count)

    for album in library.albums {
      #expect(!album.tracks.isEmpty)
      #expect(Set(album.tracks.map(\.id)).count == album.tracks.count)
    }
  }

  @Test
  func emptyLibraryIsAvailableForTestsAndPreviews() async throws {
    let library = try await ApprovedMusicClient.empty.loadApprovedLibrary()

    #expect(library.isEmpty)
  }
}
