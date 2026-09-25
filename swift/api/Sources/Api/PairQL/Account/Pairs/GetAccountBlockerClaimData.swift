import PairQL

struct GetAccountBlockerClaimData: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
  }

  struct PersonOption: PairNestable {
    let id: Child.Id
    let name: String
    let relationship: Child.Relationship
  }

  struct Assignment: PairNestable {
    let personId: Child.Id
    let personName: String
    let deviceId: IOSDevice.Id
  }

  struct Output: PairOutput {
    let people: [PersonOption]
    let modelName: String
    let modelIdentifier: String
    let deviceType: String
    let iosVersion: String
    let assignment: Assignment?
  }
}

extension GetAccountBlockerClaimData: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await resolveClaimData(
      code: input.code,
      intent: .blockerConnect,
      baseId: "31633853",
      in: context.legacyContext,
      onResume: { device, person in
        self.output(for: device, assignedTo: person)
      },
      onUnclaimed: { device, people in
        self.output(for: device, people: people)
      },
      onUnclaimedBound: { claim, device, person in
        try await completeClaim(claim, for: person, in: context.db)
        try await device.ensureBlockerBlockGroups(in: context.db)
        return self.output(for: device, assignedTo: person)
      },
    )
  }

  private static func output(
    for device: IOSDevice,
    people: [Child] = [],
    assignedTo person: Child? = nil,
  ) -> Output {
    .init(
      people: people.map { .init(id: $0.id, name: $0.name, relationship: $0.relationship) },
      modelName: device.modelName,
      modelIdentifier: device.modelIdentifier,
      deviceType: device.deviceType,
      iosVersion: device.iosVersion,
      assignment: person.map {
        .init(personId: $0.id, personName: $0.name, deviceId: device.id)
      },
    )
  }
}
