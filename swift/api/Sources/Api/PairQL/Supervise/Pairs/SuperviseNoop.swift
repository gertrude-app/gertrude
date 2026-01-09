import PairQL

struct SuperviseNoop: Pair {
  static let auth: ClientAuth = .none

  typealias Input = NoInput

  struct Output: PairOutput {
    var message: String
  }
}

extension SuperviseNoop: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    Output(message: "Supervise domain is working")
  }
}
