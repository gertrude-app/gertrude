import SwiftUI

@main
struct GertieApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var body: some View {
    VStack(spacing: 12) {
      Text("Gertie")
        .font(.system(size: 48, weight: .semibold))
      Text("browser shell — placeholder window")
        .font(.title3)
        .foregroundColor(.secondary)
    }
    .frame(minWidth: 800, minHeight: 600)
    .padding()
  }
}
