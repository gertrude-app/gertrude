import Foundation
import Gertie
import PairQL

struct UpdateMacDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: Computer.Id
    let name: String?
    let releaseChannel: ReleaseChannel
  }
}

extension UpdateMacDevice: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let trimmedName = input.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    let name = trimmedName?.isEmpty == false ? trimmedName : nil
    let computer = try await context.computer(input.deviceId)
    guard computer.customName != name || computer.appReleaseChannel != input.releaseChannel else {
      return .success
    }

    return try await SaveDevice.resolve(
      with: .init(
        id: input.deviceId,
        name: name,
        releaseChannel: input.releaseChannel,
      ),
      in: context.legacyContext,
    )
  }
}
