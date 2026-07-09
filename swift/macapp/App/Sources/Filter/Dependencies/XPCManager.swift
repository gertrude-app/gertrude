import Core
import Dependencies
import Foundation
import Gertie
import os.log

class XPCManager: NSObject, NSXPCListenerDelegate, XPCSender {
  typealias Proxy = FilterMessageReceiving

  struct AppConnection: Sendable {
    let id: ObjectIdentifier
    let connection: Connection
    let seq: Int
  }

  struct ConnectionMap: Sendable {
    var entries: [uid_t: AppConnection] = [:]
    var nextSeq = 0

    var mostRecent: AppConnection? {
      self.entries.values.max { $0.seq < $1.seq }
    }
  }

  var listener: NSXPCListener?
  let connections = Mutex(ConnectionMap())

  @Dependency(\.mainQueue) var scheduler

  func notifyFilterSuspensionEnded(for userId: uid_t) async throws {
    let connection = try self.connection(for: userId)

    os_log("[G•] FILTER XPCManager: notifying filter suspension ended: %{public}d", userId)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveUserFilterSuspensionEnded(userId: userId, reply: continuation.dataHandler)
    }
  }

  func sendBlockedRequest(_ request: BlockedRequest, userId: uid_t) async throws {
    let connection = try self.connection(for: userId)

    os_log(
      "[G•] FILTER XPCManager: sending blocked request: %{public}@",
      String(describing: request),
    )
    let requestData = try XPC.encode(request)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveBlockedRequest(requestData, userId: userId, reply: continuation.dataHandler)
    }
  }

  func sendLogs(_ logs: FilterLogs) async throws {
    guard let connection = self.connections.withValue({ $0.mostRecent?.connection }) else {
      throw XPCErr.noConnection
    }

    os_log("[G•] FILTER XPCManager: sending filter logs")
    let logsData = try XPC.encode(logs)
    try await withTimeout(connection: connection) { appProxy, continuation in
      appProxy.receiveFilterLogs(logsData, reply: continuation.dataHandler)
    }
  }

  func startListener() {
    let newListener = NSXPCListener(machServiceName: Constants.MACH_SERVICE_NAME)
    newListener.delegate = self
    newListener.resume()
    self.listener = newListener
    os_log("[G•] FILTER XPCManager: started listener")
  }

  func stopListener() {
    self.listener?.invalidate()
    self.listener = nil
    self.connections.replace(with: ConnectionMap())
    os_log("[G•] FILTER XPCManager: stopped listener")
  }

  func listener(
    _ listener: NSXPCListener,
    shouldAcceptNewConnection newConnection: NSXPCConnection,
  ) -> Bool {
    self.accept(connection: newConnection, userId: newConnection.effectiveUserIdentifier)
    return true
  }

  static let appCodeSigningRequirement = "anchor apple generic"
    + " and identifier \"\(Constants.APP_BUNDLE_ID)\""
    + " and certificate leaf[subject.OU] = \"\(Constants.TEAM_ID)\""

  func accept(connection newConnection: NSXPCConnection, userId: uid_t) {
    os_log(
      "[G•] FILTER XPCManager: accepting new connection %{public}@ for user %{public}d",
      newConnection,
      userId,
    )
    if #available(macOS 13.0, *) {
      newConnection.setCodeSigningRequirement(Self.appCodeSigningRequirement)
    } else {
      os_log("[G•] FILTER XPCManager: peer code signing requirement unavailable")
    }
    let id = ObjectIdentifier(newConnection)
    newConnection.invalidationHandler = { [weak self] in
      self?.removeConnection(userId: userId, id: id)
    }
    // ⛔️⛔️⛔️ WARNING ⛔️⛔️⛔️ `newConnection` has been "moved" into
    // the Connection object, and may not be accessed again !!!
    let connection = Connection(taking: Move(configure(connection: newConnection)))
    self.connections.transition { map in
      var map = map
      map.entries[userId] = AppConnection(id: id, connection: connection, seq: map.nextSeq)
      map.nextSeq += 1
      return map
    }
  }

  func removeConnection(userId: uid_t, id: ObjectIdentifier) {
    os_log("[G•] FILTER XPCManager: connection invalidated for user %{public}d", userId)
    self.connections.transition { map in
      guard map.entries[userId]?.id == id else { return map }
      var map = map
      map.entries[userId] = nil
      return map
    }
  }

  private func connection(for userId: uid_t) throws -> Connection {
    guard let connection = self.connections.withValue({ $0.entries[userId]?.connection }) else {
      throw XPCErr.noConnection
    }
    return connection
  }
}

func configure(connection: NSXPCConnection) -> NSXPCConnection {
  connection.exportedInterface = NSXPCInterface(with: AppMessageReceiving.self)
  connection.exportedObject = ReceiveAppMessage(subject: xpcEventSubject)
  connection.remoteObjectInterface = NSXPCInterface(with: FilterMessageReceiving.self)
  connection.resume()
  return connection
}
