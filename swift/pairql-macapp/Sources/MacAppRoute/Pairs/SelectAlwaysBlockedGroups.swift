import Foundation
import PairQL

public struct SelectAlwaysBlockedGroups: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = [UUID]
}
