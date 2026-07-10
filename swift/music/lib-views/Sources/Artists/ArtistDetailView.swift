import Foundation
import SwiftUI

public struct ArtworkPalette: Equatable, Hashable, Sendable {
  public let bgColor: String?
  public let textColor1: String?
  public let textColor2: String?
  public let textColor3: String?
  public let textColor4: String?

  public init(
    bgColor: String? = nil,
    textColor1: String? = nil,
    textColor2: String? = nil,
    textColor3: String? = nil,
    textColor4: String? = nil,
  ) {
    self.bgColor = bgColor
    self.textColor1 = textColor1
    self.textColor2 = textColor2
    self.textColor3 = textColor3
    self.textColor4 = textColor4
  }
}

public struct ArtistDetailData: Identifiable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let editorialNotes: String?

  public init(
    id: String,
    name: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    editorialNotes: String? = nil,
  ) {
    self.id = id
    self.name = name
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.editorialNotes = editorialNotes
  }
}

public struct ArtistTopSongData: Identifiable, Equatable, Hashable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let albumTitle: String?
  public let artworkUrl: URL?
  public let duration: String?

  public init(
    id: String,
    title: String,
    artist: String,
    albumTitle: String? = nil,
    artworkUrl: URL? = nil,
    duration: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.albumTitle = albumTitle
    self.artworkUrl = artworkUrl
    self.duration = duration
  }
}

public struct ArtistReleaseData: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let releaseDate: String?
  public let trackCount: Int?
  public let releaseType: String?

  public init(
    id: String,
    title: String,
    artist: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    releaseDate: String? = nil,
    trackCount: Int? = nil,
    releaseType: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.releaseDate = releaseDate
    self.trackCount = trackCount
    self.releaseType = releaseType
  }
}

public struct ArtistDetailView: View {
  private let artist: ArtistDetailData
  private let topSongs: [ArtistTopSongData]
  private let releases: [ArtistReleaseData]
  private let transitionSourceID: String?
  private let currentTrackID: String?
  private let isPlaying: Bool
  private let isLoading: Bool
  private let onPlayTap: @MainActor @Sendable () -> Void
  private let onSongTap: @MainActor @Sendable (String) -> Void
  private let onReleaseTap: @MainActor @Sendable (String) -> Void

  public init(
    artist: ArtistDetailData,
    topSongs: [ArtistTopSongData] = [],
    releases: [ArtistReleaseData] = [],
    transitionSourceID: String? = nil,
    currentTrackID: String? = nil,
    isPlaying: Bool = false,
    isLoading: Bool = false,
    onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
    onSongTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onReleaseTap: @MainActor @escaping @Sendable (String) -> Void = { _ in
    },
  ) {
    self.artist = artist
    self.topSongs = topSongs
    self.releases = releases
    self.transitionSourceID = transitionSourceID
    self.currentTrackID = currentTrackID
    self.isPlaying = isPlaying
    self.isLoading = isLoading
    self.onPlayTap = onPlayTap
    self.onSongTap = onSongTap
    self.onReleaseTap = onReleaseTap
  }

  public var body: some View {
    GeometryReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 30) {
          ArtistDetailHeroView(
            artist: self.artist,
            transitionID: self.artworkTransitionID,
            isPlaying: self.isPlaying,
            isLoading: self.isLoading,
            onPlayTap: self.onPlayTap,
          )
          .padding(.horizontal, 20)
          .padding(.top, proxy.frame(in: .global).minY + 18)
          .padding(.bottom, 24)
          .background {
            if let backgroundColor = self.artist.artworkPalette?
              .backgroundColor {
              LinearGradient(
                colors: [
                  .clear,
                  backgroundColor.opacity(0.3),
                ],
                startPoint: .top,
                endPoint: .bottom,
              )
              .ignoresSafeArea(edges: .top)
            }
          }

          ArtistTopSongsShelf(
            songs: self.topSongs,
            currentTrackID: self.currentTrackID,
            isPlaying: self.isPlaying,
            onSongTap: self.onSongTap,
          )

          ArtistReleasesShelf(
            releases: self.releases,
            onReleaseTap: self.onReleaseTap,
          )

          if let editorialNotes = self.artist.editorialNotes?.nonEmpty {
            ArtistEditorialNotesSection(notes: editorialNotes)
              .padding(.horizontal, 20)
          }
        }
        .padding(.bottom, 96)
      }
      .background(.background)
      .ignoresSafeArea(edges: .top)
    }
    .navigationTitle("")
    .artistDetailNavigationBarBackground()
  }

  private var artworkTransitionID: String {
    artistArtworkZoomTransitionID(
      for: self.transitionSourceID ?? self.artist.id,
    )
  }
}

private extension View {
  @ViewBuilder
  func artistDetailNavigationBarBackground() -> some View {
    #if os(iOS)
      self.toolbarBackground(.hidden, for: .navigationBar)
    #else
      self
    #endif
  }
}

private struct ArtistDetailHeroView: View {
  @Environment(\.self) private var environment

  let artist: ArtistDetailData
  let transitionID: String?
  let isPlaying: Bool
  let isLoading: Bool
  let onPlayTap: @MainActor @Sendable () -> Void

  var body: some View {
    let colors = self.playButtonColors

    VStack(spacing: 18) {
      ZoomableArtistArtworkView(
        artworkUrl: self.artist.artworkUrl,
        size: 220,
        transitionID: self.transitionID,
        role: .destination,
      )

      Text(self.artist.name)
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .multilineTextAlignment(.center)
        .lineLimit(3)

      Button(action: self.onPlayTap) {
        HStack(spacing: 9) {
          if self.isLoading {
            ProgressView()
              .controlSize(.small)
              .tint(colors.foreground)
          } else {
            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 15, weight: .bold))
          }

          Text("\(self.isPlaying ? "Playing" : "Play") \(self.artist.name)")
            .font(.headline)
            .lineLimit(1)
        }
        .foregroundStyle(colors.foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(colors.background, in: .capsule)
      }
      .buttonStyle(.plain)
      .disabled(self.isLoading)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .contain)
  }

  private var playButtonColors: ArtistDetailPlayButtonColors {
    guard
      let paletteColors = self.artist.artworkPalette?
      .orderedColors(in: self.environment)
    else {
      return self.environment.colorScheme == .dark
        ? ArtistDetailPlayButtonColors(
          background: .white,
          foreground: .black,
        )
        : ArtistDetailPlayButtonColors(
          background: .black,
          foreground: .white,
        )
    }

    if self.environment.colorScheme == .dark {
      return ArtistDetailPlayButtonColors(
        background: paletteColors.lighter,
        foreground: paletteColors.darker,
      )
    }

    return ArtistDetailPlayButtonColors(
      background: paletteColors.darker,
      foreground: paletteColors.lighter,
    )
  }
}

private struct ArtistDetailPlayButtonColors {
  let background: Color
  let foreground: Color
}

extension ArtistDetailData {
  init(artist: ArtistData) {
    self.init(
      id: artist.id,
      name: artist.name,
      artworkUrl: artist.artworkUrl,
      artworkPalette: artist.artworkPalette,
      editorialNotes: artist.editorialNotes,
    )
  }
}

private struct ArtistTopSongsShelf: View {
  let songs: [ArtistTopSongData]
  let currentTrackID: String?
  let isPlaying: Bool
  let onSongTap: @MainActor @Sendable (String) -> Void

  private let rows = Array(
    repeating: GridItem(.fixed(52), spacing: 8, alignment: .top),
    count: 3,
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ArtistDetailSectionHeader(title: "Top Songs")

      if self.songs.isEmpty {
        ArtistDetailEmptyCard(
          systemImage: "music.note.list",
          title: "Top songs will appear here",
          message:
          "We’ll show a short Apple Music queue for artist playback.",
        )
        .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHGrid(rows: self.rows, alignment: .top, spacing: 40) {
            ForEach(
              Array(self.songs.enumerated()),
              id: \.element.id,
            ) { index, song in
              ArtistTopSongCard(
                number: index + 1,
                song: song,
                isCurrent: song.id == self.currentTrackID,
                isPlaying: self.isPlaying,
                onTap: { self.onSongTap(song.id) },
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

private struct ArtistTopSongCard: View {
  let number: Int
  let song: ArtistTopSongData
  let isCurrent: Bool
  let isPlaying: Bool
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 0) {
        Text(self.number, format: .number)
          .font(.caption.weight(.bold))
          .monospacedDigit()
          .foregroundStyle(.secondary)

        ArtistDetailArtworkThumbnail(
          url: self.song.artworkUrl,
          systemImage: "music.note",
          size: 38,
        )
        .padding(.trailing, 8)
        .padding(.leading, 8)

        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 5) {
            if self.isCurrent {
              ArtistTopSongWaveformView(isPlaying: self.isPlaying)
            }

            Text(self.song.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(
                self.isCurrent ? Color.gertrudeBrandAccent : .primary,
              )
              .lineLimit(1)
          }

          if let detailText = self.detailText {
            Text(detailText)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }

        Spacer(minLength: 8)

        if let duration = self.song.duration?.nonEmpty {
          Text(duration)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 292, height: 52, alignment: .leading)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(self.accessibilityLabel)
  }

  private var detailText: String? {
    self.song.albumTitle?.nonEmpty
  }

  private var accessibilityLabel: String {
    [
      self.isCurrent ? self.isPlaying ? "Playing" : "Paused" : nil,
      "Song \(self.number)", self.song.title, self.song.artist,
      self.song.albumTitle,
    ]
    .compactMap { $0?.nonEmpty }
    .joined(separator: ", ")
  }
}

private struct ArtistTopSongWaveformView: View {
  let isPlaying: Bool

  @ScaledMetric(relativeTo: .subheadline) private var barSpacing: CGFloat = 1.5
  @ScaledMetric(relativeTo: .subheadline) private var barWidth: CGFloat = 2.25
  @ScaledMetric(relativeTo: .subheadline) private var minimumBarHeight: CGFloat = 3
  @ScaledMetric(relativeTo: .subheadline) private var waveformHeight: CGFloat = 12
  @ScaledMetric(relativeTo: .subheadline) private var waveformWidth: CGFloat = 10

  var body: some View {
    if self.isPlaying {
      TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
        self.bars(date: timeline.date)
      }
    } else {
      self.bars(date: nil)
    }
  }

  private func bars(date: Date?) -> some View {
    HStack(alignment: .bottom, spacing: self.barSpacing) {
      ForEach(0 ..< 3, id: \.self) { index in
        RoundedRectangle(cornerRadius: self.barWidth / 2, style: .continuous)
          .fill(Color.gertrudeBrandAccent)
          .frame(
            width: self.barWidth,
            height: self.barHeight(index: index, date: date),
          )
      }
    }
    .frame(
      width: self.waveformWidth,
      height: self.waveformHeight,
      alignment: .bottom,
    )
  }

  private func barHeight(index: Int, date: Date?) -> CGFloat {
    guard let date else { return self.minimumBarHeight }
    let phase =
      date.timeIntervalSinceReferenceDate * 5.5 + Double(index) * 1.15
    let progress = (sin(phase) + 1) / 2
    return self.minimumBarHeight
      + CGFloat(progress) * (self.waveformHeight - self.minimumBarHeight)
  }
}

private struct ArtistReleasesShelf: View {
  let releases: [ArtistReleaseData]
  let onReleaseTap: @MainActor @Sendable (String) -> Void

  init(
    releases: [ArtistReleaseData],
    onReleaseTap: @MainActor @escaping @Sendable (String) -> Void,
  ) {
    self.releases = releases.sortedByReleaseDateNewestFirst()
    self.onReleaseTap = onReleaseTap
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ArtistDetailSectionHeader(title: "Releases")

      if self.releases.isEmpty {
        ArtistDetailEmptyCard(
          systemImage: "rectangle.stack",
          title: "Releases will appear here",
          message:
          "Approved releases by this artist will be listed here.",
        )
        .padding(.horizontal, 20)
      } else {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: 16) {
            ForEach(self.releases) { release in
              ArtistReleaseCard(
                release: release,
                onTap: { self.onReleaseTap(release.id) },
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
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      VStack(alignment: .leading, spacing: 9) {
        ZoomableAlbumArtworkView(
          album: self.release.albumData,
          size: 148,
          cornerRadius: 16,
          transitionID: albumArtworkZoomTransitionID(for: self.release.id),
          role: .source,
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

private struct ArtistEditorialNotesSection: View {
  let notes: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("About")
        .font(.title3.weight(.bold))

      Text(self.notes)
        .font(.body)
        .foregroundStyle(.secondary)
        .lineSpacing(3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct ArtistDetailSectionHeader: View {
  let title: String

  var body: some View {
    Text(self.title)
      .font(.title3.weight(.bold))
      .foregroundStyle(.primary)
      .padding(.horizontal, 20)
  }
}

private struct ArtistDetailArtworkThumbnail: View {
  let url: URL?
  let systemImage: String
  let cornerRadius: CGFloat
  let size: CGFloat

  init(
    url: URL?,
    systemImage: String,
    cornerRadius: CGFloat = 9,
    size: CGFloat = 44,
  ) {
    self.url = url
    self.systemImage = systemImage
    self.cornerRadius = cornerRadius
    self.size = size
  }

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(
          .rect(cornerRadius: self.cornerRadius, style: .continuous),
        )
    } placeholder: {
      RoundedRectangle(
        cornerRadius: self.cornerRadius,
        style: .continuous,
      )
      .fill(Color.gertrudeBrandAccent.opacity(0.14))
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: self.systemImage)
          .font(.system(size: self.size * 0.38, weight: .semibold))
          .foregroundStyle(Color.gertrudeBrandAccent.opacity(0.68))
      }
    }
    .accessibilityHidden(true)
  }
}

private struct ArtistDetailEmptyCard: View {
  let systemImage: String
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: self.systemImage)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Text(self.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)

      Text(self.message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(18)
    .background(
      .primary.opacity(0.05),
      in: .rect(cornerRadius: 18, style: .continuous),
    )
  }
}

private extension [ArtistReleaseData] {
  func sortedByReleaseDateNewestFirst() -> [ArtistReleaseData] {
    self.sorted { lhs, rhs in
      if lhs.releaseSortKey != rhs.releaseSortKey {
        return lhs.releaseSortKey > rhs.releaseSortKey
      }
      return lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        == .orderedAscending
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

private extension String {
  var nonEmpty: String? {
    self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? nil : self
  }
}

#if DEBUG
  #Preview("Artist detail") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
      )
    }
  }

  #Preview("Artist detail playing") {
    NavigationStack {
      ArtistDetailView(
        artist: .previewSpoketIKoket,
        topSongs: .previewSpoketIKoketTopSongs,
        releases: .previewSpoketIKoketReleases,
        currentTrackID: [ArtistTopSongData].previewSpoketIKoketTopSongs[0].id,
        isPlaying: true,
      )
    }
  }

  #Preview("Artist detail empty") {
    NavigationStack {
      ArtistDetailView(artist: .previewSpoketIKoket)
    }
  }

  fileprivate extension ArtistDetailData {
    static let previewSpoketIKoket = ArtistDetailData(
      id: "1458349518",
      name: "Spöket i Köket",
      artworkUrl: URL(
        string:
        "https://is1-ssl.mzstatic.com/image/thumb/AMCArtistImages221/v4/10/f7/8d/10f78d77-5ef5-611b-ff57-dd839f1848fb/ami-identity-fb08fd0a7f650ce0f8c0b3415d958347-2025-03-13T10-39-00.698Z_cropped.png/600x600bb.jpg",
      ),
      artworkPalette: .init(
        bgColor: "123b2f",
        textColor1: "c5e9f5",
        textColor2: "fb7f6f",
        textColor3: "a1c6cd",
        textColor4: "cc7162",
      ),
    )
  }

  fileprivate extension [ArtistTopSongData] {
    static let previewSpoketIKoketTopSongs:
      [ArtistTopSongData] = [
        .init(
          id: "1458353279",
          title: "Ninos vaggvisa",
          artist: "Spöket i Köket",
          albumTitle: "Château du Garage",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          duration: "3:20",
        ),
        .init(
          id: "1638997831",
          title: "Polska Till Wik",
          artist: "Spöket i Köket",
          albumTitle: "Kurbits & Flames",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/77/c6/d5/77c6d545-30e2-35a1-592e-b9c1d227f65f/7320470263310.png/600x600bb.jpg",
          ),
          duration: "5:00",
        ),
        .init(
          id: "1458352968",
          title: "Engelsk rävjakt",
          artist: "Spöket i Köket",
          albumTitle: "Château du Garage",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          duration: "4:28",
        ),
        .init(
          id: "1458352964",
          title: "The Jay Kay Reel - Reel à la carte",
          artist: "Spöket i Köket",
          albumTitle: "Château du Garage",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          duration: "5:20",
        ),
        .init(
          id: "1505856849",
          title: "Ugglan - Farväl till Skurup - Lasses jig",
          artist: "Spöket i Köket",
          albumTitle: "Den nya spisen",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/ed/a5/22/eda522e2-89d2-4d30-0e4c-c0a2233107c0/73495.jpg/600x600bb.jpg",
          ),
          duration: "5:36",
        ),
        .init(
          id: "1638997828",
          title: "Polska Från Medelpad",
          artist: "Spöket i Köket",
          albumTitle: "Kurbits & Flames",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/77/c6/d5/77c6d545-30e2-35a1-592e-b9c1d227f65f/7320470263310.png/600x600bb.jpg",
          ),
          duration: "6:11",
        ),
        .init(
          id: "1458352960",
          title: "Rävsvansen",
          artist: "Spöket i Köket",
          albumTitle: "Château du Garage",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          duration: "0:47",
        ),
        .init(
          id: "1458353290",
          title: "Ninos vaggvisa (Reprise)",
          artist: "Spöket i Köket",
          albumTitle: "Château du Garage",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          duration: "4:18",
        ),
        .init(
          id: "1885416619",
          title: "Gammal och ung",
          artist: "Spöket i Köket & Åkervinda",
          albumTitle: "Hits från förr - EP",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/c2/f1/7f/c2f17f6c-596c-b58e-dbcb-f4cf5795da9d/125420.jpg/600x600bb.jpg",
          ),
          duration: "3:43",
        ),
        .init(
          id: "1885416621",
          title: "Nattvandrare",
          artist: "Spöket i Köket & Åkervinda",
          albumTitle: "Hits från förr - EP",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/c2/f1/7f/c2f17f6c-596c-b58e-dbcb-f4cf5795da9d/125420.jpg/600x600bb.jpg",
          ),
          duration: "5:54",
        ),
        .init(
          id: "1885416618",
          title: "Öppna ditt fönster",
          artist: "Spöket i Köket & Åkervinda",
          albumTitle: "Hits från förr - EP",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/c2/f1/7f/c2f17f6c-596c-b58e-dbcb-f4cf5795da9d/125420.jpg/600x600bb.jpg",
          ),
          duration: "3:16",
        ),
        .init(
          id: "1803507268",
          title: "A-K & Ivan",
          artist: "Spöket i Köket",
          albumTitle: "Grannlåt",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/b9/01/55/b90155d7-ea39-97ed-0c39-c8d4562c150d/113590.jpg/600x600bb.jpg",
          ),
          duration: "5:38",
        ),
      ]
  }

  fileprivate extension [ArtistReleaseData] {
    static let previewSpoketIKoketReleases:
      [ArtistReleaseData] = [
        .init(
          id: "1803507096",
          title: "Grannlåt",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/b9/01/55/b90155d7-ea39-97ed-0c39-c8d4562c150d/113590.jpg/600x600bb.jpg",
          ),
          releaseDate: "2025-06-06",
          trackCount: 8,
          releaseType: "Album",
        ),
        .init(
          id: "1638997824",
          title: "Kurbits & Flames",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/77/c6/d5/77c6d545-30e2-35a1-592e-b9c1d227f65f/7320470263310.png/600x600bb.jpg",
          ),
          releaseDate: "2022-09-03",
          trackCount: 10,
          releaseType: "Album",
        ),
        .init(
          id: "1458352510",
          title: "Château du Garage",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music123/v4/76/03/a1/7603a13f-0370-282d-dc9a-eb02e7b44cc2/cover.jpg/600x600bb.jpg",
          ),
          releaseDate: "2019-04-12",
          trackCount: 14,
          releaseType: "Album",
        ),
        .init(
          id: "1505856391",
          title: "Den nya spisen",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/ed/a5/22/eda522e2-89d2-4d30-0e4c-c0a2233107c0/73495.jpg/600x600bb.jpg",
          ),
          releaseDate: "2017-03-17",
          trackCount: 12,
          releaseType: "Album",
        ),
        .init(
          id: "1885416347",
          title: "Hits från förr - EP",
          artist: "Spöket i Köket & Åkervinda",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/c2/f1/7f/c2f17f6c-596c-b58e-dbcb-f4cf5795da9d/125420.jpg/600x600bb.jpg",
          ),
          releaseDate: "2026-04-17",
          trackCount: 4,
          releaseType: "EP",
        ),
        .init(
          id: "1885416250",
          title: "Inte flyttar jag till sjöss - Single",
          artist: "Spöket i Köket & Åkervinda",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/2e/1b/17/2e1b1764-fb5e-839b-db2d-32b1ea872bde/125427.jpg/600x600bb.jpg",
          ),
          releaseDate: "2026-04-17",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1885416071",
          title: "Gammal och ung - Single",
          artist: "Spöket i Köket & Åkervinda",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0e/3a/07/0e3a07f7-4a6d-f2e0-6d71-3a4dba1ff2ae/125426.jpg/600x600bb.jpg",
          ),
          releaseDate: "2026-04-10",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1885415371",
          title: "Nattvandrare - Single",
          artist: "Spöket i Köket & Åkervinda",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/5a/ba/f4/5abaf464-7d71-1719-0e48-c2b23d71bf7f/125425.jpg/600x600bb.jpg",
          ),
          releaseDate: "2026-04-03",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1885415415",
          title: "Öppna ditt fönster - Single",
          artist: "Spöket i Köket & Åkervinda",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/6e/ff/07/6eff07a2-551d-50db-dbd1-bd344a941b9b/125424.jpg/600x600bb.jpg",
          ),
          releaseDate: "2026-03-27",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1803507386",
          title: "Turbomoppen - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/4b/80/b8/4b80b800-1c8c-4369-3694-945d5aa88989/113586.jpg/600x600bb.jpg",
          ),
          releaseDate: "2025-05-23",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1803507194",
          title: "Poesipolska - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/8f/ba/60/8fba60ce-7b86-0db8-9c19-763a5512715c/113585.jpg/600x600bb.jpg",
          ),
          releaseDate: "2025-05-09",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1803506280",
          title: "Bjagnes - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d9/79/ba/d979ba40-f160-0f1b-a931-44ac2a16d279/113584.jpg/600x600bb.jpg",
          ),
          releaseDate: "2025-04-25",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1633613183",
          title: "Shuffle Bonanza - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/80/9f/9f/809f9f51-b853-b977-c273-fe492e1f2162/634457110861.png/600x600bb.jpg",
          ),
          releaseDate: "2022-08-18",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1633613059",
          title: "Polska Från Medelpad - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/26/8d/a8/268da898-a00b-2f2f-0398-526b1c40346d/634457110854.png/600x600bb.jpg",
          ),
          releaseDate: "2022-07-28",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1631472811",
          title: "Värmlandsnytt - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/17/44/8d/17448d51-6b35-78c7-8879-5cfb7b4d28b2/634457109780.png/600x600bb.jpg",
          ),
          releaseDate: "2022-07-07",
          trackCount: 1,
          releaseType: "Single",
        ),
        .init(
          id: "1455983165",
          title: "Light Is Dim / Hommage aux frères pigeon - Single",
          artist: "Spöket i Köket",
          artworkUrl: URL(
            string:
            "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/78/27/e7/7827e700-5bb0-a41a-9e9a-f58a910b68f3/cover.jpg/600x600bb.jpg",
          ),
          releaseDate: "2019-03-20",
          trackCount: 1,
          releaseType: "Single",
        ),
      ]
  }
#endif
