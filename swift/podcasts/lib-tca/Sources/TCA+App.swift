import ComposableArchitecture
import CustomDump

extension _ReducerPrinter<AppReducer.State, AppReducer.Action> {
  static var custom: Self {
    Self { action, oldState, newState in
      var target = ""
      switch action {
      case .nowPlaying(.system(.progressUpdated(let position))):
        let shortPos = (position * 10000).rounded() / 10000
        target.write("received action: .nowPlaying(.system(.progressUpdated(\(shortPos))))")
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
