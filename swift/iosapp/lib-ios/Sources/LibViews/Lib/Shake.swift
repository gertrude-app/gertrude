import LibCore
import SwiftUI

#if os(iOS)
  import UIKit

  extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
      if motion == .motionShake {
        NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
      }
    }
  }
#endif

struct DeviceShakeViewModifier: ViewModifier {
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .onAppear()
      .onReceive(
        NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification),
      ) { _ in
        self.action()
      }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self.modifier(DeviceShakeViewModifier(action: action))
  }

  @ViewBuilder
  func pageSheet() -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      self.presentationSizing(.page)
    } else {
      self
    }
  }
}
