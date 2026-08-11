import SwiftUI

#if canImport(UIKit)
  import UIKit
#else
  import AppKit
#endif

// NB: duplicated verbatim in the podcasts and blocker apps — hoist into
// GertieUI (swift/gertie-ui) once #861 lands, and keep the copies in sync until then
public struct RetryingAsyncImage<Content: View, Placeholder: View>: View {
  let url: URL
  let maxAttempts: Int
  let animation: Animation?
  let onFailure: (@MainActor @Sendable (any Error) -> Void)?
  let content: (Image) -> Content
  let placeholder: () -> Placeholder

  @State private var image: Image?
  @State private var failed = false

  public init(
    url: URL,
    maxAttempts: Int = 3,
    animation: Animation? = nil,
    onFailure: (@MainActor @Sendable (any Error) -> Void)? = nil,
    @ViewBuilder content: @escaping (Image) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder,
  ) {
    self.url = url
    self.maxAttempts = maxAttempts
    self.animation = animation
    self.onFailure = onFailure
    self.content = content
    self.placeholder = placeholder
  }

  public var body: some View {
    Group {
      if let image = self.image {
        self.content(image)
      } else if !self.failed {
        self.placeholder()
      }
    }
    .task(id: self.url) {
      await self.load()
    }
  }

  private func load() async {
    self.failed = false
    for attempt in 1 ... self.maxAttempts {
      do {
        let (data, response) = try await URLSession.shared.data(from: self.url)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
          throw RemoteImageError.httpStatus(http.statusCode)
        }
        guard let image = Image(data: data) else {
          throw RemoteImageError.undecodable(bytes: data.count)
        }
        withAnimation(self.animation) { self.image = image }
        return
      } catch {
        if Task.isCancelled { return }
        if attempt == self.maxAttempts {
          self.failed = true
          self.onFailure?(error)
          return
        }
        try? await Task.sleep(for: .milliseconds(150 * attempt))
      }
    }
  }
}

public enum RemoteImageError: Error {
  case httpStatus(Int)
  case undecodable(bytes: Int)
}

private extension Image {
  init?(data: Data) {
    #if canImport(UIKit)
      guard let image = UIImage(data: data) else { return nil }
      self.init(uiImage: image)
    #else
      guard let image = NSImage(data: data) else { return nil }
      self.init(nsImage: image)
    #endif
  }
}
