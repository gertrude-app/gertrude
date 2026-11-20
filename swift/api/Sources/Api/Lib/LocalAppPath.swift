import Foundation

func isLocalAppPath(_ path: String) -> Bool {
  guard
    path.hasPrefix("/"),
    !path.hasPrefix("//"),
    !path.contains("\\"),
    !path.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }),
    path.rangeOfCharacter(from: .controlCharacters) == nil,
    let components = URLComponents(string: path),
    components.scheme == nil,
    components.host == nil
  else { return false }
  return true
}
