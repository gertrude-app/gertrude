import DuetSQL
import Foundation
import MusicRoute
import PairQL
import PodcastRoute

enum AccountIOSFlow: String, PairNestable {
  case blockerConnect
  case blockerSupervise
  case podcasts
  case music

  var intent: ClaimIntent {
    switch self {
    case .blockerConnect: .blockerConnect
    case .blockerSupervise: .blockerSupervise
    case .podcasts: .podcasts
    case .music: .music
    }
  }

  init?(_ intent: ClaimIntent) {
    self.init(rawValue: intent.rawValue)
  }

  func path(code: Int) -> String {
    "/connect/\(self.rawValue)/\(code)"
  }
}

struct GetAccountIOSClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let flow: AccountIOSFlow
    let code: Int
  }

  struct Assignment: PairNestable {
    let personId: Child.Id
    let personName: String
    let deviceId: IOSDevice.Id
    let amSubscription: AmSubscriptionState?
    let musicSubscription: MusicSubscriptionState?
    let supervisionStatus: GetDevices.Mobile.SupervisionStatus?
    let requiresPayment: Bool
  }

  struct Output: PairOutput {
    let people: [GetAccountBlockerClaimData.PersonOption]
    let modelName: String
    let modelIdentifier: String
    let deviceType: String
    let iosVersion: String
    let assignment: Assignment?
  }
}

extension GetAccountIOSClaimData: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    try await resolveClaimData(
      code: input.code,
      intent: input.flow.intent,
      baseId: "6fc4ae74",
      in: context.legacyContext,
      onResume: { device, person in
        try await self.output(for: device, assignedTo: person, flow: input.flow, in: context)
      },
      onUnclaimed: { device, people in
        try await self.requireInstall(for: device, flow: input.flow, in: context)
        return self.output(for: device, people: people)
      },
      onUnclaimedBound: { claim, device, person in
        try await self.requireInstall(for: device, flow: input.flow, in: context)
        try await completeClaim(claim, for: person, in: context.db)
        if input.flow == .blockerConnect || input.flow == .blockerSupervise {
          try await device.ensureBlockerBlockGroups(in: context.db)
        }
        return try await self.output(for: device, assignedTo: person, flow: input.flow, in: context)
      },
    )
  }

  static func requireInstall(
    for device: IOSDevice,
    flow: AccountIOSFlow,
    in context: AccountOwnerContext,
  ) async throws {
    switch flow {
    case .music:
      _ = try await ClaimMusicDevice.requireMusicInstall(
        for: device, eventId: "e346a252", in: context.legacyContext,
      )
    case .podcasts:
      guard try await device.podcastInstall(in: context.db) != nil else {
        throw context.error(
          "6eb6a9ec",
          .notFound,
          user: "Gertrude Podcasts is not set up on this device.",
        )
      }
    case .blockerConnect, .blockerSupervise:
      break
    }
  }

  private static func output(for device: IOSDevice, people: [Child]) -> Output {
    .init(
      people: people.map { .init(id: $0.id, name: $0.name, relationship: $0.relationship) },
      modelName: device.modelName,
      modelIdentifier: device.modelIdentifier,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      assignment: nil,
    )
  }

  private static func output(
    for device: IOSDevice,
    assignedTo person: Child,
    flow: AccountIOSFlow,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let amSubscription: AmSubscriptionState? = if flow == .podcasts,
                                                  let install = try await device
                                                  .podcastInstall(in: context.db) {
      try await (context.currentBillingAccount()).amSubscriptionState(forInstall: install)
    } else {
      nil
    }
    let musicSubscription: MusicSubscriptionState? = if flow == .music,
                                                        let install = try await device
                                                        .musicInstall(in: context.db) {
      try await ClaimMusicDevice.subscription(for: install, in: context.legacyContext)
    } else {
      nil
    }
    let supervision: BlockerApp.Supervision? = if flow == .blockerSupervise {
      try await device.supervision(in: context.db)
    } else {
      nil
    }
    let supervisionStatus: GetDevices.Mobile.SupervisionStatus? = if flow == .blockerSupervise {
      .init(supervision?.status(claimedAt: Date.distantPast) ?? .claimed)
    } else {
      nil
    }
    let requiresPayment = if flow == .blockerSupervise {
      try await (context.currentBillingAccount())
        .paymentActionForMissingCapability(.superviseIosDevice) != nil
    } else {
      false
    }
    return .init(
      people: [],
      modelName: device.modelName,
      modelIdentifier: device.modelIdentifier,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      assignment: .init(
        personId: person.id,
        personName: person.name,
        deviceId: device.id,
        amSubscription: amSubscription,
        musicSubscription: musicSubscription,
        supervisionStatus: supervisionStatus,
        requiresPayment: requiresPayment,
      ),
    )
  }
}
