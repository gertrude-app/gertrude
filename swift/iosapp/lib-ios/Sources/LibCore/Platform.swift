#if !os(iOS)
  import Foundation

  @MainActor
  public class UIDevice: @unchecked Sendable {
    public enum UserInterfaceIdiom {
      case phone, pad, tv, carPlay, mac, unspecified
    }

    public static let current = UIDevice()
    public var userInterfaceIdiom: UserInterfaceIdiom { .phone }
  }

  public extension UIDevice {
    nonisolated static let deviceDidShakeNotification = Notification
      .Name(rawValue: "deviceDidShakeNotification")
  }

  @MainActor
  public class UIPasteboard: @unchecked Sendable {
    public static let general = UIPasteboard()
    public var string: String?
  }

#else
  import UIKit

  public typealias UIDevice = UIKit.UIDevice
  public typealias UIPasteboard = UIKit.UIPasteboard

  public extension UIDevice {
    nonisolated static let deviceDidShakeNotification = Notification
      .Name(rawValue: "deviceDidShakeNotification")
  }
#endif
