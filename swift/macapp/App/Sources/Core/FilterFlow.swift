import Foundation
import Gertie
import Network

public struct FilterFlow: Equatable, Codable, Sendable {
  public var url: String?
  public var ipAddress: String?
  public var hostname: String?
  public var bundleId: String?
  public var remoteEndpoint: String?
  public var userId: uid_t?
  public var port: Port?
  public var ipProtocol: IpProtocol?
  public var flowType: FlowType?

  public var isDnsRequest: Bool {
    self.isUDP && self.port == .dns(53)
  }

  public var isUDP: Bool {
    self.ipProtocol == .udp(Int32(IPPROTO_UDP))
  }

  public var isLocal: Bool {
    if self.ipAddress == "127.0.0.1" || self.ipAddress == "::1" || self
      .ipAddress == "0:0:0:0:0:0:0:1" {
      return true
    }
    if self.hostname == "localhost" {
      return true
    }
    return false
  }

  public var isPrivateNetwork: Bool {
    guard let ip = ipAddress else {
      return false
    }
    // https://en.wikipedia.org/wiki/Reserved_IP_addresses
    let prefixes = ["10.", "100.64.", "192.0.0.", "192.168."]
    for prefix in prefixes {
      if ip.hasPrefix(prefix) {
        return true
      }
    }

    if !ip.hasPrefix("172.") {
      return false
    }

    let parts = ip.split(separator: ".")
    if parts.count < 2 {
      return false
    }

    if let second = Int(parts[1]), second >= 16, second <= 31 {
      return true
    }

    return false
  }

  public var isFromGertrude: Bool {
    self.bundleId?.contains("com.netrivet.gertrude.app") == true
    // in testing, i've seen our bundle id come through as:
    // - `.com.netrivet.gertrude.app` (leading dot)
    // - `WFN83LM943.com.netrivet.gertrude.app` (full)
    // - not sure about `com.netrivet.gertrude.app`
  }

  public var isSystemUiServerInternal: Bool {
    self.bundleId == ".com.apple.systemuiserver" && self.isPrivateNetwork
  }

  @discardableResult
  public mutating func parseOutboundData(_ data: Data) -> OutboundDataParser.Result {
    let result = OutboundDataParser.parse(data)
    if let url = result.url {
      self.url = url
    }
    if let hostname = result.hostname {
      self.hostname = hostname
    }
    return result
  }

  public init(
    url: String? = nil,
    ipAddress: String? = nil,
    hostname: String? = nil,
    bundleId: String? = nil,
    remoteEndpoint: String? = nil,
    userId: uid_t? = nil,
    port: Port? = nil,
    ipProtocol: IpProtocol? = nil,
    flowType: FlowType? = nil,
  ) {
    self.url = url
    self.ipAddress = ipAddress
    self.hostname = hostname
    self.bundleId = bundleId
    self.remoteEndpoint = remoteEndpoint
    self.userId = userId
    self.port = port
    self.ipProtocol = ipProtocol
    self.flowType = flowType
  }

  public init(url: String?, description: String) {
    self.url = url
    let descLines = description.components(separatedBy: "\n")

    // @TODO: `protocol`, `remoteEndpoint`, `port`, and `ipAddress`
    // can be resolved faster and more stably by casting the `NEFilterFlow`
    // to a `NEFilterSocketFlow`, and insepecting the `.remoteEndpoint` class,
    // `.socketProtocol`, `.socketType`, etc. Not doing now (4/22/21) b/c it's
    // mostly just a speed and forward-compat issue, not pressing
    // it would definitely be better to reduce dependence on this debug description
    // and would likely be much faster if we could do less string matching/regex
    // that said, `hostname` and `bundleId` don't have easy workarounds
    // UPDATE: 11/24 - bundleId can likely be obtained from audit token

    for untrimmedLine in descLines {
      let line = untrimmedLine.trimmingCharacters(in: .whitespaces)
      if line.hasPrefix("sourceAppIdentifier") {
        self.bundleId = line.components(separatedBy: " = ").last ?? ""
      } else if line.hasPrefix("protocol") {
        self.ipProtocol = IpProtocol(line.components(separatedBy: " = ").last ?? "")
      } else if line.hasPrefix("hostname") {
        self.hostname = line.components(separatedBy: " = ").last ?? ""
      } else if line.hasPrefix("remoteEndpoint") {
        self.remoteEndpoint = line.components(separatedBy: " = ").last ?? line
        if self.remoteEndpoint?.matchesRegex(#"^\d+\.\d+\.\d+\.\d+:(\d+)$"#) == true {
          let parts = self.remoteEndpoint?.components(separatedBy: ":") ?? []
          if parts.count == 2 {
            self.ipAddress = parts.first!
            self.port = Port(parts.last!)
          }
        } else {
          let parts = self.remoteEndpoint?.components(separatedBy: ".") ?? []
          if parts.count != 2 {
            return
          }
          let noPort = parts.first!
          self.port = Port(parts.last!)
          if IPv6Address(noPort) != nil {
            self.ipAddress = noPort
          }
        }
      }
    }
  }

  public var shortDescription: String {
    [
      self.ipProtocol?.description,
      self.url ?? self.hostname ?? self.ipAddress ?? self.remoteEndpoint,
      self.bundleId,
    ]
    .compactMap(\.self)
    .joined(separator: " ")
  }
}

public func bytesToAscii(_ bytes: Data) -> String {
  var result = [UInt8]()
  result.reserveCapacity(bytes.count * 3)
  let dotBytes: [UInt8] = [0xE2, 0x80, 0xA2]
  for byte in bytes {
    switch byte {
    case 45 ... 57, 61, 63, 65 ... 90, 95, 97 ... 122:
      result.append(byte)
    default:
      result.append(contentsOf: dotBytes)
    }
  }
  return String(bytes: result, encoding: .utf8) ?? ""
}
