import SwiftUI

public struct AlbumDetailView: View {
    private let album: AlbumData
    private let rows: [AlbumDetailTrackRow]
    private let transitionSourceID: String?
    private let onPlayTap: @MainActor @Sendable () -> Void
    private let onTrackTap: @MainActor @Sendable (String) -> Void

    public init(
        album: AlbumData,
        tracks: [TrackData],
        transitionSourceID: String? = nil,
        onPlayTap: @MainActor @escaping @Sendable () -> Void = {},
        onTrackTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    ) {
        self.album = album
        self.transitionSourceID = transitionSourceID
        self.onPlayTap = onPlayTap
        self.onTrackTap = onTrackTap
        self.rows = tracks.enumerated().map { index, track in
            AlbumDetailTrackRow(number: index + 1, track: track)
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        ZStack {
                            CachedArtworkImageView(url: self.album.artworkUrl) {
                                image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .scaleEffect(6)
                                    .blur(radius: 60)
                                    .opacity(0.3)
                            } placeholder: {
                                Color.clear
                                    .frame(width: 100, height: 100)
                            }

                            ZoomableAlbumArtworkView(
                                album: self.album,
                                size: self.artworkSize(for: proxy.size.width),
                                cornerRadius: 32,
                                transitionID: self.artworkTransitionID,
                                role: .destination,
                            )
                        }

                        VStack(spacing: 5) {
                            Text(self.album.title)
                                .font(
                                    .system(
                                        size: 26,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)

                            Text(self.album.artist)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 28)

                        AlbumDetailPlayButton(onTap: self.onPlayTap)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)

                    if self.rows.isEmpty {
                        AlbumDetailEmptyTracksView()
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(self.rows) { row in
                                AlbumDetailTrackRowView(row: row) {
                                    self.onTrackTap(row.track.id)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
            .background(.background)
        }
        .navigationTitle("")
    }

    private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
        min(320, max(220, containerWidth - 96))
    }

    private var artworkTransitionID: String {
        albumArtworkZoomTransitionID(
            for: self.transitionSourceID ?? self.album.id
        )
    }
}

private struct AlbumDetailPlayButton: View {
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
        Button(action: self.onTap) {
            Label("Play", systemImage: "play.fill")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(Color.gertrudeBrandAccent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AlbumDetailTrackRow: Identifiable, Equatable {
    let number: Int
    let track: TrackData

    var id: String { self.track.id }
}

private struct AlbumDetailTrackRowView: View {
    let row: AlbumDetailTrackRow
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 12) {
                Text(self.row.number, format: .number)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)

                VStack(alignment: .leading, spacing: 3) {
                    Text(self.row.track.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(self.row.track.artist)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.row.number). \(self.row.track.title), \(self.row.track.artist)")
    }
}

private struct AlbumDetailEmptyTracksView: View {
    var body: some View {
        Text("No tracks yet")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                .primary.opacity(0.05),
                in: .rect(cornerRadius: 24, style: .continuous)
            )
    }
}

#Preview("Album detail") {
    NavigationStack {
        AlbumDetailView(
            album: [AlbumData].previewAlbums[0],
            tracks: .previewTracks,
        )
    }
}
