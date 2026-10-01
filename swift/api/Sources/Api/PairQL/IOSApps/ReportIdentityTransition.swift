import DuetSQL
import GertieApp
import IOSAppsRoute
import Vapor

extension ReportIdentityTransition: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await context.db.withTransaction { db in
      let oldId = IOSDevice.Id(input.oldDeviceId)
      let newId = IOSDevice.Id(input.newDeviceId)
      _ = try await db.execute(raw: """
      SELECT id FROM child.ios_devices
      WHERE id IN (\(bind: input.oldDeviceId), \(bind: input.newDeviceId))
      ORDER BY id FOR UPDATE
      """)
      let new = try await db.findOrCreate(
        IOSDevice(id: newId, modelIdentifier: input.modelIdentifier, iosVersion: input.iosVersion),
        conflictOn: [.id],
      )
      guard let old = try await IOSDevice.query().where(.id == oldId).all(in: db).first else {
        with(dependency: \.logger)
          .warning("Identity transition source missing: \(input.app) \(oldId) -> \(newId)")
        return Output(deviceId: input.newDeviceId, reason: .normal)
      }
      let verified = try await input.provesOldDevice(in: db)
      if !verified {
        with(dependency: \.logger)
          .warning("Unverified identity transition: \(input.app) \(oldId) -> \(newId)")
      }
      if verified, let childId = old.childId, let newChild = new.childId, newChild != childId {
        with(dependency: \.logger)
          .warning("Identity transition child conflict: \(oldId) -> \(newId)")
        return Output(
          deviceId: old.id.rawValue, reason: .childConflictPin,
          childId: childId.rawValue, token: input.proofToken,
        )
      }
      if oldId == newId {
        return Output(
          deviceId: input.oldDeviceId,
          reason: .normal,
          childId: verified ? old.childId?.rawValue : nil,
          token: verified && old.childId != nil ? input.proofToken : nil,
        )
      }

      let migrated = try await IOSDeviceTransition.query()
        .where((.oldDeviceId == oldId .&& .newDeviceId == newId)
          .|| (.oldDeviceId == newId .&& .newDeviceId == oldId))
        .where(.kind == Kind.migrated)
        .where(.verified == true)
        .exists(in: db)
      let kind: Kind = migrated ? .migrated : input.kind
      try await db.upsert(
        IOSDeviceTransition(
          oldDeviceId: oldId, newDeviceId: newId, kind: kind,
          app: input.app, verified: verified,
        ),
        conflictOn: [.oldDeviceId, .newDeviceId, .app],
        do: .updateRaw { c in
          """
          \(c.col(.kind)) = CASE
            WHEN NOT \(c.excluded(.verified)) THEN \(c.target(.kind))
            WHEN \(c.target(.verified)) AND \(c.target(.kind)) = 'migrated' THEN 'migrated'
            ELSE \(c.excluded(.kind)) END,
          \(c.col(.verified)) = \(c.target(.verified)) OR \(c.excluded(.verified))
          """
        },
      )

      var canonical = new
      var reason: Reason = input.kind == .sameDevice && migrated ? .resolvedAsMigration : .normal
      if kind == .sameDevice {
        let supervisions = try await BlockerApp.Supervision.query()
          .where(.deviceId |=| [oldId, newId]).all(in: db)
        if supervisions.count == 1, supervisions[0].deviceId == oldId {
          canonical = old
          reason = .supervisionCanonical
        } else if supervisions.count > 1 {
          with(dependency: \.logger)
            .warning("Both identity transition devices have supervision: \(oldId), \(newId)")
        }
      }
      guard verified, let childId = old.childId else {
        return Output(deviceId: canonical.id.rawValue, reason: reason)
      }
      if canonical.childId == nil {
        canonical.childId = childId
        try await db.update(canonical)
      }
      let token = try await input.ensureToken(on: canonical.id, in: db)
      return Output(
        deviceId: canonical.id.rawValue, reason: reason,
        childId: childId.rawValue, token: token,
      )
    }
  }
}

private extension ReportIdentityTransition.Input {
  func provesOldDevice(in db: any DuetSQL.Client) async throws -> Bool {
    guard let proofToken else { return false }
    let deviceId: IOSDevice.Id?
    switch self.app {
    case .blocker:
      let token = try await BlockerApp.Token.query()
        .where(.value == BlockerApp.Token.Value(proofToken)).all(in: db).first
      deviceId = try await token?.install(in: db).deviceId
    case .music:
      let token = try await MusicApp.Token.query()
        .where(.value == MusicApp.Token.Value(proofToken)).all(in: db).first
      deviceId = try await token?.install(in: db).deviceId
    case .podcasts:
      let token = try await PodcastApp.Token.query()
        .where(.value == PodcastApp.Token.Value(proofToken)).all(in: db).first
      deviceId = try await token?.install(in: db).deviceId
    }
    return deviceId?.rawValue == self.oldDeviceId
  }

  func ensureToken(on deviceId: IOSDevice.Id, in db: any DuetSQL.Client) async throws -> UUID {
    switch self.app {
    case .blocker:
      let install = try await db.findOrCreate(
        BlockerApp.Install(deviceId: deviceId, appVersion: self.appVersion),
        conflictOn: [.deviceId],
      )
      return try await db.findOrCreate(
        BlockerApp.Token(installId: install.id), conflictOn: [.installId],
      ).value.rawValue
    case .music:
      let install = try await db.findOrCreate(
        MusicApp.Install(deviceId: deviceId, appVersion: self.appVersion),
        conflictOn: [.deviceId],
      )
      return try await db.findOrCreate(
        MusicApp.Token(installId: install.id), conflictOn: [.installId],
      ).value.rawValue
    case .podcasts:
      let install = try await db.findOrCreate(
        PodcastApp.Install(deviceId: deviceId, appVersion: self.appVersion),
        conflictOn: [.deviceId],
      )
      return try await db.findOrCreate(
        PodcastApp.Token(installId: install.id), conflictOn: [.installId],
      ).value.rawValue
    }
  }
}
