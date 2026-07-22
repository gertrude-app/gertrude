import Foundation
import SwiftUI

struct ArtistReleasesShelf: View {
  let releases: [ArtistReleaseData]
  let transitionNamespace: Namespace.ID?
  let onReleaseAddToPlaylist: @MainActor @Sendable (String) -> Void
  let onReleaseAddToQueue: @MainActor @Sendable (String) -> Void
  let onReleasePlayNext: @MainActor @Sendable (String) -> Void
  let onReleaseTap: @MainActor @Sendable (String) -> Void

  init(
    releases: [ArtistReleaseData],
    transitionNamespace: Namespace.ID?,
    onReleaseAddToPlaylist: @MainActor @escaping @Sendable (String) -> Void,
    onReleaseAddToQueue: @MainActor @escaping @Sendable (String) -> Void,
    onReleasePlayNext: @MainActor @escaping @Sendable (String) -> Void,
    onReleaseTap: @MainActor @escaping @Sendable (String) -> Void,
  ) {
    self.releases = releases.sortedByReleaseDateNewestFirst()
    self.transitionNamespace = transitionNamespace
    self.onReleaseAddToPlaylist = onReleaseAddToPlaylist
    self.onReleaseAddToQueue = onReleaseAddToQueue
    self.onReleasePlayNext = onReleasePlayNext
    self.onReleaseTap = onReleaseTap
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ArtistDetailSectionHeader(title: "Releases")

      if self.releases.isEmpty {
        ArtistDetailEmptyCard(
          systemImage: "rectangle.stack",
          title: "Releases will appear here",
          message: "Approved releases by this artist will be listed here.",
        )
        .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.releases) { release in
              ArtistReleaseCard(
                release: release,
                transitionNamespace: self.transitionNamespace,
                onTap: { self.onReleaseTap(release.id) },
              )
              .playbackQueueContextMenu(
                onPlayNext: { self.onReleasePlayNext(release.id) },
                onAddToQueue: { self.onReleaseAddToQueue(release.id) },
                onAddToPlaylist: { self.onReleaseAddToPlaylist(release.id) },
              )
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
      }
    }
  }
}

private struct ArtistReleaseCard: View {
  let release: ArtistReleaseData
  let transitionNamespace: Namespace.ID?
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      VStack(alignment: .leading, spacing: 9) {
        AlbumArtworkView(
          album: self.release.albumData,
          size: 148,
          cornerRadius: 16,
        )
        .matchedTransitionSourceIfAvailable(
          id: albumArtworkZoomTransitionID(for: self.release.id),
          in: self.transitionNamespace,
          cornerRadius: 16,
        )

        VStack(alignment: .leading, spacing: 2) {
          Text(self.release.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          if let detailText = self.release.detailText {
            Text(detailText)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      }
      .frame(width: 148, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }

  private var accessibilityLabel: String {
    [self.release.title, self.release.detailText]
      .compactMap { $0?.nonEmpty }
      .joined(separator: ", ")
  }
}

private extension [ArtistReleaseData] {
  func sortedByReleaseDateNewestFirst() -> [ArtistReleaseData] {
    self.sorted { lhs, rhs in
      if lhs.releaseSortKey != rhs.releaseSortKey {
        return lhs.releaseSortKey > rhs.releaseSortKey
      }
      return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
  }
}

private extension ArtistReleaseData {
  var albumData: AlbumData {
    AlbumData(
      id: self.id,
      title: self.title,
      artist: self.artist,
      artworkUrl: self.artworkUrl,
      artworkPalette: self.artworkPalette,
      trackCount: self.trackCount,
      releaseDate: self.releaseDate,
      releaseType: self.releaseType,
    )
  }

  var detailText: String? {
    [self.releaseType?.nonEmpty, self.releaseYear, self.trackCountText]
      .compactMap(\.self)
      .joined(separator: " • ")
      .nonEmpty
  }

  var releaseYear: String? {
    guard let releaseDate = self.releaseDate?.nonEmpty else { return nil }
    return String(releaseDate.prefix(4)).nonEmpty
  }

  var trackCountText: String? {
    guard let trackCount = self.trackCount else { return nil }
    return trackCount == 1 ? "1 track" : "\(trackCount) tracks"
  }

  var releaseSortKey: String {
    self.releaseDate?.nonEmpty ?? ""
  }
}
