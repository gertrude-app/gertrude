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
      .tint(.violet500)
  }
}

private var initialState: AppReducer.State {
  @Dependency(\.passcode) var passcode
  var state = AppReducer.State()
  // #if !targetEnvironment(simulator)
  // if let passcode = passcode.load() {
  //   state.mode = .podcasts(PodcastsFeature.State(passcode: passcode))
  // } else {
  //   state.mode = .onboarding(OnboardingFeature.State())
  // }
  // #else
  //   passcode.delete()
  state.nowPlaying = .init(
    episode: .mock,
    show: .mock,
    isPlaying: true,
    minimized: true,
  )
  state.mode = .podcasts(PodcastsFeature.State(
    passcode: 111_111,
    shows: [.mock],
    destination: .show(.init(show: .mock)),
  ))
  // #endif
  return state
}
