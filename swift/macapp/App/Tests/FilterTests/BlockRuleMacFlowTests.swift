import Core
import Gertie
import XCTest

final class BlockRuleMacFlowTests: XCTestCase {
  func testBlocksFlow() {
    let cases: [(BlockRule, Case)] = [
      // hostnameContains()
      (.hostnameContains(value: "a.com"), .init(host: "bla.com", block: true)),
      (.hostnameContains(value: "a.com"), .init(host: "bla.com.uk", block: true)),
      (.hostnameContains(value: "a.com"), .init(host: "blah.com", block: false)),
      (.hostnameContains(value: "a.com"), .init(host: "b.com", url: "b.com/a.com", block: false)),
      // hostnameEquals()
      (.hostnameEquals(value: "a.com"), .init(host: "a.com", block: true)),
      (.hostnameEquals(value: "a.com"), .init(host: "a.com.uk", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "bla.com", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "b.com", block: false)),
      (.hostnameEquals(value: "a.com"), .init(host: "b.com", url: "a.com", block: false)),
      // hostnameEndsWith()
      (.hostnameEndsWith(value: "a.com"), .init(host: "bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: "www.a.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: "bla.com.uk", block: false)),
      // safely deriving hostname from url only
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "https://bla.com/", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "https://bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "http://bla.com", block: true)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "ftp://bla.com", block: false)),
      (.hostnameEndsWith(value: "a.com"), .init(host: nil, url: "bla.com", block: false)),
      (
        .hostnameEquals(value: "www.safe.com"),
        .init(host: nil, url: "https://www.safe.com/foo/bar", block: true),
      ),
      (
        .hostnameEndsWith(value: "safe.com"),
        .init(host: nil, url: "https://foo.bar-sobaz.qux.safe.com/foo/bar", block: true),
      ),
      // unless(rule:negatedBy:)
      (
        .unless(
          rule: .bundleIdContains(value: "com.apple.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "bad.com", src: ".com.apple.Safari", block: true),
      ),
      (
        .unless(
          rule: .bundleIdContains(value: "com.apple.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "www.kids.org", src: ".com.apple.Safari", block: false),
      ),
      (
        .unless(
          rule: .bundleIdContains(value: "com.apple.Safari"),
          negatedBy: [.hostnameEndsWith(value: "safe.com"), .hostnameEndsWith(value: "kids.org")],
        ),
        .init(host: "bad.com", src: "com.other.app", block: false),
      ),
      // both(a:b:)
      (
        .both(
          a: .bundleIdContains(value: "com.apple.MobileSMS"),
          b: .targetContains(value: "ssl.mzstatic.com"),
        ),
        .init(host: "is1-ssl.mzstatic.com", src: ".com.apple.MobileSMS", block: true),
      ),
      (
        .both(
          a: .bundleIdContains(value: "com.apple.MobileSMS"),
          b: .targetContains(value: "ssl.mzstatic.com"),
        ),
        .init(host: "is1-ssl.mzstatic.com", src: "com.other.app", block: false),
      ),
      // targetContains() — url wins over hostname when url is set
      (.targetContains(value: "giphy.com"), .init(host: "giphy.com", block: true)),
      (.targetContains(value: "giphy.com"), .init(host: "other.com", block: false)),
      (
        .targetContains(value: "giphy.com"),
        .init(host: "cdn.other.com", url: "https://cdn.other.com/a/giphy.com/x", block: true),
      ),
      // urlContains() — only matches when url is set
      (.urlContains(value: "tenor.co"), .init(host: "tenor.co", block: false)),
      (
        .urlContains(value: "tenor.co"),
        .init(host: "tenor.co", url: "https://tenor.co/a", block: true),
      ),
      // bundleIdContains()
      (.bundleIdContains(value: "MobileSMS"), .init(src: ".com.apple.MobileSMS", block: true)),
      (.bundleIdContains(value: "MobileSMS"), .init(src: "com.other.app", block: false)),
      // flowTypeIs() — mac reads authoritative flowType from NEFilterFlow subclass
      (.flowTypeIs(value: .browser), .init(flowType: .browser, block: true)),
      (.flowTypeIs(value: .browser), .init(flowType: .socket, block: false)),
      (.flowTypeIs(value: .browser), .init(flowType: nil, block: false)),
      (.flowTypeIs(value: .socket), .init(flowType: .browser, block: false)),
      (.flowTypeIs(value: .socket), .init(flowType: .socket, block: true)),
      (.flowTypeIs(value: .socket), .init(flowType: nil, block: false)),
    ]

    for (rule, c) in cases {
      XCTAssertEqual(
        rule.blocksFlow(FilterFlow.test(
          url: c.url,
          hostname: c.host,
          bundleId: c.src,
          flowType: c.flowType,
        )),
        c.block,
        "rule: \(rule), case: \(c)",
      )
    }
  }
}

private struct Case {
  let host: String?
  let url: String?
  let src: String
  let flowType: FlowType?
  let block: Bool

  init(
    host: String? = nil,
    url: String? = nil,
    src: String = "com.acme.app",
    flowType: FlowType? = nil,
    block: Bool,
  ) {
    self.host = host
    self.url = url
    self.src = src
    self.flowType = flowType
    self.block = block
  }
}
