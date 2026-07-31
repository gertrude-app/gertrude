import SwiftUI

struct MusicSetupSplashView: View {
  var body: some View {
    ZStack {
      Image("MusicSplashGradient", bundle: Bundle.module)
        .resizable()
      Image("MusicSplashNote", bundle: Bundle.module)
        .resizable()
        .scaledToFit()
        .frame(width: 144, height: 144)
    }
    .ignoresSafeArea()
  }
}
