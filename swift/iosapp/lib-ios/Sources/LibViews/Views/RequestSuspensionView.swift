import ComposableArchitecture
import LibApp
import SwiftUI

#if os(iOS)
  import ReplayKit
#endif

struct RequestSuspensionView: View {
  @Environment(\.colorScheme) var cs

  @Bindable var store: StoreOf<RequestSuspension>
  @State private var comment: String = ""

  var trimmedComment: String? {
    let trimmed = self.comment.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  var body: some View {
    VStack(spacing: 16) {
      switch self.store.state {
      case .customizing:
        Text("Ask to pause blocking")
          .font(.system(size: 24, weight: .medium))
        Text(
          "While blocking is paused, your screen will be recorded so the person protecting you can see what you did.",
        )
        .font(.system(size: 16))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
        TextField("Comment (optional)", text: self.$comment)
          .textFieldStyle(.roundedBorder)
          .padding(.vertical, 8)
        BigButton("5 minutes", type: .button {
          self.store.send(.submitRequest(duration: 60 * 5, comment: self.trimmedComment))
        })
        BigButton("15 minutes", type: .button {
          self.store.send(.submitRequest(duration: 60 * 15, comment: self.trimmedComment))
        }, variant: .secondary)

      case .requesting:
        ProgressView()

      case .requestFailed(let error):
        Text("Request failed: \(error)")

      case .waitingForDecision:
        ProgressView()
        Text("Waiting for a decision...")

      case .requestExpired:
        Text("No decision was made, try again later.")

      case .denied(let comment):
        Text(comment.map { "Request denied: \($0)" } ?? "Request denied")

      case .granted(let duration, let comment):
        Text("Pause approved for \(duration.rawValue / 60) minutes")
          .font(.system(size: 24, weight: .medium))
        if let comment {
          Text(comment)
            .font(.system(size: 16))
        }
        Text("Blocking stays paused only while your screen is being recorded.")
          .font(.system(size: 16))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
        BigButton("Start recording & pause", type: .button {
          self.store.send(.startRecordingTapped)
          self.launchBroadcastPicker()
        })

      case .recording:
        Text("Blocking is paused while recording")
          .font(.system(size: 24, weight: .medium))
        BigButton("Resume blocking now", type: .button {
          self.store.send(.endSuspensionTapped)
        }, variant: .secondary)
      }
    }
    .multilineTextAlignment(.center)
    .padding(24)
  }

  private func launchBroadcastPicker() {
    #if os(iOS)
      let picker = RPSystemBroadcastPickerView()
      picker.preferredExtension = .gertrudeRecorderBundleIdShort
      picker.showsMicrophoneButton = false
      for subview in picker.subviews where subview is UIButton {
        (subview as? UIButton)?.sendActions(for: .touchUpInside)
      }
    #endif
  }
}
