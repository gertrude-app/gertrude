import Dependencies
import DuetSQL
import Foundation

actor Ephemeral {
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now
  @Dependency(\.db) private var db
  @Dependency(\.env) private var env
  @Dependency(\.slack) private var slack
  @Dependency(\.logger) private var logger
  @Dependency(\.verificationCode) private var verificationCode

  struct Storage: Codable {
    struct ParentId: Codable {
      var parentId: Parent.Id
      var expiration: Date
      var claimCode: String?
      var claimApp: GertrudeIOSApp?
    }

    struct ChildId: Codable {
      var childId: Child.Id
      var expiration: Date
    }

    struct PendingMethod: Codable {
      var model: Parent.NotificationMethod
      var code: Int
      var expiration: Date
    }

    struct SuperAdminEmail: Codable {
      var email: String
      var expiration: Date
    }

    struct RetrievedParentId: Codable {
      var parentId: Parent.Id
      var retrievedAt: Date
      var claimCode: String?
      var claimApp: GertrudeIOSApp?
    }

    struct PinReset: Codable {
      var installId: PodcastApp.Install.Id
      var expiration: Date
    }

    var parentIds: [UUID: ParentId] = [:]
    var retrievedParentIds: [UUID: RetrievedParentId] = [:]
    var pendingAppConnections: [Int: ChildId] = [:]
    var pendingMethods: [Parent.NotificationMethod.Id: PendingMethod] = [:]
    var superAdminEmails: [UUID: SuperAdminEmail] = [:]
    // optional only to survive first deploy decode; flip to non-optional `= [:]`
    // (and drop the lazy-init dance in createPinResetCode) once persisted JSON
    // is confirmed to contain the `pinResets` key.
    var amPinResets: [Int: PinReset]? = nil
    var latestIOSAppStoreVersion: String?
  }

  private var storage = Storage()

  enum ParentId: Equatable {
    case notFound
    case notExpired(Parent.Id, claimCode: String?, claimApp: GertrudeIOSApp?)
    case expired(Parent.Id, claimCode: String?, claimApp: GertrudeIOSApp?)
    case previouslyRetrieved(Parent.Id, claimCode: String?, claimApp: GertrudeIOSApp?)

    var notExpired: Parent.Id? {
      guard case .notExpired(let parentId, _, _) = self else { return nil }
      return parentId
    }
  }

  func createParentIdToken(
    _ parentId: Parent.Id,
    expiration: Date? = nil,
    claimCode: String? = nil,
    claimApp: GertrudeIOSApp? = nil,
  ) -> UUID {
    defer { Task { await self.persistStorage() } }
    let token = self.uuid()
    self.storage.parentIds[token] = .init(
      parentId: parentId,
      expiration: expiration ?? self.now + .minutes(60),
      claimCode: claimCode,
      claimApp: claimApp,
    )
    return token
  }

  func unexpiredParentIdFromToken(_ token: UUID) -> Parent.Id? {
    switch self.parentIdFromToken(token) {
    case .notExpired(let parentId, _, _):
      parentId
    case .expired, .notFound, .previouslyRetrieved:
      nil
    }
  }

  func parentIdFromToken(_ token: UUID) -> ParentId {
    defer { Task { await self.persistStorage() } }
    if let stored = self.storage.parentIds.removeValue(forKey: token) {
      if stored.expiration > self.now {
        self.storage.retrievedParentIds[token] = .init(
          parentId: stored.parentId,
          retrievedAt: self.now,
          claimCode: stored.claimCode,
          claimApp: stored.claimApp,
        )
        return .notExpired(stored.parentId, claimCode: stored.claimCode, claimApp: stored.claimApp)
      } else {
        // put back, so if they try again, they know it's expired, not missing
        self.storage.parentIds[token] = stored
        return .expired(stored.parentId, claimCode: stored.claimCode, claimApp: stored.claimApp)
      }
    } else if let retrieved = self.storage.retrievedParentIds[token] {
      return .previouslyRetrieved(
        retrieved.parentId,
        claimCode: retrieved.claimCode,
        claimApp: retrieved.claimApp,
      )
    } else {
      return .notFound
    }
  }

  func createPendingNotificationMethod(
    _ model: Parent.NotificationMethod,
    expiration: Date? = nil,
  ) -> Int {
    defer { Task { await self.persistStorage() } }
    let code = self.verificationCode.generate()
    self.storage.pendingMethods[model.id] = .init(
      model: model,
      code: code,
      expiration: expiration ?? self.now + .minutes(60),
    )
    return code
  }

  func storePendingNtfyMethod(
    _ model: Parent.NotificationMethod,
    expiration: Date? = nil,
  ) {
    defer { Task { await self.persistStorage() } }
    self.storage.pendingMethods[model.id] = .init(
      model: model,
      code: 0,
      expiration: expiration ?? self.now + .minutes(60),
    )
  }

  func confirmPendingNotificationMethod(
    _ modelId: Parent.NotificationMethod.Id,
    _ code: Int,
  ) -> Parent.NotificationMethod? {
    defer { Task { await self.persistStorage() } }
    guard let stored = self.storage.pendingMethods.removeValue(forKey: modelId),
          code == stored.code,
          stored.expiration > self.now else {
      return nil
    }
    return stored.model
  }

  func createPendingAppConnection(
    _ childId: Child.Id,
    expiration: Date? = nil,
  ) -> Int {
    defer { Task { await self.persistStorage() } }
    let code = self.verificationCode.generate()
    if self.storage.pendingAppConnections[code] != nil {
      return self.createPendingAppConnection(childId)
    }
    self.storage.pendingAppConnections[code] = .init(
      childId: childId,
      expiration: expiration ?? self.now + .days(2),
    )
    return code
  }

  func getOrCreatePendingAppConnection(_ childId: Child.Id) -> Int {
    if let existing = self.storage.pendingAppConnections
      .first(where: { $0.value.childId == childId && $0.value.expiration > self.now }) {
      return existing.key
    }
    return self.createPendingAppConnection(childId)
  }

  func getPendingAppConnection(_ code: Int) -> Child.Id? {
    defer { Task { await self.persistStorage() } }
    #if DEBUG
      if code == 999_999 { return AdminBetsy.Ids.jimmysId }
    #endif
    guard let stored = self.storage.pendingAppConnections.removeValue(forKey: code),
          stored.expiration > self.now else {
      return nil
    }
    return stored.childId
  }

  func createPinResetCode(
    forInstall installId: PodcastApp.Install.Id,
    expiration: Date? = nil,
  ) -> Int {
    defer { Task { await self.persistStorage() } }
    let code = self.verificationCode.generate()
    if self.storage.amPinResets?[code] != nil {
      return self.createPinResetCode(forInstall: installId, expiration: expiration)
    }
    var resets = self.storage.amPinResets ?? [:]
    resets[code] = .init(
      installId: installId,
      expiration: expiration ?? self.now + .minutes(60),
    )
    self.storage.amPinResets = resets
    return code
  }

  func consumePinResetCode(_ code: Int) -> PodcastApp.Install.Id? {
    defer { Task { await self.persistStorage() } }
    guard let stored = self.storage.amPinResets?.removeValue(forKey: code),
          stored.expiration > self.now else {
      return nil
    }
    return stored.installId
  }

  func createSuperAdminToken(_ email: String, expiration: Date? = nil) -> UUID {
    defer { Task { await self.persistStorage() } }
    let token = self.uuid()
    self.storage.superAdminEmails[token] = .init(
      email: email,
      expiration: expiration ?? self.now + .minutes(60),
    )
    return token
  }

  func unexpiredSuperAdminEmailFromToken(_ token: UUID) -> String? {
    defer { Task { await self.persistStorage() } }
    guard let stored = self.storage.superAdminEmails.removeValue(forKey: token),
          stored.expiration > self.now else {
      return nil
    }
    return stored.email
  }

  func getLatestIOSAppStoreVersion() -> String? {
    self.storage.latestIOSAppStoreVersion
  }

  func setLatestIOSAppStoreVersion(_ version: String?) {
    defer { Task { await self.persistStorage() } }
    self.storage.latestIOSAppStoreVersion = version
  }
}

// extensions

extension Ephemeral {
  func persistStorage() async {
    self.cleanupExpired()
    guard let data = try? JSONEncoder().encode(self.storage),
          let json = String(data: data, encoding: .utf8) else {
      await self.slack.error("failed to encode ephemeral storage")
      return
    }
    do {
      _ = try await self.storageQuery.delete(in: self.db)
      _ = try await self.db.create(InterestingEvent(
        id: .init(UUID()),
        eventId: "store-ephemeral",
        kind: "system",
        context: "api",
        detail: json,
      ))
    } catch {
      await self.slack.error("error persisting ephemeral storage: \(String(reflecting: error))")
    }
  }

  func restoreStorage() async {
    do {
      let model = try await self.storageQuery.first(in: self.db)
      guard let storage = try? JSONDecoder().decode(
        Storage.self,
        from: model.detail?.data(using: .utf8) ?? Data(),
      ) else {
        await self.slack.error("failed to decode ephemeral storage")
        return
      }

      self.storage = storage
      self.logger.info("restored ephemeral storage")
    } catch {
      let err = String(reflecting: error)
      self.logger.info("error restoring ephemeral storage: \(err)")
      if self.env.mode == .prod {
        await self.slack.error("error restoring ephemeral storage: \(err)")
      }
    }
  }

  private func cleanupExpired() {
    self.storage.parentIds = self.storage.parentIds.filter {
      $0.value.expiration > self.now - .days(7)
    }
    self.storage.retrievedParentIds = self.storage.retrievedParentIds.filter {
      $0.value.retrievedAt > self.now - .days(7)
    }
    self.storage.pendingAppConnections = self.storage.pendingAppConnections.filter {
      $0.value.expiration > self.now
    }
    self.storage.pendingMethods = self.storage.pendingMethods.filter {
      $0.value.expiration > self.now
    }
    self.storage.superAdminEmails = self.storage.superAdminEmails.filter {
      $0.value.expiration > self.now
    }
    self.storage.amPinResets = self.storage.amPinResets?.filter {
      $0.value.expiration > self.now
    }
  }

  private var storageQuery: DuetQuery<InterestingEvent> {
    InterestingEvent.query()
      .where(.eventId == "store-ephemeral")
      .where(.context == "api")
      .where(.kind == "system")
  }
}

extension DependencyValues {
  var ephemeral: Ephemeral {
    get { self[Ephemeral.self] }
    set { self[Ephemeral.self] = newValue }
  }
}

extension Ephemeral: DependencyKey {
  static var liveValue: Ephemeral {
    .init()
  }
}

#if DEBUG
  extension Ephemeral: TestDependencyKey {
    static var testValue: Ephemeral {
      .init()
    }
  }
#endif
