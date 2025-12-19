import Foundation

extension Int {
  var redacted: String {
    let str = String(self)
    guard str.count > 3 else { return str }
    let prefix = str.prefix(3)
    let dots = String(repeating: "•", count: str.count - 3)
    return prefix + dots
  }
}
