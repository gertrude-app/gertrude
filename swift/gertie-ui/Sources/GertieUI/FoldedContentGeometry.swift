import SwiftUI

public struct FoldedContentGeometry: Equatable {
  public let containerSize: CGSize
  public let division: CGRect
  public let axis: Axis

  public var primarySize: CGSize {
    switch self.axis {
    case .horizontal:
      CGSize(width: self.division.minX, height: self.containerSize.height)
    case .vertical:
      CGSize(width: self.containerSize.width, height: self.division.minY)
    }
  }

  public var secondarySize: CGSize {
    switch self.axis {
    case .horizontal:
      CGSize(
        width: self.containerSize.width - self.division.maxX,
        height: self.containerSize.height,
      )
    case .vertical:
      CGSize(
        width: self.containerSize.width,
        height: self.containerSize.height - self.division.maxY,
      )
    }
  }

  public var spacing: CGFloat {
    self.axis == .horizontal ? self.division.width : self.division.height
  }

  public static func resolve(in proxy: GeometryProxy, includeInactive: Bool = false) -> Self? {
    self.resolve(
      containerSize: proxy.size,
      divisions: self.divisions(in: proxy, includeInactive: includeInactive),
      includeInactive: includeInactive,
    )
  }

  public static func divisions(in proxy: GeometryProxy, includeInactive: Bool = false) -> [CGRect] {
    #if os(iOS) && canImport(SwiftUI, _version: 8.0.85)
      if #available(iOS 27.1, *) {
        return proxy.reservedRegions(
          kind: .division,
          options: includeInactive ? .includeInactive : [],
        ).map(\.frame)
      }
    #endif
    return []
  }

  public static func resolve(
    containerSize: CGSize,
    divisions: [CGRect],
    includeInactive: Bool = false,
  ) -> Self? {
    guard containerSize.width.isFinite, containerSize.height.isFinite,
          containerSize.width > 0, containerSize.height > 0 else { return nil }

    for frame in divisions {
      guard !frame.isNull, !frame.isInfinite,
            frame.size.width >= 0, frame.size.height >= 0,
            !frame.isEmpty || includeInactive else { continue }

      if frame.width > frame.height,
         frame.minX <= 0, frame.maxX >= containerSize.width,
         frame.minY > 0, frame.maxY < containerSize.height {
        return Self(containerSize: containerSize, division: frame, axis: .vertical)
      }

      if frame.height > frame.width,
         frame.minY <= 0, frame.maxY >= containerSize.height,
         frame.minX > 0, frame.maxX < containerSize.width {
        return Self(containerSize: containerSize, division: frame, axis: .horizontal)
      }
    }

    return nil
  }
}
