import Core
import SwiftUI

@main
struct EntryPoint: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text(Foo().sayHello())
    }
    .padding()
    .ignoresSafeArea()
  }
}

#Preview {
  ContentView()
}
