import DuetSQL
import GertieApp
import IOSAppsRoute
import XCTest
import XExpect

@testable import Api

final class ReportIdentityTransitionResolverTests: ApiTestCase, @unchecked Sendable {
  func testMigrationInheritsChildWithoutChangingSourceAndReplayReusesToken() async throws {
    let source = try await self.childWithIOSDevice()
    let supervision = try await self.db.create(BlockerApp.Supervision(
      deviceId: source.device.id, supervisedAt: .reference, profileInstalledAt: .reference,
    ))
    let input = self.input(source)
    let deviceBefore = try await self.db.find(source.device.id)
    let installBefore = try await self.db.find(source.install.id)
    let supervisionBefore = try await self.db.find(supervision.id)
    let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    let replay = try await ReportIdentityTransition.resolve(with: input, in: .mock)

    expect(output).toEqual(replay)
    expect(output.deviceId).toEqual(input.newDeviceId)
    expect(output.reason).toEqual(.normal)
    expect(output.childId).toEqual(source.id.rawValue)
    expect(output.token == nil).toEqual(false)
    expect(output.token == source.token.value.rawValue).toEqual(false)
    let old = try await self.db.find(source.device.id)
    let oldInstall = try await self.db.find(source.install.id)
    let oldToken = try await self.db.find(source.token.id)
    let oldSupervision = try await self.db.find(supervision.id)
    expect(old).toEqual(deviceBefore)
    expect(oldInstall).toEqual(installBefore)
    expect(oldToken.value).toEqual(source.token.value)
    expect(oldSupervision).toEqual(supervisionBefore)
    let new = try await self.db.find(IOSDevice.Id(input.newDeviceId))
    expect(new.childId).toEqual(source.id)
    expect(new.modelIdentifier).toEqual(input.modelIdentifier)
    expect(new.iosVersion).toEqual(input.iosVersion)
    let install = try await new.blockerInstall(in: self.db)
    expect(install.appVersion).toEqual(input.appVersion)
    let tokens = try await BlockerApp.Token.query().where(.installId == install.id).all(in: self.db)
    expect(tokens).toHaveCount(1)
    expect(tokens.first?.value.rawValue).toEqual(output.token)
    let transitions = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).all(in: self.db)
    expect(transitions).toHaveCount(1)
    expect(transitions.first?.verified).toEqual(true)
    expect(transitions.first?.kind).toEqual(.migrated)
    let newSupervision = try await new.supervision(in: self.db)
    expect(newSupervision).toBeNil()
  }

  func testMissingWrongAndWrongAppProofsGrantNothing() async throws {
    let source = try await self.childWithIOSDevice()
    let stranger = try await self.childWithIOSDevice()
    for proof in [nil, UUID(), stranger.token.value.rawValue, source.token.value.rawValue] {
      var input = self.input(source)
      input.proofToken = proof
      if proof == source.token.value.rawValue { input.app = .music }
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output.childId).toBeNil()
      expect(output.token).toBeNil()
      let new = try await self.db.find(IOSDevice.Id(input.newDeviceId))
      expect(new.childId).toBeNil()
      let transition = try await IOSDeviceTransition.query()
        .where(.newDeviceId == new.id).first(in: self.db)
      expect(transition.verified).toEqual(false)
      let installs = try await BlockerApp.Install.query().where(.deviceId == new.id)
        .all(in: self.db)
      expect(installs).toHaveCount(0)
      let music = try await new.musicInstall(in: self.db)
      expect(music).toBeNil()
    }
  }

  func testForgedReportCannotReadOrChangeClaimedDestination() async throws {
    let source = try await self.childWithIOSDevice()
    let destination = try await self.childWithIOSDevice()
    let before = try await self.db.find(destination.device.id)
    var input = self.input(source, newId: destination.device.id.rawValue)
    input.proofToken = nil
    let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(output.childId).toBeNil()
    expect(output.token).toBeNil()
    expect(output.reason).toEqual(.normal)
    let device = try await self.db.find(destination.device.id)
    expect(device).toEqual(before)
    let transition = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).first(in: self.db)
    expect(transition.verified).toEqual(false)
  }

  func testChildConflictPinsToSourceForBothKinds() async throws {
    let source = try await self.childWithIOSDevice()
    let destination = try await self.childWithIOSDevice()
    let before = try await self.db.find(destination.device.id)
    for kind in [ReportIdentityTransition.Kind.sameDevice, .migrated] {
      let input = self.input(source, newId: destination.device.id.rawValue, kind: kind)
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output.deviceId).toEqual(source.device.id.rawValue)
      expect(output.reason).toEqual(.childConflictPin)
      expect(output.childId).toEqual(source.id.rawValue)
      expect(output.token).toEqual(source.token.value.rawValue)
      let device = try await self.db.find(destination.device.id)
      expect(device).toEqual(before)
      let transitions = try await IOSDeviceTransition.query()
        .where(.oldDeviceId == source.device.id).all(in: self.db)
      expect(transitions).toHaveCount(0)
    }
  }

  func testSiblingSameDeviceReportAlsoPinsAfterConflictingMigration() async throws {
    let source = try await self.childWithIOSDevice()
    let destination = try await self.childWithIOSDevice()
    var input = self.input(source, newId: destination.device.id.rawValue)
    let first = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(first.reason).toEqual(.childConflictPin)
    let install = try await self.db.create(MusicApp.Install(
      deviceId: source.device.id, appVersion: "1.0.0",
    ))
    let token = try await self.db.create(MusicApp.Token(installId: install.id))
    input.app = .music
    input.kind = .sameDevice
    input.proofToken = token.value.rawValue
    let sibling = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(sibling).toEqual(.init(
      deviceId: source.device.id.rawValue, reason: .childConflictPin,
      childId: source.id.rawValue, token: token.value.rawValue,
    ))
    let transitions = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).all(in: self.db)
    expect(transitions).toHaveCount(0)
  }

  func testRetryRecordsVerifiedTransitionAfterChildConflictClears() async throws {
    for kind in [ReportIdentityTransition.Kind.sameDevice, .migrated] {
      let source = try await self.childWithIOSDevice()
      let destination = try await self.childWithIOSDevice()
      let input = self.input(source, newId: destination.device.id.rawValue, kind: kind)
      let pinned = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(pinned.reason).toEqual(.childConflictPin)
      var device = try await self.db.find(destination.device.id)
      device.childId = nil
      try await self.db.update(device)
      let retry = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(retry.deviceId).toEqual(destination.device.id.rawValue)
      expect(retry.reason).toEqual(.normal)
      expect(retry.childId).toEqual(source.id.rawValue)
      expect(retry.token).toEqual(destination.token.value.rawValue)
      let adopted = try await self.db.find(destination.device.id)
      expect(adopted.childId).toEqual(source.id)
      let transitions = try await IOSDeviceTransition.query()
        .where(.oldDeviceId == source.device.id).all(in: self.db)
      expect(transitions).toHaveCount(1)
      expect(transitions.first?.verified).toEqual(true)
      expect(transitions.first?.kind).toEqual(kind)
    }
  }

  func testChildConflictDoesNotUpdateExistingTransition() async throws {
    let source = try await self.childWithIOSDevice()
    let destination = try await self.childWithIOSDevice()
    let transition = try await self.db.create(IOSDeviceTransition(
      oldDeviceId: source.device.id, newDeviceId: destination.device.id,
      kind: .sameDevice, app: .blocker, verified: true,
    ))
    let before = try await self.db.find(transition.id)
    let output = try await ReportIdentityTransition.resolve(
      with: self.input(source, newId: destination.device.id.rawValue), in: .mock,
    )
    expect(output.reason).toEqual(.childConflictPin)
    let after = try await self.db.find(transition.id)
    expect(after).toEqual(before)
  }

  func testSameDeviceChoosesOnlySupervisedRowOtherwiseDestination() async throws {
    for supervised in ["neither", "old", "new", "both"] {
      let source = try await self.childWithIOSDevice()
      let new = try await self.db.create(IOSDevice.mock)
      if supervised == "old" || supervised == "both" {
        try await self.db.create(BlockerApp.Supervision(deviceId: source.device.id))
      }
      if supervised == "new" || supervised == "both" {
        try await self.db.create(BlockerApp.Supervision(deviceId: new.id))
      }
      let input = self.input(source, newId: new.id.rawValue, kind: .sameDevice)
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output.deviceId)
        .toEqual(supervised == "old" ? source.device.id.rawValue : new.id.rawValue)
      expect(output.reason).toEqual(supervised == "old" ? .supervisionCanonical : .normal)
      expect(output.childId).toEqual(source.id.rawValue)
      if supervised == "old" {
        expect(output.token).toEqual(source.token.value.rawValue)
        let unchanged = try await self.db.find(new.id)
        expect(unchanged.childId).toBeNil()
      }
    }
  }

  func testMusicAndPodcastsCreateInstallWithReportedVersionAndReuseToken() async throws {
    for app in [GertrudeIOSApp.music, .podcasts] {
      let source = try await self.childWithIOSDevice()
      var input = self.input(source)
      input.app = app
      if app == .music {
        let install = try await self.db.create(MusicApp.Install(
          deviceId: source.device.id,
          appVersion: "1.0.0",
        ))
        input.proofToken = try await self.db.create(MusicApp.Token(installId: install.id)).value
          .rawValue
      } else {
        let install = try await self.db.create(PodcastApp.Install(
          deviceId: source.device.id,
          appVersion: "1.0.0",
        ))
        input.proofToken = try await self.db.create(PodcastApp.Token(installId: install.id)).value
          .rawValue
      }
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      let replay = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output).toEqual(replay)
      expect(output.childId).toEqual(source.id.rawValue)
      let new = try await self.db.find(IOSDevice.Id(input.newDeviceId))
      if app == .music {
        let found = try await new.musicInstall(in: self.db)
        let install = try XCTUnwrap(found)
        expect(install.appVersion).toEqual(input.appVersion)
        let token = try await install.token(in: self.db)
        expect(token?.value.rawValue).toEqual(output.token)
      } else {
        let found = try await new.podcastInstall(in: self.db)
        let install = try XCTUnwrap(found)
        expect(install.appVersion).toEqual(input.appVersion)
        let token = try await PodcastApp.Token.query().where(.installId == install.id)
          .first(in: self.db)
        expect(token.value.rawValue).toEqual(output.token)
      }
    }
  }

  func testSiblingSameDeviceReportResolvesAsMigrationInEitherDirection() async throws {
    for reverse in [false, true] {
      let source = try await self.childWithIOSDevice()
      let destination = try await self.db.create(IOSDevice.mock { $0.childId = source.id })
      try await self.db.create(BlockerApp.Supervision(deviceId: source.device.id))
      try await self.db.create(IOSDeviceTransition(
        oldDeviceId: reverse ? destination.id : source.device.id,
        newDeviceId: reverse ? source.device.id : destination.id,
        kind: .migrated, app: .music, verified: true,
      ))
      let input = self.input(source, newId: destination.id.rawValue, kind: .sameDevice)
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output.deviceId).toEqual(destination.id.rawValue)
      expect(output.reason).toEqual(.resolvedAsMigration)
      expect(output.childId).toEqual(source.id.rawValue)
      let replay = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output).toEqual(replay)
    }
  }

  func testUnverifiedHistoryCannotBecomeVerifiedMigrationThroughSameDeviceReport() async throws {
    let source = try await self.childWithIOSDevice()
    var input = self.input(source)
    input.proofToken = nil
    _ = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    input.kind = .sameDevice
    input.proofToken = source.token.value.rawValue
    _ = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(output.reason).toEqual(.normal)
    let transition = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).first(in: self.db)
    expect(transition.kind).toEqual(.sameDevice)
    expect(transition.verified).toEqual(true)
    input.kind = .migrated
    input.proofToken = nil
    _ = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    let unchanged = try await self.db.find(transition.id)
    expect(unchanged).toEqual(transition)
  }

  func testVerifiedMigrationAndVerificationSurviveLaterReports() async throws {
    let source = try await self.childWithIOSDevice()
    var input = self.input(source)
    _ = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    input.kind = .sameDevice
    input.proofToken = nil
    let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(output.childId).toBeNil()
    expect(output.token).toBeNil()
    let transition = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).first(in: self.db)
    expect(transition.kind).toEqual(.migrated)
    expect(transition.verified).toEqual(true)
  }

  func testSelfReportDoesNotCreateHistoryOrDiscloseWithoutProof() async throws {
    let source = try await self.childWithIOSDevice()
    var input = self.input(source, newId: source.device.id.rawValue)
    let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(output.token).toEqual(source.token.value.rawValue)
    input.proofToken = nil
    let unverified = try await ReportIdentityTransition.resolve(with: input, in: .mock)
    expect(unverified.childId).toBeNil()
    expect(unverified.token).toBeNil()
    let transitions = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).all(in: self.db)
    expect(transitions).toHaveCount(0)
  }

  func testMissingSourceAcknowledgesFreshOnboardingAndReplayWithoutHistory() async throws {
    for deleted in [false, true] {
      let source = try await self.childWithIOSDevice()
      var input = self.input(source)
      if deleted {
        try await self.db.delete(Child.self, where: .id == source.id)
      } else {
        input.oldDeviceId = UUID()
      }
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      let replay = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output).toEqual(.init(deviceId: input.newDeviceId, reason: .normal))
      expect(replay).toEqual(output)
      let new = try await self.db.find(IOSDevice.Id(input.newDeviceId))
      expect(new.childId).toBeNil()
      expect(new.modelIdentifier).toEqual(input.modelIdentifier)
      expect(new.iosVersion).toEqual(input.iosVersion)
      let oldExists = try await IOSDevice.query().where(.id == IOSDevice.Id(input.oldDeviceId))
        .exists(in: self.db)
      expect(oldExists).toEqual(false)
      let transitions = try await IOSDeviceTransition.query()
        .where(.newDeviceId == new.id).all(in: self.db)
      expect(transitions).toHaveCount(0)
      let installs = try await BlockerApp.Install.query()
        .where(.deviceId == new.id).all(in: self.db)
      expect(installs).toHaveCount(0)
    }
  }

  func testMissingSourcePreservesClaimedDestinationAndDisclosesNothingOnReplay() async throws {
    let destination = try await self.childWithIOSDevice()
    let deviceBefore = try await self.db.find(destination.device.id)
    let installBefore = try await self.db.find(destination.install.id)
    var input = self.input(destination, newId: destination.device.id.rawValue)
    input.oldDeviceId = UUID()
    for _ in 0 ..< 2 {
      let output = try await ReportIdentityTransition.resolve(with: input, in: .mock)
      expect(output).toEqual(.init(deviceId: input.newDeviceId, reason: .normal))
    }
    let deviceAfter = try await self.db.find(destination.device.id)
    let installAfter = try await self.db.find(destination.install.id)
    let tokenAfter = try await self.db.find(destination.token.id)
    expect(deviceAfter).toEqual(deviceBefore)
    expect(installAfter).toEqual(installBefore)
    expect(tokenAfter.value).toEqual(destination.token.value)
    let transitions = try await IOSDeviceTransition.query()
      .where(.newDeviceId == destination.device.id).all(in: self.db)
    expect(transitions).toHaveCount(0)
  }

  func testConcurrentReplayCreatesOneTokenAndOneTransition() async throws {
    let source = try await self.childWithIOSDevice()
    let input = self.input(source)
    async let first = ReportIdentityTransition.resolve(with: input, in: .mock)
    async let second = ReportIdentityTransition.resolve(with: input, in: .mock)
    let outputs = try await [first, second]
    expect(outputs[0]).toEqual(outputs[1])
    let install = try await BlockerApp.Install.query()
      .where(.deviceId == IOSDevice.Id(input.newDeviceId)).first(in: self.db)
    let tokens = try await BlockerApp.Token.query().where(.installId == install.id).all(in: self.db)
    expect(tokens).toHaveCount(1)
    let transitions = try await IOSDeviceTransition.query()
      .where(.oldDeviceId == source.device.id).all(in: self.db)
    expect(transitions).toHaveCount(1)
  }

  func testExistingDestinationInstallVersionAndTokenArePreserved() async throws {
    let source = try await self.childWithIOSDevice()
    let destination = try await self.db.create(IOSDevice.mock { $0.childId = source.id })
    let install = try await self.db.create(BlockerApp.Install(
      deviceId: destination.id,
      appVersion: "9.8.7",
    ))
    let token = try await self.db.create(BlockerApp.Token(installId: install.id))
    let before = try await self.db.find(install.id)
    let output = try await ReportIdentityTransition.resolve(
      with: self.input(source, newId: destination.id.rawValue), in: .mock,
    )
    expect(output.token).toEqual(token.value.rawValue)
    let unchanged = try await self.db.find(install.id)
    expect(unchanged).toEqual(before)
  }

  private func input(
    _ source: ChildWithIOSDeviceEntities,
    newId: UUID = UUID(),
    kind: ReportIdentityTransition.Kind = .migrated,
  ) -> ReportIdentityTransition.Input {
    .init(
      app: .blocker, oldDeviceId: source.device.id.rawValue, newDeviceId: newId,
      kind: kind, proofToken: source.token.value.rawValue,
      modelIdentifier: "iPhone16,1", iosVersion: "26.6", appVersion: "1.10.0",
    )
  }
}
