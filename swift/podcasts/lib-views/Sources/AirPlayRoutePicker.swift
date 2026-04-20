import SwiftUI

public struct AirPlayRoutePicker: View {
  let tint: Color
  let activeTint: Color

  public init(tint: Color, activeTint: Color) {
    self.tint = tint
    self.activeTint = activeTint
  }

  public var body: some View {
    #if os(iOS)
      RoutePicker(tint: self.tint, activeTint: self.activeTint)
    #else
      Image(systemName: "airplayaudio")
        .foregroundStyle(self.tint)
    #endif
  }
}

#if os(iOS)
  import AVKit

  private struct RoutePicker: UIViewRepresentable {
    let tint: Color
    let activeTint: Color

    func makeUIView(context: Context) -> AVRoutePickerView {
      let v = AVRoutePickerView()
      v.prioritizesVideoDevices = false
      v.tintColor = UIColor(self.tint)
      v.activeTintColor = UIColor(self.activeTint)
      v.backgroundColor = .clear
      return v
    }

    func updateUIView(_ v: AVRoutePickerView, context: Context) {
      v.tintColor = UIColor(self.tint)
      v.activeTintColor = UIColor(self.activeTint)
    }
  }
#endif
