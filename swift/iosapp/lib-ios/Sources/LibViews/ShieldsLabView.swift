#if DEBUG && os(iOS)

  import Dependencies
  import FamilyControls
  import LibClients
  import LibCore
  import SwiftUI

  /// Debug-only harness for the shields conformance spike
  /// (`conformance/shields-spike.md`): verifies Screen Time authorization
  /// state, captures victim-app tokens via the system picker, round-trips the
  /// selection through group defaults, and drives shield writes from BOTH
  /// process contexts — directly (app) and via sentinel → filter → controller,
  /// which is the write path production will rely on. Every operation emits a
  /// witness so `capture.sh collect` + `check.mjs --shields` can reconstruct
  /// the session.
  public struct ShieldsLabView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var pickerPresented = false
    @State private var authStatus = "unknown"
    @State private var log: [String] = []

    @Dependency(\.managedSettings) var managedSettings
    @Dependency(\.groupDefaults) var groupDefaults

    public init() {}

    public var body: some View {
      NavigationStack {
        List {
          Section("screen time authorization") {
            Text("status: \(self.authStatus)")
            Button("Refresh status") { self.refreshAuthStatus() }
            Button("Request .individual authorization") {
              Task {
                do {
                  try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                  self.note("authorization granted")
                } catch {
                  self.note("authorization failed: \(error)")
                }
                self.refreshAuthStatus()
              }
            }
          }

          Section("victim selection") {
            Button(
              "Pick apps/domains (\(self.selection.applicationTokens.count) apps, \(self.selection.webDomainTokens.count) domains)",
            ) {
              self.pickerPresented = true
            }
            Button("Save selection to group defaults") { self.saveSelection() }
          }

          Section("app-written shields") {
            Button("Shield selected apps") { self.appWrite("apps", self.managedSettings.shieldApps)
            }
            Button("Shield ALL except selected") {
              self.appWrite("all-except", self.managedSettings.shieldAllExcept)
            }
            Button("Shield selected web domains") {
              self.appWrite("web", self.managedSettings.shieldWebDomains)
            }
            Button("Clear shields", role: .destructive) {
              self.managedSettings.clearShields()
              Witness.appShieldWrite
                .emit("down cleared state=[\(self.managedSettings.shieldsDescription())]")
              self.note("app cleared shields")
            }
          }

          Section("controller-written shields (sentinel → filter → controller)") {
            Button("shields-up (selected apps)") {
              self.fire(MagicStrings.shieldsUpSentinalHostname)
            }
            Button("shields-all (all except selected)") {
              self.fire(MagicStrings.shieldsAllSentinalHostname)
            }
            Button("shields-web (selected domains)") {
              self.fire(MagicStrings.shieldsWebSentinalHostname)
            }
            Button("shields-down (clear)", role: .destructive) {
              self.fire(MagicStrings.shieldsDownSentinalHostname)
            }
          }

          Section("current store state (this process)") {
            Text(self.managedSettings.shieldsDescription())
          }

          Section("session log") {
            ForEach(Array(self.log.enumerated().reversed()), id: \.offset) { _, line in
              Text(line).font(.caption.monospaced())
            }
          }
        }
        .navigationTitle("Shields Lab")
        .familyActivityPicker(isPresented: self.$pickerPresented, selection: self.$selection)
        .onAppear {
          self.refreshAuthStatus()
          self.loadSelection()
        }
      }
    }

    private func refreshAuthStatus() {
      let status = switch AuthorizationCenter.shared.authorizationStatus {
      case .notDetermined: "notDetermined"
      case .denied: "denied"
      case .approved: "approved"
      @unknown default: "unknown(\(AuthorizationCenter.shared.authorizationStatus))"
      }
      self.authStatus = status
      Witness.shieldsLabAuthorization.emit(status)
      self.note("auth status: \(status)")
    }

    private func saveSelection() {
      guard let data = try? JSONEncoder().encode(self.selection) else {
        self.note("ERR selection encode failed")
        return
      }
      self.groupDefaults.setData(data: data, forKey: MagicStrings.shieldsLabSelectionKey)
      let detail =
        "apps=\(self.selection.applicationTokens.count) categories=\(self.selection.categoryTokens.count) domains=\(self.selection.webDomainTokens.count) bytes=\(data.count)"
      Witness.shieldSelectionSaved.emit(detail)
      self.note("saved selection: \(detail)")
    }

    private func loadSelection() {
      guard let data = self.groupDefaults.data(forKey: MagicStrings.shieldsLabSelectionKey),
            let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
        self.note("no saved selection")
        return
      }
      self.selection = saved
      self.note("loaded saved selection (\(saved.applicationTokens.count) apps)")
    }

    private func appWrite(_ kind: String, _ write: (Data) -> String) {
      guard let data = try? JSONEncoder().encode(self.selection) else {
        self.note("ERR selection encode failed")
        return
      }
      let started = Date()
      let outcome = write(data)
      let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
      let detail =
        "\(kind) \(outcome) ms=\(elapsedMs) state=[\(self.managedSettings.shieldsDescription())]"
      Witness.appShieldWrite.emit(detail)
      self.note("app write: \(detail)")
    }

    private func fire(_ hostname: String) {
      self.note("firing sentinel \(hostname)")
      Task {
        var request = URLRequest(url: URL(string: "https://\(hostname)")!)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        _ = try? await URLSession.shared.data(for: request)
      }
    }

    private func note(_ line: String) {
      self.log.append(line)
    }
  }

  public extension View {
    func shieldsLabOverlay() -> some View {
      modifier(ShieldsLabOverlay())
    }
  }

  private struct ShieldsLabOverlay: ViewModifier {
    @State private var presented = false

    func body(content: Content) -> some View {
      content
        .overlay(alignment: .bottomTrailing) {
          Button("🛡️") { self.presented = true }
            .font(.title2)
            .padding(12)
            .opacity(0.5)
        }
        .sheet(isPresented: self.$presented) {
          ShieldsLabView()
        }
    }
  }

#endif
