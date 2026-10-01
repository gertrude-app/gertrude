import Dependencies
import Foundation
import IOSAppsRoute
import Security

@testable import DeviceIdentity

let oldId = UUID(uuidString: "a799622a-713a-48e5-85d9-8b0a0a61b56b")!
let newId = UUID(uuidString: "d83aeba6-669a-47ca-b344-13ebb0dfdabc")!
let proofId = UUID(uuidString: "3d9dbf84-dff3-4757-8a55-0b75cf273642")!
let childId = UUID(uuidString: "dfbfb9e8-36ed-42b0-ae40-75697296a7ce")!

@MainActor
final class IdentityHarness {
  var data: [IdentitySlot: Data] = [:]
  var reads: [IdentitySlot: IdentityRead<Data>] = [:]
  var writeFailures: Set<IdentitySlot> = []
  var deleteFails = false
  var addWinner: UUID?
  var repairFails = false
  var clearFails = false
  var credentialsFail = false
  var markerFails = false
  var reportFails = false
  var proof: UUID? = proofId
  var connection: UUID? = proofId
  var mirror: UUID? = oldId
  var publishedIdentities: [UUID?] = []
  var migrationRequired = false
  var events: [IdentityResolver.Event] = []
  var actions: [String] = []
  var requests: [ReportIdentityTransition.Input] = []
  var response: ReportIdentityTransition.Output?
  var transport: (@MainActor (ReportIdentityTransition.Input) async throws
    -> ReportIdentityTransition.Output)?
  var liveVendorId: UUID? = newId

  init(a: UUID? = nil, b: UUID? = nil, c: UUID? = nil) {
    for (slot, id) in [(IdentitySlot.identity, a), (.canary, b), (.appMemory, c)] {
      if let id { self.data[slot] = Data(id.uuidString.utf8) }
    }
  }

  var storage: IdentityStorage {
    .init(
      read: { slot in self.reads[slot] ?? self.data[slot].map(IdentityRead.value) ?? .absent },
      add: { slot, data in
        self.actions.append("add:\(slot.rawValue)")
        if let winner = self.addWinner {
          self.data[slot] = Data(winner.uuidString.utf8)
          self.addWinner = nil
          if self.repairFails { self.writeFailures.insert(.canary) }
          return .duplicate
        }
        guard !self.writeFailures.contains(slot) else { return .failure(errSecNotAvailable) }
        guard self.data[slot] == nil else { return .duplicate }
        self.data[slot] = data
        return .success
      },
      write: { slot, data in
        self.actions.append("write:\(slot.rawValue)")
        guard !self.writeFailures.contains(slot) else { return .failure(errSecNotAvailable) }
        self.data[slot] = data
        return .success
      },
      delete: { slot in
        self.actions.append("delete:\(slot.rawValue)")
        guard !self.deleteFails else { return .failure(errSecNotAvailable) }
        self.data[slot] = nil
        return .success
      },
    )
  }

  func resolver() -> IdentityResolver {
    withDependencies {
      $0.uuid = .constant(newId)
    } operation: {
      IdentityResolver(storage: self.storage, hooks: .init(
        metadata: {
          .init(
            app: .blocker,
            modelIdentifier: "iPhone16,1",
            iosVersion: "26.6.1",
            appVersion: "1.10.0",
            liveVendorId: self.liveVendorId,
          )
        },
        proofToken: { self.proof },
        clearDeviceBoundState: {
          self.actions.append("clear")
          self.connection = nil
          self.proof = nil
          self.mirror = nil
          if self.clearFails { throw Failure.consumer }
        },
        markMigration: {
          self.actions.append("markMigration")
          if self.markerFails { throw Failure.consumer }
          self.migrationRequired = true
        },
        migrationPending: { self.migrationRequired },
        applyCredentials: { output in
          self.actions.append("credentials")
          if self.credentialsFail { throw Failure.consumer }
          if let token = output.token {
            self.connection = token
            self.proof = token
          }
        },
        publishIdentity: {
          self.mirror = $0
          self.publishedIdentities.append($0)
        },
        report: { input in
          self.actions.append("report")
          self.requests.append(input)
          if self.reportFails { throw Failure.network }
          if let transport = self.transport { return try await transport(input) }
          return self.response ?? .init(
            deviceId: input.newDeviceId,
            reason: .normal,
            childId: childId,
            token: proofId,
          )
        },
        telemetry: { self.events.append($0) },
      ))
    }
  }

  func pending(_ kind: ReportIdentityTransition.Kind = .migrated) throws {
    self.data[.pendingTransition] = try JSONEncoder().encode(PendingIdentityTransition(
      oldDeviceId: oldId, newDeviceId: newId, kind: kind, proofToken: proofId,
    ))
  }

  enum Failure: Error {
    case consumer
    case network
  }
}

extension IdentityResolver {
  @MainActor
  func resolveAndReport() async -> Outcome {
    let local = self.resolveOnForeground()
    switch local {
    case .adopted, .retry:
      return await self.reportPendingTransition()
    default:
      return local
    }
  }
}
