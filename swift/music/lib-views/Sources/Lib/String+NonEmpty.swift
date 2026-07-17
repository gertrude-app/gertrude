import Foundation

extension String {
  var nonEmpty: String? {
    self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }
}
