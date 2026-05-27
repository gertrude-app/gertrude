import Foundation
import SwiftUI

#if os(iOS)
  import UIKit
  typealias PlatformArtworkImage = UIImage
#elseif os(macOS)
  import AppKit
  typealias PlatformArtworkImage = NSImage
#endif

@MainActor
final class ArtworkImageCache {
  static let shared = ArtworkImageCache()

  private let cache = NSCache<NSURL, PlatformArtworkImage>()
  private var inFlightLoads: [URL: Task<Data?, Never>] = [:]

  private init() {
    self.cache.totalCostLimit = 80 * 1024 * 1024
  }

  func cachedImage(for url: URL?) -> PlatformArtworkImage? {
    guard let url else { return nil }
    return self.cache.object(forKey: url as NSURL)
  }

  func image(for url: URL) async -> PlatformArtworkImage? {
    if let image = self.cachedImage(for: url) { return image }

    let data = await self.data(for: url)
    if let image = self.cachedImage(for: url) { return image }
    guard let data, let image = PlatformArtworkImage(data: data) else { return nil }

    self.cache.setObject(image, forKey: url as NSURL, cost: data.count)
    return image
  }

  private func data(for url: URL) async -> Data? {
    if let task = self.inFlightLoads[url] {
      return await task.value
    }

    let task = Task.detached(priority: .utility) { () -> Data? in
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
      } catch {
        return nil
      }
    }

    self.inFlightLoads[url] = task
    let data = await task.value
    self.inFlightLoads[url] = nil
    return data
  }
}

struct CachedArtworkImageView<Content: View, Placeholder: View>: View {
  let url: URL?
  @ViewBuilder let content: (Image) -> Content
  @ViewBuilder let placeholder: () -> Placeholder

  @State private var loadedArtwork: LoadedArtwork?

  var body: some View {
    Group {
      if let image = self.currentImage {
        self.content(Image(platformArtworkImage: image))
      } else {
        self.placeholder()
      }
    }
    .task(id: self.url) {
      await self.loadImage()
    }
  }

  private var currentImage: PlatformArtworkImage? {
    guard let url = self.url else { return nil }
    if self.loadedArtwork?.url == url { return self.loadedArtwork?.image }
    return ArtworkImageCache.shared.cachedImage(for: url)
  }

  private func loadImage() async {
    guard let url = self.url else {
      self.loadedArtwork = nil
      return
    }

    if let image = ArtworkImageCache.shared.cachedImage(for: url) {
      self.loadedArtwork = .init(url: url, image: image)
      return
    }

    guard let image = await ArtworkImageCache.shared.image(for: url), !Task.isCancelled else { return }
    self.loadedArtwork = .init(url: url, image: image)
  }
}

private struct LoadedArtwork {
  let url: URL
  let image: PlatformArtworkImage
}

private extension Image {
  init(platformArtworkImage image: PlatformArtworkImage) {
    #if os(iOS)
      self.init(uiImage: image)
    #elseif os(macOS)
      self.init(nsImage: image)
    #endif
  }
}
