import Gertie
import PairQL

extension PlainTimeWindow: @retroactive PairInput {}

public struct SetDowntimeSchedule: Pair {
  public static let auth: ClientAuth = .child
  public typealias Input = PlainTimeWindow
}
