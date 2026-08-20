import Foundation
import GertieUI
import SwiftUI

#if os(iOS)
  import UIKit

  struct NowPlayingBarAtmosphere: UIViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    let isActive: Bool

    func makeUIView(context: Context) -> NowPlayingCloudAnimationView {
      NowPlayingCloudAnimationView(clouds: Self.clouds)
    }

    func updateUIView(_ view: NowPlayingCloudAnimationView, context: Context) {
      view.update(
        isVisible: self.isActive,
        animationsEnabled: self.isActive
          && !self.reduceMotion
          && self.scenePhase == .active,
        colorScheme: self.colorScheme,
      )
    }

    static func dismantleUIView(_ view: NowPlayingCloudAnimationView, coordinator: ()) {
      view.stop()
    }

    private static let clouds = [
      Cloud(
        id: 0,
        palette: .violet,
        widthFraction: 0.38,
        minimumWidth: 118,
        height: 19,
        horizontalPosition: 0.18,
        horizontalTravel: 0.24,
        verticalPosition: 0.82,
        verticalTravel: 3.4,
        speed: 0.23,
        phase: 0.1,
        widthVariation: 0.18,
        heightVariation: 0.30,
        blurRadius: 5.2,
        opacity: 0.58,
      ),
      Cloud(
        id: 1,
        palette: .fuchsia,
        widthFraction: 0.31,
        minimumWidth: 96,
        height: 15,
        horizontalPosition: 0.72,
        horizontalTravel: 0.30,
        verticalPosition: 0.88,
        verticalTravel: 4.6,
        speed: 0.29,
        phase: 1.4,
        widthVariation: 0.24,
        heightVariation: 0.38,
        blurRadius: 4.4,
        opacity: 0.62,
      ),
      Cloud(
        id: 2,
        palette: .violetLight,
        widthFraction: 0.22,
        minimumWidth: 70,
        height: 11,
        horizontalPosition: 0.46,
        horizontalTravel: 0.41,
        verticalPosition: 0.66,
        verticalTravel: 3.1,
        speed: 0.37,
        phase: 2.8,
        widthVariation: 0.28,
        heightVariation: 0.22,
        blurRadius: 3.6,
        opacity: 0.52,
      ),
      Cloud(
        id: 3,
        palette: .fuchsiaDeep,
        widthFraction: 0.18,
        minimumWidth: 58,
        height: 20,
        horizontalPosition: 0.12,
        horizontalTravel: 0.23,
        verticalPosition: 1.02,
        verticalTravel: 5.2,
        speed: 0.41,
        phase: 4.5,
        widthVariation: 0.20,
        heightVariation: 0.42,
        blurRadius: 5.8,
        opacity: 0.48,
      ),
      Cloud(
        id: 4,
        palette: .violet,
        widthFraction: 0.27,
        minimumWidth: 84,
        height: 9,
        horizontalPosition: 0.86,
        horizontalTravel: 0.21,
        verticalPosition: 0.62,
        verticalTravel: 2.8,
        speed: 0.47,
        phase: 5.9,
        widthVariation: 0.32,
        heightVariation: 0.34,
        blurRadius: 3.1,
        opacity: 0.54,
      ),
      Cloud(
        id: 5,
        palette: .fuchsia,
        widthFraction: 0.44,
        minimumWidth: 136,
        height: 8,
        horizontalPosition: 0.54,
        horizontalTravel: 0.26,
        verticalPosition: 1.0,
        verticalTravel: 2.4,
        speed: 0.19,
        phase: 7.2,
        widthVariation: 0.14,
        heightVariation: 0.48,
        blurRadius: 4.8,
        opacity: 0.44,
      ),
      Cloud(
        id: 6,
        palette: .violetLight,
        widthFraction: 0.15,
        minimumWidth: 50,
        height: 13,
        horizontalPosition: 0.32,
        horizontalTravel: 0.35,
        verticalPosition: 0.90,
        verticalTravel: 4.1,
        speed: 0.53,
        phase: 8.8,
        widthVariation: 0.36,
        heightVariation: 0.26,
        blurRadius: 3.8,
        opacity: 0.50,
      ),
      Cloud(
        id: 7,
        palette: .fuchsiaDeep,
        widthFraction: 0.24,
        minimumWidth: 76,
        height: 16,
        horizontalPosition: 0.64,
        horizontalTravel: 0.34,
        verticalPosition: 0.72,
        verticalTravel: 3.7,
        speed: 0.34,
        phase: 10.6,
        widthVariation: 0.22,
        heightVariation: 0.44,
        blurRadius: 5.0,
        opacity: 0.46,
      ),
      Cloud(
        id: 8,
        palette: .violet,
        widthFraction: 0.12,
        minimumWidth: 42,
        height: 7,
        horizontalPosition: 0.92,
        horizontalTravel: 0.38,
        verticalPosition: 0.84,
        verticalTravel: 3.3,
        speed: 0.61,
        phase: 12.1,
        widthVariation: 0.42,
        heightVariation: 0.50,
        blurRadius: 2.8,
        opacity: 0.56,
      ),
    ]
  }

  @MainActor
  final class NowPlayingCloudAnimationView: UIView {
    private let clouds: [Cloud]
    private var cloudLayers: [CAGradientLayer] = []
    private var colorScheme = ColorScheme.light
    private var animationsEnabled = false
    private var isVisible = false
    private var lastSize = CGSize.zero

    fileprivate init(clouds: [Cloud]) {
      self.clouds = clouds
      super.init(frame: .zero)
      self.alpha = 0
      self.clipsToBounds = true
      self.isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError()
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      guard self.bounds.size != self.lastSize,
            self.bounds.width > 0,
            self.bounds.height > 0 else { return }
      self.lastSize = self.bounds.size
      self.rebuildCloudLayers()
    }

    func update(
      isVisible: Bool,
      animationsEnabled: Bool,
      colorScheme: ColorScheme,
    ) {
      if self.colorScheme != colorScheme {
        self.colorScheme = colorScheme
        self.updateColors()
      }
      if self.animationsEnabled != animationsEnabled {
        self.animationsEnabled = animationsEnabled
        self.updateAnimations()
      }
      guard self.isVisible != isVisible else { return }
      self.isVisible = isVisible
      self.alpha = isVisible ? 1 : 0
    }

    func stop() {
      for layer in self.cloudLayers {
        layer.removeAllAnimations()
      }
    }

    private func rebuildCloudLayers() {
      for layer in self.cloudLayers {
        layer.removeFromSuperlayer()
      }
      self.cloudLayers = self.clouds.map { cloud in
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.locations = [0, 0.48, 1]
        layer.drawsAsynchronously = true
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        self.layer.addSublayer(layer)
        return layer
      }
      self.updateColors()
      self.updateAnimations()
    }

    private func updateColors() {
      for (cloud, layer) in zip(self.clouds, self.cloudLayers) {
        let color = UIColor(cloud.palette.color(in: self.colorScheme))
        layer.colors = [
          color.cgColor,
          color.withAlphaComponent(0.44).cgColor,
          color.withAlphaComponent(0).cgColor,
        ]
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = cloud.blurRadius
        layer.shadowOffset = .zero
      }
    }

    private func updateAnimations() {
      guard self.cloudLayers.count == self.clouds.count else { return }
      for (cloud, layer) in zip(self.clouds, self.cloudLayers) {
        layer.removeAllAnimations()
        let progress = self.animationsEnabled
          ? CGFloat.zero
          : (CGFloat(cloud.id) * 0.137).truncatingRemainder(dividingBy: 1)
        self.apply(
          cloud.rendering(progress: progress, containerSize: self.bounds.size),
          to: layer,
        )
        if self.animationsEnabled {
          layer.add(self.animation(for: cloud), forKey: "atmosphere")
        }
      }
    }

    private func animation(for cloud: Cloud) -> CAAnimationGroup {
      let frameCount = 49
      let renderings = (0 ..< frameCount).map { frame in
        cloud.rendering(
          progress: CGFloat(frame) / CGFloat(frameCount - 1),
          containerSize: self.bounds.size,
        )
      }
      let keyTimes = (0 ..< frameCount).map {
        NSNumber(value: Double($0) / Double(frameCount - 1))
      }
      let position = CAKeyframeAnimation(keyPath: "position")
      position.values = renderings.map(\.center)
      position.keyTimes = keyTimes
      let scaleX = CAKeyframeAnimation(keyPath: "transform.scale.x")
      scaleX.values = renderings.map(\.scaleX)
      scaleX.keyTimes = keyTimes
      let scaleY = CAKeyframeAnimation(keyPath: "transform.scale.y")
      scaleY.values = renderings.map(\.scaleY)
      scaleY.keyTimes = keyTimes
      let opacity = CAKeyframeAnimation(keyPath: "opacity")
      opacity.values = renderings.map(\.opacity)
      opacity.keyTimes = keyTimes
      let group = CAAnimationGroup()
      group.animations = [position, scaleX, scaleY, opacity]
      group.duration = cloud.duration
      group.repeatCount = .infinity
      group.timingFunction = CAMediaTimingFunction(name: .linear)
      group.isRemovedOnCompletion = false
      return group
    }

    private func apply(_ rendering: Cloud.Rendering, to layer: CAGradientLayer) {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      layer.bounds = CGRect(origin: .zero, size: rendering.baseSize)
      layer.position = rendering.center
      layer.opacity = Float(rendering.opacity)
      layer.transform = CATransform3DMakeScale(
        rendering.scaleX,
        rendering.scaleY,
        1,
      )
      CATransaction.commit()
    }
  }

  private struct Cloud: Identifiable, Sendable {
    struct Rendering {
      let center: CGPoint
      let baseSize: CGSize
      let scaleX: CGFloat
      let scaleY: CGFloat
      let opacity: Double
    }

    enum Palette: Sendable {
      case fuchsia
      case fuchsiaDeep
      case violet
      case violetLight

      func color(in colorScheme: ColorScheme) -> Color {
        switch self {
        case .fuchsia:
          Color(colorScheme, light: .fuchsia500, dark: .fuchsia400)
        case .fuchsiaDeep:
          Color(colorScheme, light: .fuchsia600, dark: .fuchsia500)
        case .violet:
          Color(colorScheme, light: .violet500, dark: .violet400)
        case .violetLight:
          Color(colorScheme, light: .violet300, dark: .violet500)
        }
      }
    }

    let id: Int
    let palette: Palette
    let widthFraction: CGFloat
    let minimumWidth: CGFloat
    let height: CGFloat
    let horizontalPosition: CGFloat
    let horizontalTravel: CGFloat
    let verticalPosition: CGFloat
    let verticalTravel: CGFloat
    let speed: Double
    let phase: Double
    let widthVariation: CGFloat
    let heightVariation: CGFloat
    let blurRadius: CGFloat
    let opacity: Double
    var duration: TimeInterval {
      max(11, min(30, 1.6 * .pi / self.speed))
    }

    func rendering(progress: CGFloat, containerSize: CGSize) -> Rendering {
      let horizontalMotion = Self.organicWave(
        progress: progress,
        phase: self.phase,
        frequencies: (1, 2, 4),
      )
      let verticalMotion = Self.organicWave(
        progress: progress,
        phase: self.phase + 2.1,
        frequencies: (1, 3, 5),
      )
      let widthMotion = Self.organicWave(
        progress: progress,
        phase: self.phase + 4.3,
        frequencies: (2, 3, 5),
      )
      let heightMotion = Self.organicWave(
        progress: progress,
        phase: self.phase + 6.7,
        frequencies: (1, 4, 6),
      )
      let opacityMotion = Self.organicWave(
        progress: progress,
        phase: self.phase + 9.2,
        frequencies: (2, 5, 7),
      )
      let swellMotion = Self.organicWave(
        progress: progress,
        phase: self.phase + 15.8,
        frequencies: (1, 3, 7),
      )
      let swellProgress = pow((Double(swellMotion) + 1) / 2, 4)
      let baseWidth = max(self.minimumWidth, containerSize.width * self.widthFraction)
      let renderedWidth = baseWidth * 1.4 * (1 + widthMotion * self.widthVariation)
      let renderedHeight = self.height
        * (1 + heightMotion * self.heightVariation)
        * (1 + CGFloat(swellProgress) * 0.35)
      let x = containerSize.width * (self.horizontalPosition
        + horizontalMotion * self.horizontalTravel)
      let anchorDepth = 1 + max(0, self.verticalPosition - 0.62) * 2
      let verticalDrift = min(1, self.verticalTravel * 0.2)
      let y = containerSize.height
        - renderedHeight / 2
        + anchorDepth
        + (verticalMotion + 1) / 2 * verticalDrift
      let opacity = self.opacity
        * (0.88 + Double(opacityMotion) * 0.12)
        * (1 + swellProgress * 0.15)
      return Rendering(
        center: CGPoint(x: x, y: y),
        baseSize: CGSize(width: baseWidth * 1.4, height: self.height),
        scaleX: renderedWidth / (baseWidth * 1.4),
        scaleY: renderedHeight / self.height,
        opacity: opacity,
      )
    }

    private static func organicWave(
      progress: CGFloat,
      phase: Double,
      frequencies: (Double, Double, Double),
    ) -> CGFloat {
      let angle = Double(progress) * 2 * .pi
      let value = sin(angle * frequencies.0 + phase) * 0.52
        + sin(angle * frequencies.1 + phase * 1.73) * 0.29
        + sin(angle * frequencies.2 - phase * 0.47) * 0.19
      return CGFloat(value)
    }
  }
#endif
