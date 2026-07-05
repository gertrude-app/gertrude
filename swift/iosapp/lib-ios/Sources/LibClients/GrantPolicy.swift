import Dependencies
import LibCore

private enum GrantPolicyKey: DependencyKey {
  static let liveValue = RecordingSuspension.GrantPolicy.burnOnFinish
  static let testValue = RecordingSuspension.GrantPolicy.burnOnFinish
}

public extension DependencyValues {
  var grantPolicy: RecordingSuspension.GrantPolicy {
    get { self[GrantPolicyKey.self] }
    set { self[GrantPolicyKey.self] = newValue }
  }
}
