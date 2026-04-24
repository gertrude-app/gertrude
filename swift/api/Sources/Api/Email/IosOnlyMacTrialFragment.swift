import Foundation

enum DeviceKind: String, CaseIterable, Sendable {
  case iPhone
  case iPad

  init?(rawModelPrefix: String) {
    switch rawModelPrefix.lowercased() {
    case "iphone": self = .iPhone
    case "ipad": self = .iPad
    default: return nil
    }
  }

  var singular: String {
    switch self {
    case .iPhone: "iPhone"
    case .iPad: "iPad"
    }
  }

  var plural: String { "\(self.singular)s" }
}

struct IosOnlyMacTrialKid: Sendable {
  let name: String
  let kinds: Set<DeviceKind>
}

func iosOnlyMacTrialFragment(email: String, kids: [IosOnlyMacTrialKid]) -> String {
  var merged: [String: Set<DeviceKind>] = [:]
  var order: [String] = []
  var allKinds: Set<DeviceKind> = []
  for kid in kids {
    allKinds.formUnion(kid.kinds)
    guard let name = sanitizeChildName(kid.name) else { continue }
    if merged[name] == nil {
      order.append(name)
      merged[name] = []
    }
    merged[name]!.formUnion(kid.kinds)
  }
  let valid = order.map { (name: $0, kinds: merged[$0]!) }

  if valid.isEmpty {
    return "your child's \(deviceWord(allKinds, plural: false))"
  }

  if valid.count == 1 {
    let (name, kinds) = (valid[0].name, valid[0].kinds)
    let phrase = devicePhraseMixed(kinds)
    if looksSelfManaged(email: email, name: name) {
      return "your \(phrase)"
    }
    return "\(possessive(name)) \(phrase)"
  }

  let kindsUnion = valid.reduce(into: Set<DeviceKind>()) { $0.formUnion($1.kinds) }
  let word = deviceWord(kindsUnion, plural: true)
  return "\(joinNames(valid.map(\.name))) \(word)"
}

func sanitizeChildName(_ raw: String) -> String? {
  var name = raw.trimmingCharacters(in: .whitespaces)
  name = name.replacingOccurrences(
    of: "['\u{2019}]s\\s+(iphone|ipad).*$",
    with: "",
    options: [.regularExpression, .caseInsensitive],
  )
  name = name.replacingOccurrences(
    of: "\\s+(iphone|ipad).*$",
    with: "",
    options: [.regularExpression, .caseInsensitive],
  )
  guard let first = name.split(separator: " ").first.map(String.init), !first.isEmpty else {
    return nil
  }
  let pattern = "^[A-Za-z][A-Za-z'\u{2019}-]{1,14}$"
  guard first.range(of: pattern, options: .regularExpression) != nil else {
    return nil
  }
  if first.count <= 3, first == first.uppercased() {
    return nil
  }
  let rejected: Set<String> = [
    "kid", "kids", "child", "test", "home",
    "mom", "dad", "mommy", "daddy", "mother", "father", "parent",
  ]
  if rejected.contains(first.lowercased()) {
    return nil
  }
  return first.prefix(1).uppercased() + first.dropFirst().lowercased()
}

func possessive(_ name: String) -> String {
  if let last = name.last, last == "s" || last == "S" {
    return "\(name)'"
  }
  return "\(name)'s"
}

private func looksSelfManaged(email: String, name: String) -> Bool {
  guard name.count >= 4 else { return false }
  let local = email.split(separator: "@").first.map(String.init) ?? email
  return local.lowercased().hasPrefix(name.lowercased())
}

private func deviceWord(_ kinds: Set<DeviceKind>, plural: Bool) -> String {
  guard kinds.count == 1, let only = kinds.first else { return "devices" }
  return plural ? only.plural : only.singular
}

private func devicePhraseMixed(_ kinds: Set<DeviceKind>) -> String {
  let order: [DeviceKind] = [.iPhone, .iPad]
  let parts = order.filter { kinds.contains($0) }.map(\.singular)
  switch parts.count {
  case 0: return "device"
  case 1: return parts[0]
  default: return "\(parts[0]) and \(parts[1])"
  }
}

private func joinNames(_ names: [String]) -> String {
  switch names.count {
  case 0: return ""
  case 1: return possessive(names[0])
  case 2: return "\(names[0]) and \(possessive(names[1]))"
  default:
    let head = names.dropLast().joined(separator: ", ")
    return "\(head), and \(possessive(names.last!))"
  }
}
