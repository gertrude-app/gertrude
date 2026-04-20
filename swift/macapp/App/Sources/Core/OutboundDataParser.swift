import Foundation

public enum OutboundDataParser {
  public enum Result: Equatable {
    case http(url: String, hostname: String)
    case tls(serverName: String)
    case tlsNoServerName
    case needMoreBytes(Int)
    case unsupportedProtocol
    case malformed
  }

  public static func parse(_ data: Data) -> Result {
    switch self.parseHTTP(data) {
    case .some(let result):
      return result
    case nil:
      break
    }

    return self.parseTLS(data)
  }

  private static let httpMethods: Set<[UInt8]> = [
    Array("GET".utf8),
    Array("POST".utf8),
    Array("PUT".utf8),
    Array("PATCH".utf8),
    Array("DELETE".utf8),
    Array("HEAD".utf8),
    Array("OPTIONS".utf8),
    Array("CONNECT".utf8),
    Array("TRACE".utf8),
  ]

  private static func parseHTTP(_ data: Data) -> Result? {
    guard data.count >= 4 else {
      return nil
    }

    let headerTerminator = Data([0x0D, 0x0A, 0x0D, 0x0A])
    guard let headerEnd = data.range(of: headerTerminator)?.lowerBound else {
      return self.httpHeaderNeedMoreBytes(data).map(Result.needMoreBytes)
    }

    guard let requestLineEnd = data.range(of: Data([0x0D, 0x0A]))?.lowerBound,
          requestLineEnd < headerEnd
    else {
      return .malformed
    }

    let requestLine = data.prefix(requestLineEnd)
    let requestLineBytes = [UInt8](requestLine)
    guard let firstSpace = requestLineBytes.firstIndex(of: 0x20),
          let secondSpace = requestLineBytes[(firstSpace + 1)...].firstIndex(of: 0x20)
    else {
      return self.httpHeaderNeedMoreBytes(data)
        .map(Result.needMoreBytes) ?? .unsupportedProtocol
    }

    let methodBytes = Array(requestLineBytes[..<firstSpace])
    guard self.isHTTPMethod(methodBytes) else {
      return nil
    }

    let pathBytes = Array(requestLineBytes[(firstSpace + 1) ..< secondSpace])
    let versionBytes = Array(requestLineBytes[(secondSpace + 1)...])
    guard let path = String(bytes: pathBytes, encoding: .utf8),
          let version = String(bytes: versionBytes, encoding: .utf8),
          version.hasPrefix("HTTP/")
    else {
      return .malformed
    }

    let headerBytes = data[data.index(after: requestLineEnd) ..< headerEnd]
    for line in self.splitHTTPHeaderLines(headerBytes) {
      guard let separator = line.firstIndex(of: 0x3A) else {
        return .malformed
      }
      let name = String(bytes: line[..<separator], encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
      guard let name else {
        return .malformed
      }
      guard name.caseInsensitiveCompare("Host") == .orderedSame else {
        continue
      }
      let valueBytes = self.trimHTTPHeaderValue(line[line.index(after: separator)...])
      guard let authority = String(bytes: valueBytes, encoding: .utf8),
            let host = parseHTTPHostAuthority(authority)
      else {
        return .malformed
      }
      guard let url = makeHTTPURL(hostAuthority: host.urlAuthority, requestTarget: path) else {
        return .malformed
      }
      return .http(url: url, hostname: host.hostname)
    }

    return .malformed
  }

  private static func parseTLS(_ data: Data) -> Result {
    guard let firstByte = data.first else {
      return .unsupportedProtocol
    }
    guard firstByte == 0x16 else {
      return .unsupportedProtocol
    }
    guard data.count >= 5 else {
      return .needMoreBytes(5)
    }
    guard data[1] == 0x03 else {
      return .unsupportedProtocol
    }

    let recordLength = Int(data[3]) << 8 | Int(data[4])
    let totalRecordLength = 5 + recordLength
    guard data.count >= totalRecordLength else {
      return .needMoreBytes(totalRecordLength)
    }

    let recordPayload = Data(data[5 ..< totalRecordLength])
    guard recordPayload.count >= 4 else {
      return .malformed
    }
    guard recordPayload.first == 0x01 else {
      return .unsupportedProtocol
    }

    let clientHelloLength = Int(recordPayload[1]) << 16 | Int(recordPayload[2]) << 8
      | Int(recordPayload[3])
    guard recordPayload.count >= 4 + clientHelloLength else {
      return .needMoreBytes(5 + 4 + clientHelloLength)
    }

    let clientHelloData = Data(recordPayload[4 ..< (4 + clientHelloLength)])
    guard let reader = parseClientHello(clientHelloData) else {
      return .malformed
    }
    return reader
  }

  private static func parseClientHello(_ data: Data) -> Result? {
    var reader = ByteReader(data)

    guard reader.readUInt16() != nil else {
      return nil
    }
    guard reader.readBytes(count: 32) != nil else {
      return nil
    }
    guard let sessionIdLength = reader.readUInt8(),
          reader.readBytes(count: Int(sessionIdLength)) != nil,
          let cipherSuitesLength = reader.readUInt16(),
          cipherSuitesLength.isMultiple(of: 2),
          reader.readBytes(count: Int(cipherSuitesLength)) != nil,
          let compressionMethodsLength = reader.readUInt8(),
          reader.readBytes(count: Int(compressionMethodsLength)) != nil
    else {
      return nil
    }

    if reader.remainingCount == 0 {
      return .tlsNoServerName
    }

    guard let extensionsLength = reader.readUInt16(),
          let extensions = reader.readBytes(count: Int(extensionsLength))
    else {
      return nil
    }

    var extensionReader = ByteReader(extensions)
    while extensionReader.remainingCount > 0 {
      guard let type = extensionReader.readUInt16(),
            let length = extensionReader.readUInt16(),
            let payload = extensionReader.readBytes(count: Int(length))
      else {
        return nil
      }
      guard type == 0 else {
        continue
      }
      return self.parseServerNameExtension(payload)
    }

    return .tlsNoServerName
  }

  private static func parseServerNameExtension(_ data: Data) -> Result? {
    var reader = ByteReader(data)
    guard let listLength = reader.readUInt16(),
          let listData = reader.readBytes(count: Int(listLength))
    else {
      return nil
    }

    var listReader = ByteReader(listData)
    while listReader.remainingCount > 0 {
      guard let nameType = listReader.readUInt8(),
            let nameLength = listReader.readUInt16(),
            let nameData = listReader.readBytes(count: Int(nameLength))
      else {
        return nil
      }
      guard nameType == 0 else {
        continue
      }
      guard let hostname = String(bytes: nameData, encoding: .utf8),
            isLikelyHostname(hostname)
      else {
        return .malformed
      }
      return .tls(serverName: hostname)
    }

    return .tlsNoServerName
  }

  private static func httpHeaderNeedMoreBytes(_ data: Data) -> Int? {
    if let requestLineEnd = data.range(of: Data([0x0D, 0x0A]))?.lowerBound {
      let requestLine = data.prefix(requestLineEnd)
      let requestLineBytes = [UInt8](requestLine)
      guard let firstSpace = requestLineBytes.firstIndex(of: 0x20),
            let secondSpace = requestLineBytes[(firstSpace + 1)...].firstIndex(of: 0x20)
      else {
        return nil
      }

      let methodBytes = Array(requestLineBytes[..<firstSpace])
      guard self.isHTTPMethod(methodBytes) else {
        return nil
      }

      let versionBytes = Array(requestLineBytes[(secondSpace + 1)...])
      guard let version = String(bytes: versionBytes, encoding: .utf8),
            version.hasPrefix("HTTP/")
      else {
        return nil
      }

      return min(data.count + 2048, 16384)
    }

    let methods = [
      "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "CONNECT", "TRACE",
    ]
    let prefix = String(decoding: data.prefix(16), as: UTF8.self).uppercased()
    for method in methods {
      if method.hasPrefix(prefix) || prefix.hasPrefix(method + " ") {
        return min(data.count + 2048, 16384)
      }
    }

    return nil
  }

  private static func parseHTTPHostAuthority(_ authority: String)
    -> (hostname: String, urlAuthority: String)? {
    guard !authority.isEmpty else {
      return nil
    }

    if authority.first == "[" {
      guard let closingBracket = authority.firstIndex(of: "]") else {
        return nil
      }
      let hostnameStart = authority.index(after: authority.startIndex)
      let hostname = String(authority[hostnameStart ..< closingBracket])
      guard !hostname.isEmpty else {
        return nil
      }

      let remainderStart = authority.index(after: closingBracket)
      let remainder = authority[remainderStart...]
      guard remainder.isEmpty || self.isValidHTTPPortSuffix(String(remainder)) else {
        return nil
      }
      return (hostname, authority)
    }

    let parts = authority.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
    guard let hostnamePart = parts.first else {
      return nil
    }
    let hostname = String(hostnamePart)
    guard self.isLikelyHostname(hostname) else {
      return nil
    }

    if parts.count == 2 {
      guard self.isValidHTTPPort(String(parts[1])) else {
        return nil
      }
    }

    return (hostname, authority)
  }

  private static func makeHTTPURL(hostAuthority: String, requestTarget: String) -> String? {
    if requestTarget.hasPrefix("http://") || requestTarget.hasPrefix("https://") {
      return requestTarget
    }
    if requestTarget == "*" {
      return "http://\(hostAuthority)/*"
    }
    if requestTarget.hasPrefix("/") {
      return "http://\(hostAuthority)\(requestTarget)"
    }
    if !requestTarget.isEmpty {
      return "http://\(requestTarget)"
    }
    return nil
  }

  private static func isHTTPMethod(_ bytes: [UInt8]) -> Bool {
    self.httpMethods.contains(bytes)
  }

  private static func splitHTTPHeaderLines(_ data: Data) -> [Data] {
    data
      .split(separator: 0x0A, omittingEmptySubsequences: false)
      .map { line in
        if line.last == 0x0D {
          return Data(line.dropLast())
        }
        return Data(line)
      }
      .filter { !$0.isEmpty }
  }

  private static func trimHTTPHeaderValue(_ data: Data.SubSequence) -> Data {
    var lower = data.startIndex
    var upper = data.endIndex

    while lower < upper, data[lower].isHTTPWhitespace {
      lower = data.index(after: lower)
    }
    while lower < upper {
      let previous = data.index(before: upper)
      guard data[previous].isHTTPWhitespace else {
        break
      }
      upper = previous
    }
    return Data(data[lower ..< upper])
  }

  private static func isLikelyHostname(_ hostname: String) -> Bool {
    guard !hostname.isEmpty,
          hostname.utf8.count <= 253,
          !hostname.hasPrefix("."),
          !hostname.hasSuffix(".")
    else {
      return false
    }

    let allowed = CharacterSet(
      charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._",
    )
    guard hostname.unicodeScalars.allSatisfy(allowed.contains) else {
      return false
    }

    return hostname.split(separator: ".").allSatisfy { label in
      !label.isEmpty && label.utf8.count <= 63 && label.first != "-" && label.last != "-"
    }
  }

  private static func isValidHTTPPortSuffix(_ suffix: String) -> Bool {
    guard suffix.first == ":" else {
      return false
    }
    return self.isValidHTTPPort(String(suffix.dropFirst()))
  }

  private static func isValidHTTPPort(_ value: String) -> Bool {
    guard !value.isEmpty, value.count <= 5 else {
      return false
    }
    return value.unicodeScalars.allSatisfy(CharacterSet.decimalDigits.contains)
  }
}

private struct ByteReader {
  private let data: Data
  private var offset: Int = 0

  init(_ data: Data) {
    self.data = data
  }

  var remainingCount: Int {
    self.data.count - self.offset
  }

  mutating func readUInt8() -> UInt8? {
    guard self.offset < self.data.count else {
      return nil
    }
    defer { offset += 1 }
    return self.data[self.offset]
  }

  mutating func readUInt16() -> UInt16? {
    guard let first = readUInt8(), let second = readUInt8() else {
      return nil
    }
    return UInt16(first) << 8 | UInt16(second)
  }

  mutating func readBytes(count: Int) -> Data? {
    guard count >= 0, self.offset + count <= self.data.count else {
      return nil
    }
    defer { offset += count }
    return Data(self.data[self.offset ..< (self.offset + count)])
  }
}

private extension UInt8 {
  var isHTTPWhitespace: Bool {
    self == 0x20 || self == 0x09 || self == 0x0D || self == 0x0A
  }
}

public extension OutboundDataParser.Result {
  var hostname: String? {
    switch self {
    case .http(_, let hostname):
      hostname
    case .tls(let serverName):
      serverName
    case .tlsNoServerName, .needMoreBytes, .unsupportedProtocol, .malformed:
      nil
    }
  }

  var url: String? {
    switch self {
    case .http(let url, _):
      url
    case .tls, .tlsNoServerName, .needMoreBytes, .unsupportedProtocol, .malformed:
      nil
    }
  }

  var logDescription: String {
    switch self {
    case .http(let url, let hostname):
      "http hostname=\(hostname) url=\(url)"
    case .tls(let serverName):
      "tls serverName=\(serverName)"
    case .tlsNoServerName:
      "tlsNoServerName"
    case .needMoreBytes(let count):
      "needMoreBytes(\(count))"
    case .unsupportedProtocol:
      "unsupportedProtocol"
    case .malformed:
      "malformed"
    }
  }
}
