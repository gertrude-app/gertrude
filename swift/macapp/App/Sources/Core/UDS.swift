import Foundation
import Gertie

public enum UDS {
  public static let socketDir = "/var/run/gertrude"

  public static func socketPath(for uid: uid_t, in dir: String = socketDir) -> String {
    "\(dir)/filter-\(uid).sock"
  }

  public struct Envelope: Codable, Equatable, Sendable {
    public var id: UUID
    public var replyTo: UUID?
    public var message: Message

    public init(id: UUID = UUID(), replyTo: UUID? = nil, message: Message) {
      self.id = id
      self.replyTo = replyTo
      self.message = message
    }
  }

  public enum Message: Codable, Equatable, Sendable {
    // handshake
    case hello(pid: Int32, uid: uid_t, version: String)
    case helloAck(pid: Int32, version: String)

    // app -> filter, mirroring AppMessageReceiving
    case ackRequest(randomInt: Int, userId: uid_t)
    case alive(userId: uid_t)
    case userTypesRequest
    case userRules(userId: uid_t, manifest: AppIdManifest, filterData: UserFilterData)
    case pauseDowntime(userId: uid_t, until: Date)
    case endDowntimePause(userId: uid_t)
    case setBlockStreaming(enabled: Bool, userId: uid_t)
    case disconnectUser(userId: uid_t)
    case setUserExemption(userId: uid_t, enabled: Bool)
    case suspendFilter(userId: uid_t, durationInSeconds: Int)
    case endFilterSuspension(userId: uid_t)
    case deleteAllStoredState

    // filter -> app, mirroring FilterMessageReceiving
    case blockedRequest(userId: uid_t, request: BlockedRequest)
    case filterSuspensionEnded(userId: uid_t)
    case filterLogs(FilterLogs)

    // replies
    case ack(XPC.FilterAck)
    case aliveAck(Bool)
    case userTypes(FilterUserTypes)
    case success
    case failure(String)
  }

  public struct ShadowHealth: Equatable, Sendable {
    public var healthy: Bool
    public var detail: String

    public init(healthy: Bool, detail: String) {
      self.healthy = healthy
      self.detail = detail
    }
  }

  public struct ShadowStatusReport: Equatable, Sendable {
    public var connected: Bool
    public var filterVersion: String?
    public var connectedForSeconds: Int?
    public var lastRoundTripAgeSeconds: Int?
    public var requestsSucceeded: Int
    public var requestsFailed: Int
    public var reconnects: Int

    public init(
      connected: Bool,
      filterVersion: String? = nil,
      connectedForSeconds: Int? = nil,
      lastRoundTripAgeSeconds: Int? = nil,
      requestsSucceeded: Int = 0,
      requestsFailed: Int = 0,
      reconnects: Int = 0,
    ) {
      self.connected = connected
      self.filterVersion = filterVersion
      self.connectedForSeconds = connectedForSeconds
      self.lastRoundTripAgeSeconds = lastRoundTripAgeSeconds
      self.requestsSucceeded = requestsSucceeded
      self.requestsFailed = requestsFailed
      self.reconnects = reconnects
    }

    public var detail: String {
      var parts: [String] = []
      if self.connected {
        var connectedPart = "connected"
        if let version = self.filterVersion {
          connectedPart += ", filter v\(version)"
        }
        if let seconds = self.connectedForSeconds {
          connectedPart += ", up \(seconds)s"
        }
        parts.append(connectedPart)
      } else if let age = self.lastRoundTripAgeSeconds {
        parts.append("disconnected, last round-trip \(age)s ago")
      } else {
        parts.append("never connected")
      }
      parts.append("requests \(self.requestsSucceeded) ok / \(self.requestsFailed) failed")
      parts.append("reconnects \(self.reconnects)")
      return parts.joined(separator: ", ")
    }
  }
}

public enum UDSFrame {
  public static let maxPayloadBytes = 16 * 1024 * 1024

  public static func encode(_ envelope: UDS.Envelope) throws -> Data {
    let payload = try JSONEncoder().encode(envelope)
    var length = UInt32(payload.count).bigEndian
    var data = Data(bytes: &length, count: 4)
    data.append(payload)
    return data
  }
}

public final class UDSFrameParser {
  public private(set) var failed = false
  public private(set) var skippedFrames = 0
  private var buffer = Data()
  private let maxPayloadBytes: Int

  public init(maxPayloadBytes: Int = UDSFrame.maxPayloadBytes) {
    self.maxPayloadBytes = maxPayloadBytes
  }

  public func append(_ chunk: Data) -> [UDS.Envelope] {
    guard !self.failed else { return [] }
    self.buffer.append(chunk)
    var envelopes: [UDS.Envelope] = []
    while self.buffer.count >= 4 {
      let lengthBytes = [UInt8](self.buffer.prefix(4))
      let length = lengthBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
      guard length <= self.maxPayloadBytes else {
        // an oversized frame means the stream can never resync; the
        // connection must be torn down and re-established by the peer
        self.failed = true
        self.buffer.removeAll()
        return envelopes
      }
      guard self.buffer.count >= 4 + Int(length) else { break }
      let payload = self.buffer.dropFirst(4).prefix(Int(length))
      self.buffer = Data(self.buffer.dropFirst(4 + Int(length)))
      if let envelope = try? JSONDecoder().decode(UDS.Envelope.self, from: Data(payload)) {
        envelopes.append(envelope)
      } else {
        // tolerate version skew: an unknown message from a newer/older
        // peer skips one frame, the stream itself stays in sync
        self.skippedFrames += 1
      }
    }
    return envelopes
  }
}
