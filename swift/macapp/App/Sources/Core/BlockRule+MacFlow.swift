import Foundation
import Gertie

public extension BlockRule {
  func blocksFlow(_ flow: FilterFlow) -> Bool {
    let hostname = flow.hostname ?? flow.url.flatMap {
      guard $0.hasPrefix("http://") || $0.hasPrefix("https://") else { return nil }
      return URL(string: $0)?.host
    }
    let lowercasedHostname = hostname?.lowercased()
    let target = flow.url ?? flow.hostname
    switch self {
    case .bundleIdContains(let fragment):
      return flow.bundleId?.contains(fragment) == true
    case .targetContains(let fragment):
      return target?.contains(fragment) == true
    case .urlContains(let fragment):
      return flow.url?.contains(fragment) == true
    case .hostnameContains(let fragment):
      return lowercasedHostname?.contains(fragment.lowercased()) == true
    case .hostnameEquals(let fragment):
      return lowercasedHostname == fragment.lowercased()
    case .hostnameEndsWith(let fragment):
      return lowercasedHostname?.hasSuffix(fragment.lowercased()) == true
    case .hostnameOrSubdomain(let domain):
      guard let lowercasedHostname else { return false }
      let lowercasedDomain = domain.lowercased()
      return lowercasedHostname == lowercasedDomain
        || lowercasedHostname.hasSuffix("." + lowercasedDomain)
    case .flowTypeIs(let type):
      return flow.flowType == type
    case .both(let a, let b):
      return a.blocksFlow(flow) && b.blocksFlow(flow)
    case .unless(let rule, let negatedBy):
      if rule.blocksFlow(flow) {
        return !negatedBy.contains { $0.blocksFlow(flow) }
      } else {
        return false
      }
    }
  }
}
