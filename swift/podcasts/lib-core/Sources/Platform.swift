import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI

#if !os(iOS)
  import AppKit

  public struct UIImage {
    public init?(data: Data) {}
    public var size: CGSize { CGSize(width: 100, height: 100) }
    public var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in .init() }
    }

    public func jpegData(compressionQuality: CGFloat) -> Data? { nil }
    public var NOT_REAL_CHECK_XCODE: String { "" }
  }

  public struct AVAudioSession {
    public enum Category { case playback, NOT_REAL_CHECK_XCODE }
    public enum Mode { case spokenAudio, NOT_REAL_CHECK_XCODE }
    public var NOT_REAL_CHECK_XCODE: String { "" }

    public static func sharedInstance() -> AVAudioSession {
      AVAudioSession()
    }

    public func setCategory(_ category: Category) throws {}
    public func setMode(_ mode: Mode) throws {}
    public func setActive(_ active: Bool) throws {}
  }

  public enum UIApplication {
    public static let willResignActiveNotification = Notification.Name("")
    public static let didBecomeActiveNotification = Notification.Name("")
    public static let NOT_REAL_CHECK_XCODE = ""
  }

  public extension Image {
    init(uiImage: UIImage) {
      self.init(systemName: "photo")
    }
  }

  public struct UIImpactFeedbackGenerator {
    public enum FeedbackStyle {
      case light, medium, heavy, soft, rigid
      public var NOT_REAL_CHECK_XCODE: String { "" }
    }

    public init(style: FeedbackStyle) {}
    public init() {}
    public func impactOccurred() {}
    public func prepare() {}
    public var NOT_REAL_CHECK_XCODE: String { "" }
  }

  public struct UINotificationFeedbackGenerator {
    public enum FeedbackType {
      case success, warning, error
      public var NOT_REAL_CHECK_XCODE: String { "" }
    }

    public init() {}
    public func notificationOccurred(_ type: FeedbackType) {}
    public func prepare() {}
    public var NOT_REAL_CHECK_XCODE: String { "" }
  }

  public struct UISelectionFeedbackGenerator {
    public init() {}
    public func selectionChanged() {}
    public func prepare() {}
    public var NOT_REAL_CHECK_XCODE: String { "" }
  }
#else
  import UIKit

  public typealias UIImage = UIKit.UIImage
  public typealias UIApplication = UIKit.UIApplication
  public typealias UIImpactFeedbackGenerator = UIKit.UIImpactFeedbackGenerator
  public typealias UINotificationFeedbackGenerator = UIKit.UINotificationFeedbackGenerator
  public typealias UISelectionFeedbackGenerator = UIKit.UISelectionFeedbackGenerator

  public extension UIImage {
    var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in self }
    }
  }
#endif
