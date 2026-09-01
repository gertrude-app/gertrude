import TestSupport
import XCTest

@testable import Core

final class OutboundDataParserTests: XCTestCase {
  func testParsesHttpRequest() {
    let data = Data(
      "GET /cards HTTP/1.1\r\nHost: api-win.howtocomputer.link\r\nConnection: keep-alive\r\n\r\n"
        .utf8,
    )

    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(
        url: "http://api-win.howtocomputer.link/cards",
        hostname: "api-win.howtocomputer.link",
      ),
    )
  }

  func testParsesHttpRequestWithHostPort() {
    let data = Data(
      "GET /health HTTP/1.1\r\nHost: example.com:8080\r\nConnection: keep-alive\r\n\r\n"
        .utf8,
    )

    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(url: "http://example.com:8080/health", hostname: "example.com"),
    )
  }

  func testParsesHttpRequestWithUnderscoreHostname() {
    let data = Data("GET /health HTTP/1.1\r\nHost: foo_bar.example.com\r\n\r\n".utf8)

    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(
        url: "http://foo_bar.example.com/health",
        hostname: "foo_bar.example.com",
      ),
    )
  }

  func testParsesAbsoluteFormHttpRequest() {
    let data = Data("GET http://foo.example/path?q=1 HTTP/1.1\r\nHost: foo.example\r\n\r\n".utf8)
    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(
        url: "http://foo.example/path?q=1",
        hostname: "foo.example",
      ),
    )
  }

  func testParsesAsteriskFormHttpRequest() {
    let data = Data("OPTIONS * HTTP/1.1\r\nHost: example.com\r\n\r\n".utf8)
    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(
        url: "http://example.com/*",
        hostname: "example.com",
      ),
    )
  }

  func testParsesConnectHttpRequest() {
    let data = Data("CONNECT example.com:443 HTTP/1.1\r\nHost: example.com:443\r\n\r\n".utf8)
    XCTAssertEqual(
      OutboundDataParser.parse(data),
      .http(
        url: "http://example.com:443",
        hostname: "example.com",
      ),
    )
  }

  func testReportsMeaningfulNeedMoreBytesForIncompleteHttpHeaders() {
    let data = Data(
      "GET /cards HTTP/1.1\r\nHost: api-win.howtocomputer.link\r\nConnection: keep-alive"
        .utf8,
    )

    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .needMoreBytes(min(data.count + 2048, 16384)))
  }

  func testReportsMeaningfulNeedMoreBytesForTruncatedHttpRequestLine() {
    let data = Data(("GET /search?q=" + String(repeating: "a", count: 3000)).utf8)

    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .needMoreBytes(min(data.count + 2048, 16384)))
  }

  func testParsesTlsServerName() {
    let data = makeTLSClientHello(serverName: "www.google.com")
    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .tls(serverName: "www.google.com"))
  }

  func testParsesTlsServerNameWithUnderscore() {
    let data = makeTLSClientHello(serverName: "foo_bar.example.com")
    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .tls(serverName: "foo_bar.example.com"))
  }

  func testParsesTlsWithoutServerName() {
    let data = makeTLSClientHello(serverName: nil)
    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .tlsNoServerName)
  }

  func testReportsNeedMoreBytesForTruncatedTlsRecord() {
    let data = makeTLSClientHello(serverName: "www.google.com")
    let truncated = data.prefix(20)
    let result = OutboundDataParser.parse(Data(truncated))
    XCTAssertEqual(result, .needMoreBytes(data.count))
  }

  func testRejectsNonTlsVersionFromRecordHeaderWithoutWaitingForFullRecord() {
    let data = Data([0x16, 0x01, 0x00, 0x7F, 0xFF])
    let result = OutboundDataParser.parse(data)
    XCTAssertEqual(result, .unsupportedProtocol)
  }

  func testParseOutboundDataUpdatesFlow() {
    var flow = FilterFlow()
    let result = flow.parseOutboundData(makeTLSClientHello(serverName: "www.google.com"))

    XCTAssertEqual(result, OutboundDataParser.Result.tls(serverName: "www.google.com"))
    XCTAssertEqual(flow.hostname, "www.google.com")
    XCTAssertNil(flow.url)
  }

  func testStructuredParserAvoidsLegacyHostnameOvershoot() {
    let data = makeTLSClientHello(
      serverName: "www.google.com",
      sessionId: Data(),
      serverNameTrailingBytes: Data("zz".utf8),
    )

    let legacy = parseOutboundDataLegacy(byteString: bytesToAscii(data))
    XCTAssertEqual(legacy.hostname, "www.google.comzz") // <-- old method failed here

    let structured = OutboundDataParser.parse(data)
    XCTAssertEqual(structured, OutboundDataParser.Result.tls(serverName: "www.google.com"))
  }

  func testStructuredParserRecoversRealHostnameFromNoise() {
    let data = makeTLSClientHello(
      serverName: "content-autofill.googleapis.com",
      sessionId: Data("u.b5".utf8),
      serverNameTrailingBytes: Data(),
    )

    let legacy = parseOutboundDataLegacy(byteString: bytesToAscii(data))
    XCTAssertEqual(legacy.hostname, "u.b5") // <-- old method failed here

    XCTAssertEqual(
      OutboundDataParser.parse(data),
      OutboundDataParser.Result.tls(serverName: "content-autofill.googleapis.com"),
    )
  }

  func testTlsSampleSupportsNeedMoreBytesRetry() {
    let data = makeTLSClientHello(serverName: "www.google.com")

    let full = OutboundDataParser.parse(data)
    XCTAssertEqual(full, .tls(serverName: "www.google.com"))

    let retry = firstRecoverableRetry(in: data)
    XCTAssertNotNil(retry)
    XCTAssertLessThan(retry!.prefixLength, retry!.requestedTotal)
    XCTAssertLessThanOrEqual(retry!.requestedTotal, data.count)
    XCTAssertEqual(
      OutboundDataParser.parse(Data(data.prefix(retry!.prefixLength))),
      .needMoreBytes(retry!.requestedTotal),
    )
    XCTAssertEqual(
      OutboundDataParser.parse(Data(data.prefix(retry!.requestedTotal))),
      full,
    )
  }
}

// this was our former method for parsing outbound data, retained only for test comparison
func parseOutboundDataLegacy(byteString: String) -> (hostname: String?, url: String?) {
  if let range = byteString.range(
    of: #"^(GET|POST|PUT|PATCH|DELETE)•[^•]+•HTTP/[^•]+••Host••[^•]+"#,
    options: .regularExpression,
  ) {
    let firstChunk = String(byteString[range])
    let pieces = firstChunk.components(separatedBy: "•").filter { $0 != "" }
    let url = "http://" + pieces[4] + pieces[1]
    let hostname = pieces[4]
    return (hostname: hostname, url: url)
  }

  if let range = byteString.range(
    of: #"[a-z0-9_-]{1,}(\.[a-z0-9_-]{1,}){0,5}\.[a-z0-9_-]{2,}"#,
    options: .regularExpression,
  ) {
    let hostname = String(byteString[range])
    return (hostname: hostname, url: nil)
  }

  return (hostname: nil, url: nil)
}

private func firstRecoverableRetry(in data: Data) -> (prefixLength: Int, requestedTotal: Int)? {
  let full = OutboundDataParser.parse(data)
  for prefixLength in 1 ..< data.count {
    let prefix = Data(data.prefix(prefixLength))
    guard case .needMoreBytes(let requestedTotal) = OutboundDataParser.parse(prefix),
          requestedTotal > prefixLength,
          requestedTotal <= data.count
    else {
      continue
    }
    let resumed = OutboundDataParser.parse(Data(data.prefix(requestedTotal)))
    if resumed == full {
      return (prefixLength, requestedTotal)
    }
  }
  return nil
}
