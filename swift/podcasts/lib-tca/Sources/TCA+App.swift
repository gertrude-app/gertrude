import ComposableArchitecture
import CustomDump
import Dependencies

extension _ReducerPrinter<AppReducer.State, AppReducer.Action> {
  static var custom: Self {
    Self { action, oldState, newState in
      var target = ""
      switch action {
      case .nowPlaying(.system):
        target.write("received action: .\(simplifyAction("\(action)"))")
        target.write(diff(oldState, newState).map { "\($0)\n" } ?? " (no change)")
      default:
        target.write("received action:\n")
        CustomDump.customDump(action, to: &target, indent: 2)
        target.write("\n")
        target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
      }
      print(target)
    }
  }
}

extension Episode: CustomDumpStringConvertible {
  var customDumpDescription: String {
    "Episode(\(self.id), title: \"\(self.title.prefix(35))\", ...)"
  }
}

extension Show: CustomDumpStringConvertible {
  var customDumpDescription: String {
    "Show(\(self.id), name: \"\(self.name.prefix(35))\", ...)"
  }
}

func simplifyAction(_ input: String) -> String {
  let pattern = #"([().])"#
  let parts = input
    .replacingOccurrences(of: pattern, with: " $1 ", options: .regularExpression)
    .split(separator: " ")
    .map(String.init)

  var result: [String] = []
  for part in parts {
    if ["(", ")", "."].contains(part) {
      result.append(part)
    } else if let first = part.first, !first.isUppercase {
      result.append(part)
    }
  }

  var joined = result.joined()
  while joined.contains("..") {
    joined = joined.replacingOccurrences(of: "..", with: ".")
  }
  return joined
}

func dep<Value>(_ keyPath: KeyPath<DependencyValues, Value> & Sendable) -> Value {
  @Dependency(keyPath) var value
  return value
}

#if DEBUG
  import Darwin

  func eprint(_ items: Any...) {
    let s = items.map { "\($0)" }.joined(separator: " ")
    fputs(s + "\n", stderr)
    fflush(stderr)
  }
#endif
