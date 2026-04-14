import Foundation
import PairQL

public struct SelectPublicKeychains: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = [UUID]
}
