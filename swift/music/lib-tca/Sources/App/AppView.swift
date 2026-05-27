import ComposableArchitecture
import LibViews
import SwiftUI

struct AppView: View {
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

  private var searchText: Binding<String> {
    Binding(
      get: { self.store.searchText },
      set: { self.store.send(.searchTextChanged($0)) }
    )
  }
}
