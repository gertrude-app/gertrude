import SwiftUI
import Testing

@testable import LibViews

@MainActor
struct NowPlayingMetadataLayoutTests {
  @Test
  func wrappedMetadataKeepsLineBreaksWithoutReservingEmptyColumnWidth() throws {
    let metadata = Button(action: {}) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Improvisation til de efterladte")
          .font(.system(size: 24, weight: .bold, design: .rounded))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
        Text("Julian Svejgaard")
          .font(.system(size: 17, weight: .semibold, design: .rounded))
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      .multilineTextAlignment(.leading)
    }
    .buttonStyle(.plain)

    let unwrapped = try #require(ImageRenderer(content: metadata).cgImage)
    let wrapped = try #require(ImageRenderer(content: NowPlayingMetadataLayout(maximumWidth: 320) {
      metadata
    }).cgImage)

    #expect(wrapped.width < 320)
    #expect(wrapped.height > unwrapped.height)
  }

  @Test
  func shortMetadataKeepsItsNaturalWidth() throws {
    let metadata = Text("A Tune")
      .font(.system(size: 24, weight: .bold, design: .rounded))
      .fixedSize(horizontal: false, vertical: true)
    let natural = try #require(ImageRenderer(content: metadata).cgImage)
    let constrained =
      try #require(ImageRenderer(content: NowPlayingMetadataLayout(maximumWidth: 320) {
        metadata
      }).cgImage)

    #expect(constrained.width == natural.width)
    #expect(constrained.height == natural.height)
  }
}
