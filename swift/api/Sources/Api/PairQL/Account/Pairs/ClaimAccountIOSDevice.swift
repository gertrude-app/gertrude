import Dependencies
import DuetSQL
import PairQL
import TSCodable

struct ClaimAccountIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  @TSCodable
  enum PersonAssignment: PairNestable {
    case existing(id: Child.Id)
    case new(name: String, relationship: Child.Relationship)
  }

  struct Input: PairInput {
    let flow: AccountIOSFlow
    let code: Int
    let person: PersonAssignment
  }

  typealias Output = GetAccountIOSClaimData.Output
}

extension ClaimAccountIOSDevice: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let assignment: ClaimIOSDevice.ChildAssignment
    let relationship: Child.Relationship?
    switch input.person {
    case .existing(let id):
      assignment = .existingChild(id: id)
      relationship = nil
    case .new(let name, let selectedRelationship):
      assignment = try .newChild(name: context.validatedPersonName(name))
      relationship = selectedRelationship
    }

    let createdPerson: Child? = if let relationship {
      try await context.db.withTransaction { tx in
        try await withDependencies {
          $0.db = tx
        } operation: {
          try await self.claim(
            input,
            assignment: assignment,
            relationship: relationship,
            in: context,
          )
        }
      }
    } else {
      try await self.claim(
        input, assignment: assignment, relationship: nil, in: context,
      )
    }

    if let createdPerson {
      dashSecurityEvent(.childAdded, "name: \(createdPerson.name)", in: context.legacyContext)
    }

    return try await GetAccountIOSClaimData.resolve(
      with: .init(flow: input.flow, code: input.code),
      in: context,
    )
  }

  private static func claim(
    _ input: Input,
    assignment: ClaimIOSDevice.ChildAssignment,
    relationship: Child.Relationship?,
    in context: AccountOwnerContext,
  ) async throws -> Child? {
    let legacy = context.legacyContext
    var createdPerson: Child?
    _ = try await claimDevice(
      intent: input.flow.intent,
      code: input.code,
      child: assignment,
      baseId: "1c1dadba",
      in: legacy,
      onResume: { _, _ in },
      beforeClaim: { device in
        try await GetAccountIOSClaimData.requireInstall(for: device, flow: input.flow, in: context)
      },
      createNewChild: relationship.map { relationship in
        { name in
          try await context.validatePersonRelationship(relationship)
          let person = try await context.db.create(Child(
            parentId: context.accountOwner.id,
            name: name,
            relationship: relationship,
          ))
          createdPerson = person
          return person
        }
      },
      onFresh: { device, person in
        switch input.flow {
        case .blockerConnect:
          _ = try await ClaimBlockerDevice.didClaim(device, person, input.code, in: legacy)
        case .blockerSupervise:
          _ = try await ClaimIOSDevice.didClaim(device, person, input.code, in: legacy)
        case .podcasts:
          _ = try await ClaimAmDevice.didClaim(device, person, input.code, in: legacy)
        case .music:
          _ = try await ClaimMusicDevice.didClaim(device, person, input.code, in: legacy)
        }
      },
    )
    return createdPerson
  }
}
