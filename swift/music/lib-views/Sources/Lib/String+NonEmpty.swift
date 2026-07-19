import Foundation

extension String {
  var nonEmpty: String? {
    self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }

  var isValidPlaylistName: Bool {
    let name = self.trimmingCharacters(in: .whitespacesAndNewlines)
    return !name.isEmpty
      && name.count <= 100
      && name.rangeOfCharacter(from: .newlines) == nil
  }
}
