#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import GertieUI

  @MainActor
  struct RenderedScreenRegions {
    let red: CGRect
    let green: CGRect
    let blue: CGRect

    init(
      containerSize: CGSize,
      @ViewBuilder content: () -> some View,
    ) throws {
      let layout = content()
        .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
      let host = NSHostingView(rootView: layout) // ImageRenderer omits native ScrollView content.
      host.frame = CGRect(origin: .zero, size: containerSize)
      host.layoutSubtreeIfNeeded()
      let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
      host
        .cacheDisplay(
          in: host.bounds,
          to: bitmap,
        ) // Settle geometry-driven layout before measuring.
      host.layoutSubtreeIfNeeded()
      host.cacheDisplay(in: host.bounds, to: bitmap)
      let image = try #require(bitmap.cgImage)
      var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
      var bounds = [CGRect](repeating: .null, count: 3)

      let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
      try pixels.withUnsafeMutableBytes { bytes in
        let context = try #require(CGContext(
          data: bytes.baseAddress,
          width: image.width,
          height: image.height,
          bitsPerComponent: 8,
          bytesPerRow: image.width * 4,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue,
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
      }

      for y in 0 ..< image.height {
        for x in 0 ..< image.width {
          let offset = (y * image.width + x) * 4
          let pixel = CGRect(x: x, y: y, width: 1, height: 1)
          for component in 0 ..< 3 where pixels[offset + component] > 200
            && pixels[offset + (component + 1) % 3] < 100
            && pixels[offset + (component + 2) % 3] < 100 {
            bounds[component] = bounds[component].union(pixel)
          }
        }
      }

      let pointScale = CGAffineTransform(
        scaleX: containerSize.width / CGFloat(image.width),
        y: containerSize.height / CGFloat(image.height),
      )
      self.red = bounds[0].applying(pointScale)
      self.green = bounds[1].applying(pointScale)
      self.blue = bounds[2].applying(pointScale)
    }
  }
#endif
