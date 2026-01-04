#if !os(iOS)
  import AppKit
  import SwiftUI

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
    public nonisolated(unsafe) static let general = UIPasteboard()
    public var string: String?
  }

  @MainActor
  public class UIScreen: @unchecked Sendable {
    public struct Bounds {
      public var width: CGFloat { 393 }
      public var height: CGFloat { 852 }
    }

    public static let main = UIScreen()
    public var bounds: Bounds { Bounds() }
  }

  public enum UIKeyboardType {
    case numberPad
  }

  public extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View {
      self
    }
  }

#else
  import UIKit

  public typealias UIDevice = UIKit.UIDevice
  public typealias UIPasteboard = UIKit.UIPasteboard
  public typealias UIScreen = UIKit.UIScreen

  public extension UIDevice {
    nonisolated static let deviceDidShakeNotification = Notification
      .Name(rawValue: "deviceDidShakeNotification")
  }
#endif
