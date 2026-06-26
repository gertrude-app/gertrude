import SwiftUI

struct AlbumGridView: View {
  private let albums: [AlbumData]
  private let isLoading: Bool
  private let transitionNamespace: Namespace.ID?
  private let onAlbumTap: @MainActor @Sendable (String) -> Void
  private let onDebugResetTap: (@MainActor @Sendable () -> Void)?

  init(
    albums: [AlbumData],
    isLoading: Bool = false,
    transitionNamespace: Namespace.ID? = nil,
    onAlbumTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
    onDebugResetTap: (@MainActor @Sendable () -> Void)? = nil,
  ) {
    self.albums = albums
    self.isLoading = isLoading
    self.transitionNamespace = transitionNamespace
    self.onAlbumTap = onAlbumTap
    self.onDebugResetTap = onDebugResetTap
  }

  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        if self.isLoading {
          self.loadingGrid(containerWidth: proxy.size.width)
        } else if self.albums.isEmpty {
          AlbumGridEmptyStateView()
            .padding(.horizontal, self.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, self.bottomContentPadding)
        } else {
          self.albumGrid(containerWidth: proxy.size.width)

          #if DEBUG
            if let onDebugResetTap = self.onDebugResetTap {
              DebugResetOnboardingButton(onTap: onDebugResetTap)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.horizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, self.bottomContentPadding)
            }
          #endif
        }
      }
      .background(.background)
    }
  }

  private let horizontalPadding: CGFloat = 20
  private let columnSpacing: CGFloat = 16

  private var columns: [GridItem] {
    Array(
      repeating: GridItem(.flexible(minimum: 148), spacing: self.columnSpacing, alignment: .top),
      count: 2,
    )
  }

  private func albumGrid(containerWidth: CGFloat) -> some View {
    LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
      ForEach(self.albums) { album in
        AlbumCardView(
          album: album,
          artworkSize: self.artworkSize(for: containerWidth),
          transitionNamespace: self.transitionNamespace,
        ) {
          self.onAlbumTap(album.id)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(.horizontal, self.horizontalPadding)
    .padding(.top, 16)
    .padding(.bottom, self.albumGridBottomPadding)
  }

  private func loadingGrid(containerWidth: CGFloat) -> some View {
    LazyVGrid(columns: self.columns, alignment: .leading, spacing: 24) {
      ForEach(0 ..< 6, id: \.self) { _ in
        VStack(alignment: .leading, spacing: 10) {
          SkeletonBlock(
            width: self.artworkSize(for: containerWidth),
            height: self.artworkSize(for: containerWidth),
            cornerRadius: 20,
          )

          VStack(alignment: .leading, spacing: 6) {
            SkeletonBlock(width: 132, height: 13, cornerRadius: 6)
            SkeletonBlock(width: 92, height: 11, cornerRadius: 5)
          }
        }
        .frame(width: self.artworkSize(for: containerWidth), alignment: .leading)
      }
    }
    .padding(.horizontal, self.horizontalPadding)
    .padding(.top, 16)
    .padding(.bottom, self.bottomContentPadding)
    .accessibilityLabel("Loading albums")
  }

  private let bottomContentPadding: CGFloat = 96

  private var albumGridBottomPadding: CGFloat {
    #if DEBUG
      self.onDebugResetTap == nil ? self.bottomContentPadding : 8
    #else
      self.bottomContentPadding
    #endif
  }

  private func artworkSize(for containerWidth: CGFloat) -> CGFloat {
    max(148, floor((containerWidth - self.horizontalPadding * 2 - self.columnSpacing) / 2))
  }
}

#if DEBUG
  private struct DebugResetOnboardingButton: View {
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
      Button("Reset onboarding", action: self.onTap)
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .buttonStyle(.bordered)
        .tint(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
  }
#endif

private struct AlbumGridEmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "rectangle.stack")
        .font(.system(size: 30, weight: .semibold))
        .foregroundStyle(.secondary)

      Text("No albums yet")
        .font(.system(size: 18, weight: .semibold))

      Text("Approved albums will show up here.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(28)
    .background(.primary.opacity(0.05), in: .rect(cornerRadius: 24, style: .continuous))
  }
}

#if DEBUG
  #Preview("Album grid") {
    AlbumGridView(albums: .previewAlbums, onDebugResetTap: {})
  }

  #Preview("Album grid empty") {
    AlbumGridView(albums: [])
  }
#endif
