import ComposableArchitecture

@Reducer
struct PlaceholderScreenFeature {
  @ObservableState
  struct State: Equatable {
    let title: String
    let transitionSourceID: String?

    init(
      title: String,
      transitionSourceID: String? = nil,
    ) {
      self.title = title
      self.transitionSourceID = transitionSourceID
    }
  }

  enum Action: Equatable {}
}
