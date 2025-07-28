import LibCore
import LibTCA
import LibViews
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
      Text(Foo().hello())
      Text(CoolView().hello())
      Text(AppReducer().hello())
    }
    .padding()
    .ignoresSafeArea()
  }
}

#Preview {
  ContentView()
}
