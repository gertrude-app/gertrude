import Foundation
import os.log

/// Emits grep-able `[G•] WITNESS <event> <detail>` lines marking the process
/// lifecycle and cross-process handoff points that the `LibSim` OS model makes
/// claims about; the tooling in `iosapp/conformance/` captures these from a real
/// device and checks the model against them (see `docs/ios-conformance.md`).
/// Lines log at default os_log level because lower levels are not persisted to
/// the device log archive. Compiles to a no-op outside DEBUG builds.
public enum Witness: String, Sendable {
  case filterProxyInit = "filter-proxy-init"
  case filterStart = "filter-start"
  case filterStop = "filter-stop"
  case filterNeedRules = "filter-need-rules"
  case filterRulesChanged = "filter-rules-changed"
  case filterSentinel = "filter-sentinel"
  case controllerProxyInit = "controller-proxy-init"
  case controllerStart = "controller-start"
  case controllerStop = "controller-stop"
  case controllerReceivedFlow = "controller-received-flow"
  case controllerVerdict = "controller-verdict"
  case controllerNotifiedRulesChanged = "controller-notified-rules-changed"
  case controllerMigrated = "controller-migrated"
  case appAuthorized = "app-authorized"
  case appInstalledFilter = "app-installed-filter"
  case appMigrated = "app-migrated"
  case appSentinelSent = "app-sentinel-sent"
  case filterSuspended = "filter-suspended"
  case filterResumed = "filter-resumed"
  case recorderStart = "recorder-start"
  case recorderStop = "recorder-stop"
  case recorderScreenshotSaved = "recorder-screenshot-saved"
  case screenshotsDrained = "screenshots-drained"
  case appReceivedRecorderEvent = "app-received-recorder-event"

  @inline(__always)
  public func emit(_ detail: @autoclosure () -> String = "") {
    #if DEBUG
      os_log("[G•] WITNESS %{public}s %{public}s", self.rawValue, detail())
    #endif
  }
}
