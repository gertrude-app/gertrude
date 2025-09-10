import ComposableArchitecture
import SwiftUI

public struct EntryPoint: View {
  private let store: StoreOf<AppReducer>

  public init() {
    let db = try! appDatabase()
    prepareDependencies {
      $0.defaultDatabase = db
      #if targetEnvironment(simulator)
        $0.passcode.load = { 111_111 }
      #endif
    }
    self.store = Store(
      initialState: initialState,
      reducer: { AppReducer()._printChanges() }
    )
  }

  public var body: some View {
    AppView(store: self.store)
  }
}

private var initialState: AppReducer.State {
  @Dependency(\.passcode) var passcode
  var state = AppReducer.State()
  #if !targetEnvironment(simulator)
    if let passcode = passcode.load() {
      state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
    } else {
      state.mode = .onboarding(OnboardingFeature.State())
    }
  #else
    passcode.delete()
    state.mode = .podcasts(PodcastsFeature.State(
      passcode: 111_111,
      shows: [],
      destination: .addShow(.init(
        passcode: 111_111,
        screen: .searching,
        searchText: "henderson ancient path",
      ))
    ))
  #endif
  return state
}
