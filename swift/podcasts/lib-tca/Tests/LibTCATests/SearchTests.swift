import Foundation
import LibViews
import Testing

@testable import LibTCA

@Test
func testSearchPodcastsWithValidQuery() async throws {
  let results = try await searchPodcastsLive(
    query: "this american life",
    locale: Locale(identifier: "en_US")
  )

  #expect(!results.isEmpty)

  // Check that results have required fields
  for result in results {
    #expect(!result.title.isEmpty)
    #expect(result.id > 0)
  }

  // Look for the actual "This American Life" podcast
  let thisAmericanLife = results.first { result in
    result.title.lowercased().contains("this american life")
  }

  #expect(thisAmericanLife != nil)
}
