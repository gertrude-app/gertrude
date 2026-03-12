// swiftformat:disable extensionAccessControl
import TSCodable

/// TSCodable format, but with FlowType frozen in the pre-string object format.
/// context: https://gist.github.com/jaredh159/af45d98eee7f8a33b6b5af945ec23cfc
/// Used by ConnectedRules_v2 to avoid breaking iOS apps 1.4.x–1.7.x in the wild.
/// Delete when ConnectedRules_v3 ships and those app versions are retired.
extension BlockRule {
  @TSCodable
  public enum Frozen {
    case bundleIdContains(value: String)
    case urlContains(value: String)
    case hostnameContains(value: String)
    case hostnameEquals(value: String)
    case hostnameEndsWith(value: String)
    case targetContains(value: String)
    case flowTypeIs(value: FlowType.Legacy)
    indirect case both(a: BlockRule.Frozen, b: BlockRule.Frozen)
    indirect case unless(rule: BlockRule.Frozen, negatedBy: [BlockRule.Frozen])
  }

  public var frozen: Frozen {
    switch self {
    case .bundleIdContains(let v): .bundleIdContains(value: v)
    case .urlContains(let v): .urlContains(value: v)
    case .hostnameContains(let v): .hostnameContains(value: v)
    case .hostnameEquals(let v): .hostnameEquals(value: v)
    case .hostnameEndsWith(let v): .hostnameEndsWith(value: v)
    case .targetContains(let v): .targetContains(value: v)
    case .flowTypeIs(let v): .flowTypeIs(value: v.legacy)
    case .both(let a, let b): .both(a: a.frozen, b: b.frozen)
    case .unless(let rule, let negatedBy): .unless(
        rule: rule.frozen,
        negatedBy: negatedBy.map(\.frozen),
      )
    }
  }
}

extension BlockRule.Frozen: Equatable, Sendable, Hashable {}

public extension BlockRule.Frozen {
  var current: BlockRule {
    switch self {
    case .bundleIdContains(let v): .bundleIdContains(value: v)
    case .urlContains(let v): .urlContains(value: v)
    case .hostnameContains(let v): .hostnameContains(value: v)
    case .hostnameEquals(let v): .hostnameEquals(value: v)
    case .hostnameEndsWith(let v): .hostnameEndsWith(value: v)
    case .targetContains(let v): .targetContains(value: v)
    case .flowTypeIs(let v): .flowTypeIs(value: v == .browser ? .browser : .socket)
    case .both(let a, let b): .both(a: a.current, b: b.current)
    case .unless(let rule, let negatedBy): .unless(
        rule: rule.current,
        negatedBy: negatedBy.map(\.current),
      )
    }
  }
}

/// Pre 1.4.x type, didn't have typescript-friendly encoding, now deprecated
/// but preserved exactly as it was for encoding/decoding stored legacy data
public extension BlockRule {
  enum Legacy {
    case bundleIdContains(String)
    case urlContains(String)
    case hostnameContains(String)
    case hostnameEquals(String)
    case hostnameEndsWith(String)
    case targetContains(String)
    case flowTypeIs(FlowType.Legacy)
    indirect case both(BlockRule.Legacy, BlockRule.Legacy)
    indirect case unless(rule: BlockRule.Legacy, negatedBy: [BlockRule.Legacy])
  }

  var legacy: Legacy {
    switch self {
    case .both(let a, let b): .both(a.legacy, b.legacy)
    case .bundleIdContains(let bundleId): .bundleIdContains(bundleId)
    case .flowTypeIs(let flowType): .flowTypeIs(flowType.legacy)
    case .hostnameContains(let hostname): .hostnameContains(hostname)
    case .hostnameEndsWith(let hostname): .hostnameEndsWith(hostname)
    case .hostnameEquals(let hostname): .hostnameEquals(hostname)
    case .targetContains(let target): .targetContains(target)
    case .unless(let rule, let negatedBy): .unless(
        rule: rule.legacy,
        negatedBy: negatedBy.map(\.legacy),
      )
    case .urlContains(let url): .urlContains(url)
    }
  }
}

// extensions

public extension BlockRule.Legacy {
  var current: GertieIOS.BlockRule {
    switch self {
    case .bundleIdContains(let bundleId):
      .bundleIdContains(value: bundleId)
    case .urlContains(let url):
      .urlContains(value: url)
    case .hostnameContains(let hostname):
      .hostnameContains(value: hostname)
    case .hostnameEquals(let hostname):
      .hostnameEquals(value: hostname)
    case .hostnameEndsWith(let hostname):
      .hostnameEndsWith(value: hostname)
    case .targetContains(let target):
      .targetContains(value: target)
    case .flowTypeIs(let flowType):
      .flowTypeIs(value: flowType.current)
    case .both(let a, let b):
      .both(a: a.current, b: b.current)
    case .unless(let rule, let negatedBy):
      .unless(rule: rule.current, negatedBy: negatedBy.map(\.current))
    }
  }

  static var defaults: [BlockRule.Legacy] {
    [
      .bundleIdContains("HashtagImagesExtension"),
      .bundleIdContains("com.apple.Spotlight"),
      .bundleIdContains(".com.apple.photoanalysisd"),
      .urlContains("tenor.co"),
      .targetContains("cdn2.smoot.apple.com"),
      .targetContains("tenor.co"),
      .targetContains("giphy.com"),
      .targetContains("media.fosu2-1.fna.whatsapp.net"),
      .both(
        .bundleIdContains("com.apple.MobileSMS"),
        .targetContains("ssl.mzstatic.com"),
      ),
      .both(
        .bundleIdContains("org.whispersystems.signal"),
        .targetContains("contentproxy.signal.org"),
      ),
    ]
  }
}

extension BlockRule.Legacy: Equatable, Codable, Sendable, Hashable {}
