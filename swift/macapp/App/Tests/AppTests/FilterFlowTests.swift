import Gertie
import XCTest

@testable import Core

class FilterFlowTests: XCTestCase {
  func testExtractsHostnameFromDesc() throws {
    let flow = TestDesc(hostname: "www.wikipedia.org").flow
    XCTAssertEqual(flow.hostname, "www.wikipedia.org")
  }

  func testExtractsIpv4IpFromDesc() throws {
    let cases = [
      ("208.80.154.224:443", "208.80.154.224"),
      ("1.2.3.4:80", "1.2.3.4"),
      ("0.0.0.0:443", "0.0.0.0"),
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.ipAddress, expected)
    }
  }

  func testExtractsIpV6FromDesc() throws {
    let cases = [
      ("2001:4998:24:120d::1:0.443", "2001:4998:24:120d::1:0"),
      ("2001:4998:60:800::1105.443", "2001:4998:60:800::1105"),
      ("2001:4998:58:204::2000.443", "2001:4998:58:204::2000"),
      ("::.443", "::"), // the `any` "unspecified" adddress
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.ipAddress, expected)
    }
  }

  func testIsLocal() throws {
    let cases = [
      ("12.2.3.4:80", false),
      ("::1.80", true),
      ("0:0:0:0:0:0:0:1.80", true),
      ("127.0.0.1:80", true),
      ("127.0.0.1:443", true),
      ("2001:4998:24:120d::1:0.443", false),
    ]
    for (endpoint, expected) in cases {
      let flow = TestDesc(endpoint: endpoint).flow
      XCTAssertEqual(flow.isLocal, expected)
    }
  }

  func testExtractsPortFromEndpoint() throws {
    let cases: [(String, Core.Port?)] = [
      ("unexpected", nil),
      ("1.2.3.4:80", .http(80)),
      ("1.2.3.4:443", .https(443)),
      ("1.2.3.4:53", .dns(53)),
      ("1.2.3.4:222", .other(222)),
      ("::.443", .https(443)),
      ("::.80", .http(80)),
      ("::.53", .dns(53)),
      ("::.222", .other(222)),
    ]
    for (remoteEndpoint, port) in cases {
      let flow = TestDesc(endpoint: remoteEndpoint).flow
      XCTAssertEqual(flow.port, port)
    }
  }

  func testExtractsProtocolFromDesc() throws {
    let cases: [(Int, IpProtocol)] = [
      (6, .tcp(6)),
      (17, .udp(17)),
      (26, .other(26)),
    ]
    for (actual, expected) in cases {
      let flow = TestDesc(ipProtocol: actual).flow
      XCTAssertEqual(flow.ipProtocol, expected)
    }
  }
}

struct TestDesc {
  var hostname: String = "www.wikipedia.org"
  var endpoint: String = "0.0.0.0:80"
  var appId: String = ".com.apple.Safari"
  var ipProtocol: Int = 6

  init(appId: String) {
    self.appId = appId
  }

  init(endpoint: String) {
    self.endpoint = endpoint
  }

  init(hostname: String) {
    self.hostname = hostname
  }

  init(ipProtocol: Int) {
    self.ipProtocol = ipProtocol
  }

  var flow: FilterFlow { FilterFlow(url: nil, description: self.get) }

  var get: String {
    """
        identifier = 5B4BF304-E46B-4602-9C09-7EF0BC9D1757
        hostname = \(self.hostname)
        sourceAppIdentifier = \(self.appId)
        sourceAppVersion = 14.0.1
        sourceAppUniqueIdentifier = 20:{length = 20, bytes = 0xf0c4232c3a01828c129246f4b575524558714576}
        procPID = 41141
        eprocPID = 41141
        direction = outbound
        inBytes = 0
        outBytes = 0
        signature = 32:{...}
        remoteEndpoint = \(self.endpoint)
        protocol = \(self.ipProtocol)
        family = 2
        type = 1
        procUUID = 5DBC6092-DC53-3DA2-A09C-48B532B84D11
        eprocUUID = 5DBC6092-DC53-3DA2-A09C-48B532B84D11
    """
  }
}
