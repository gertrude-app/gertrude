import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI

#if !os(iOS)
  import AppKit

  public enum TextInputAutocapitalization {
    case never, words, sentences, allCharacters
  }

  public extension View {
    nonisolated
    func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization?)
      -> some View {
      EmptyView()
    }
  }

  public extension ToolbarItemPlacement {
    static var navigationBarLeading: Self { .automatic }
    static var navigationBarTrailing: Self { .automatic }
  }

  @MainActor
  public class UIDevice {
    public enum UserInterfaceIdiom {
      case phone, pad, tv, carPlay, mac, unspecified
    }

    public static let current = UIDevice()
    public var userInterfaceIdiom: UserInterfaceIdiom { .phone }
    public var NOT_REAL_CHECK_XCODE: String { "" }
    public var systemVersion: String { "26.1.2" }
  }

  public struct UIImage {
    public init?(data: Data) {}
    public init?(named name: String) {}
    public var size: CGSize { CGSize(width: 100, height: 100) }
    public var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in .init() }
    }

    public func jpegData(compressionQuality: CGFloat) -> Data? { nil }
    public var NOT_REAL_CHECK_XCODE: String { "" }
  }

  public let AVAudioSessionInterruptionOptionKey = ""
  public let AVAudioSessionInterruptionTypeKey = ""

  public struct AVAudioSession {
    public enum Category { case playback, NOT_REAL_CHECK_XCODE }
    public enum Mode { case spokenAudio, NOT_REAL_CHECK_XCODE }
    public enum InterruptionType {
      case began
      case ended

      public init?(rawValue: UInt) {
        switch rawValue {
        case 1: self = .began
        case 0: self = .ended
        default: return nil
        }
      }
    }

    public struct InterruptionOptions: OptionSet {
      public let rawValue: UInt
      public nonisolated(unsafe) static let shouldResume = InterruptionOptions(rawValue: 1 << 0)
      public init(rawValue: UInt) {
        self.rawValue = rawValue
      }

      public var NOT_REAL_CHECK_XCODE: String { "" }
    }

    public var NOT_REAL_CHECK_XCODE: String { "" }

    public static var interruptionNotification: Notification.Name {
      Notification.Name("")
    }

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

  public class BGTask: Equatable {
    public var identifier: String
    public var expirationHandler: (() -> Void)? = nil

    public func setTaskCompleted(success: Bool) {}
    public init(identifier: String? = nil) {
      self.identifier = identifier ?? UUID().uuidString
    }

    public static func == (lhs: BGTask, rhs: BGTask) -> Bool {
      lhs.identifier == rhs.identifier
    }
  }

  public class BGAppRefreshTask: BGTask {}
  public class BGProcessingTask: BGTask {}

  public final class BGTaskScheduler {
    public nonisolated(unsafe) static let shared = BGTaskScheduler()

    @discardableResult
    public func register(
      forTaskWithIdentifier identifier: String,
      using queue: DispatchQueue?,
      launchHandler: @escaping (BGTask) -> Void
    ) -> Bool {
      true
    }

    public func submit(_ request: BGTaskRequest) throws {}

    public var NOT_REAL_CHECK_XCODE: String { "" }
  }

  public class BGTaskRequest {
    public var identifier: String
    public var earliestBeginDate: Date?
    public var NOT_REAL_CHECK_XCODE: String { "" }
    public init(identifier: String) {
      self.identifier = identifier
    }
  }

  public class BGAppRefreshTaskRequest: BGTaskRequest {}
  public class BGProcessingTaskRequest: BGTaskRequest {
    public var requiresNetworkConnectivity: Bool = false
    public var requiresExternalPower: Bool = false
  }

#else
  import BackgroundTasks
  import UIKit

  public typealias UIDevice = UIKit.UIDevice
  public typealias UIImage = UIKit.UIImage
  public typealias UIApplication = UIKit.UIApplication
  public typealias UIImpactFeedbackGenerator = UIKit.UIImpactFeedbackGenerator
  public typealias UINotificationFeedbackGenerator = UIKit.UINotificationFeedbackGenerator
  public typealias UISelectionFeedbackGenerator = UIKit.UISelectionFeedbackGenerator
  public typealias BGTask = BackgroundTasks.BGTask
  public typealias BGAppRefreshTask = BackgroundTasks.BGAppRefreshTask
  public typealias BGProcessingTask = BackgroundTasks.BGProcessingTask
  public typealias BGTaskScheduler = BackgroundTasks.BGTaskScheduler
  public typealias BGTaskRequest = BackgroundTasks.BGTaskRequest
  public typealias BGAppRefreshTaskRequest = BackgroundTasks.BGAppRefreshTaskRequest
  public typealias BGProcessingTaskRequest = BackgroundTasks.BGProcessingTaskRequest

  public extension UIImage {
    var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in self }
    }
  }
#endif
