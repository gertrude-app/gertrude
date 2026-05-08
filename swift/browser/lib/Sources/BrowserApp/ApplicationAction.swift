import Foundation

// public, not nested, because it's used in the AppDelegate
// (and to insulate the Xcode shell from any TCA / reducer types)
public enum ApplicationAction: Equatable, Sendable {
  case didFinishLaunching
}
