import Foundation

/// The desired ManagedSettings shield state as a pure projection of the
/// recording-suspension registers (docs/ios-shields-protocol.md, D8):
/// `shieldsDerived(now) = live(now) ? down : up` for non-allowlisted apps.
/// Shields are the protocol's first inverted-fail-safe actuator — the dropped
/// state survives process death and reboot (OS RULE R14) — so shield state
/// must always be a level-triggered reconciled projection of the registers,
/// never an edge. Both authorized writers (app, controller) compute exactly
/// this projection from the same registers; writes reconcile toward it.
public enum ShieldsProjection: Equatable, Sendable {
  case up(allowlist: Data)
  case down

  public static func derive(
    expiration: Date?,
    lastScreenshot: Date?,
    now: Date,
    allowlist: Data,
  ) -> ShieldsProjection {
    RecordingSuspension.rederived(
      expiration: expiration,
      lastScreenshot: lastScreenshot,
      now: now,
    ) != nil ? .down : .up(allowlist: allowlist)
  }
}

public extension RecordingSuspension {
  /// Grant-consumption policy (protocol doc §Open, shields doc
  /// §restart-within-grant — UNDECIDED, both modeled so the sim/explorer can
  /// demonstrate the difference): `.burnOnFinish` is the shipped behavior — a
  /// finished broadcast consumes the grant (app clears the expiration
  /// register); `.restartWithinGrant` leaves a still-future expiration in
  /// place so the kid can restart the recording (e.g. after a device lock
  /// cleanly finishes the broadcast) within the originally granted window.
  enum GrantPolicy: String, Equatable, Sendable {
    case burnOnFinish
    case restartWithinGrant
  }
}
