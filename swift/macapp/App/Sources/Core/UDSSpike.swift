import Foundation

public enum UDSSpike {
  public static let markerPath = "/private/etc/gertrude-uds-spike"
  public static let socketDir = "/var/run/gertrude"

  public static var isEnabled: Bool {
    FileManager.default.fileExists(atPath: self.markerPath)
  }

  public static func socketPath(for uid: uid_t, in dir: String = socketDir) -> String {
    "\(dir)/spike-\(uid).sock"
  }
}

public enum UDSSpikeMessage: Codable, Equatable, Sendable {
  case hello(pid: Int32, uid: UInt32, version: String)
  case helloAck(filterPid: Int32, filterVersion: String)
  case ping(seq: Int)
  case pong(seq: Int)
  case filterPush(seq: Int)
  case pushAck(seq: Int)
  case blob(seq: Int, data: Data)
  case blobAck(seq: Int, byteCount: Int, checksum: UInt32)
}

public enum UDSFrame {
  public static let maxPayloadBytes = 16 * 1024 * 1024

  public static func encode(_ msg: UDSSpikeMessage) throws -> Data {
    let payload = try JSONEncoder().encode(msg)
    var length = UInt32(payload.count).bigEndian
    var data = Data(bytes: &length, count: 4)
    data.append(payload)
    return data
  }

  public static func checksum(_ data: Data) -> UInt32 {
    var hash: UInt32 = 2_166_136_261
    for byte in data {
      hash = (hash ^ UInt32(byte)) &* 16_777_619
    }
    return hash
  }
}

public final class UDSFrameParser {
  private var buffer = Data()
  private let maxPayloadBytes: Int

  public init(maxPayloadBytes: Int = UDSFrame.maxPayloadBytes) {
    self.maxPayloadBytes = maxPayloadBytes
  }

  public func append(_ chunk: Data) -> [UDSSpikeMessage] {
    self.buffer.append(chunk)
    var messages: [UDSSpikeMessage] = []
    while self.buffer.count >= 4 {
      let lengthBytes = [UInt8](self.buffer.prefix(4))
      let length = lengthBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
      guard length <= self.maxPayloadBytes else {
        self.buffer.removeAll()
        break
      }
      guard self.buffer.count >= 4 + Int(length) else { break }
      let payload = self.buffer.dropFirst(4).prefix(Int(length))
      self.buffer = Data(self.buffer.dropFirst(4 + Int(length)))
      if let msg = try? JSONDecoder().decode(UDSSpikeMessage.self, from: Data(payload)) {
        messages.append(msg)
      }
    }
    return messages
  }
}
