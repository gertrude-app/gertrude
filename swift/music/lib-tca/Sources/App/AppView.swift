import ComposableArchitecture
import LibViews
import SwiftUI

struct AppView: View {
  @Environment(\.colorScheme) private var colorScheme

  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    #if os(iOS)
      if #available(iOS 26.0, *) {
        TabView {
          Tab("Library", systemImage: "square.grid.2x2") {
            self.libraryView
          }

          Tab("Queue", systemImage: "list.bullet") {
            self.queueView
          }

          Tab(role: .search) {
            self.searchView
          }
        }
        .tint(.gertrudeBrandAccent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
          self.nowPlayingAccessory
        }
        .sheet(isPresented: self.nowPlayingPresented) {
          self.nowPlayingSheet
        }
      } else {
        self.defaultTabView
      }
    #else
      self.defaultTabView
    #endif
  }

  private var defaultTabView: some View {
    TabView {
      Tab("Library", systemImage: "square.grid.2x2") {
        self.libraryView
      }

      Tab("Queue", systemImage: "list.bullet") {
        self.queueView
      }

      Tab("Search", systemImage: "magnifyingglass") {
        self.searchView
      }
    }
    .tint(.gertrudeBrandAccent)
  }

  private var libraryView: some View {
    LibraryViewContainer(
      store: self.store.scope(state: \.library, action: \.library)
    )
  }

  private var queueView: some View {
    NavigationStack {
      PlaceholderScreenView(title: "Queue")
    }
  }

  private var searchView: some View {
    NavigationStack {
      PlaceholderScreenView(title: "Search")
    }
    .searchable(text: self.searchText)
  }

  #if os(iOS)
    @available(iOS 26.0, *)
    private var nowPlayingAccessory: some View {
      NowPlayingAccessoryView(foregroundColor: self.nowPlayingForegroundColor) {
        self.store.send(.nowPlayingPresentationChanged(true))
      }
    }
  #endif

  private var nowPlayingForegroundColor: Color {
    self.colorScheme == .dark ? .white : .black
  }

  private var nowPlayingSheet: some View {
    Text("now playing")
      .font(.title)
  }

  private var searchText: Binding<String> {
    Binding(
      get: { self.store.searchText },
      set: { self.store.send(.searchTextChanged($0)) }
    )
  }

  private var nowPlayingPresented: Binding<Bool> {
    Binding(
      get: { self.store.isNowPlayingPresented },
      set: { self.store.send(.nowPlayingPresentationChanged($0)) }
    )
  }
}
