import SwiftUI

struct FoldedContentLayout<Primary: View, Secondary: View>: View {
  private let geometry: FoldedContentGeometry
  private let primary: Primary
  private let secondary: Secondary

  init(
    geometry: FoldedContentGeometry,
    @ViewBuilder primary: (CGSize) -> Primary,
    @ViewBuilder secondary: (CGSize) -> Secondary,
  ) {
    self.geometry = geometry
    self.primary = primary(geometry.primarySize)
    self.secondary = secondary(geometry.secondarySize)
  }

  var body: some View {
    let layout = self.geometry.axis == .horizontal
      ? AnyLayout(HStackLayout(spacing: self.geometry.spacing))
      : AnyLayout(VStackLayout(spacing: self.geometry.spacing))

    layout {
      self.primary
        .frame(width: self.geometry.primarySize.width, height: self.geometry.primarySize.height)

      self.secondary
        .frame(width: self.geometry.secondarySize.width, height: self.geometry.secondarySize.height)
    }
  }
}

struct FoldedContentGeometry: Equatable {
  let containerSize: CGSize
  let division: CGRect
  let axis: Axis

  var primarySize: CGSize {
    switch self.axis {
    case .horizontal:
      CGSize(width: self.division.minX, height: self.containerSize.height)
    case .vertical:
      CGSize(width: self.containerSize.width, height: self.division.minY)
    }
  }

  var secondarySize: CGSize {
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

  var spacing: CGFloat {
    self.axis == .horizontal ? self.division.width : self.division.height
  }

  static func resolve(containerSize: CGSize, divisions: [CGRect]) -> Self? {
    guard containerSize.width.isFinite, containerSize.height.isFinite,
          containerSize.width > 0, containerSize.height > 0 else { return nil }

    for frame in divisions {
      guard !frame.isNull, !frame.isInfinite, !frame.isEmpty else { continue }

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
