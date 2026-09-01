import Foundation

extension String {
  var isValidEmail: Bool {
    let parts = split(separator: "@")
    return parts.count == 2 && parts[0].count > 0 && parts[1].count > 3 && parts[1].contains(".")
  }

  var withEmailSubjectDisambiguator: String {
    let ref = UUID().lowercased.split(separator: "-").first!
    return "\(self) [ref:\(ref.prefix(5))]"
  }

  var singular: String {
    regexReplace("ies$", "y").regexReplace("s$", "")
  }

  var withoutTrailingSlashes: String {
    var copy = self
    while copy.hasSuffix("/") {
      copy.removeLast()
    }
    return copy
  }

  var normalizedBundleId: String {
    var id = self
    if id.first == "." {
      id = String(id.dropFirst())
    }
    // strip a leading 10-char Apple team-id prefix, e.g. "9QW8UQUTAA."
    let parts = id.split(separator: ".", maxSplits: 1)
    if parts.count == 2,
       parts[0].count == 10,
       parts[0].allSatisfy({ $0.isNumber || ($0.isLetter && $0.isUppercase) }) {
      id = String(parts[1])
    }
    return id
  }
}
