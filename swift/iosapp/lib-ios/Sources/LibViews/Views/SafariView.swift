import GertieUI
import SwiftUI

#if os(iOS)
  import SafariServices

  struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
      let config = SFSafariViewController.Configuration()
      config.entersReaderIfAvailable = false
      config.barCollapsingEnabled = false

      let safari = SFSafariViewController(url: self.url, configuration: config)
      safari.delegate = context.coordinator
      safari.dismissButtonStyle = .done
      return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
      Coordinator(onDismiss: self.onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
      let onDismiss: () -> Void

      init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
      }

      func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.onDismiss()
      }
    }
  }
#else
  struct SafariView: View {
    let url: URL
    let onDismiss: () -> Void

    var body: some View {
      VStack(spacing: 20) {
        Text("Safari View (iOS only)")
          .font(.headline)
        Text(self.url.absoluteString)
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Dismiss") {
          self.onDismiss()
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.gray.opacity(0.1))
    }
  }
#endif

struct ProfileDownloadView: View {
  @Environment(\.colorScheme) var cs

  let profileUrl: URL
  let osMajorVersion: Int
  let onSafariDismissed: () -> Void

  @State private var showSafari = false

  var body: some View {
    VStack(spacing: 12) {
      Spacer().frame(height: 0)

      VStack(alignment: .leading, spacing: 12) {
        Text("1. Choose “Allow”")
        Text("2. Tap “Close”")
        Text(self.osMajorVersion >= 26 ? "3. Tap the “✓”" : "3. Tap “Done”")
      }
      .font(.system(size: 20, weight: .semibold))
      .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet300))

      Spacer()
    }
    .frame(maxWidth: 500)
    .padding(30)
    .gertieScreenBackground()
    .delayedTask(for: .milliseconds(300)) {
      self.showSafari = true
    }
    .sheet(isPresented: self.$showSafari, onDismiss: self.onSafariDismissed) {
      SafariView(url: self.profileUrl, onDismiss: {})
        .ignoresSafeArea()
        .presentationDetents([.fraction(0.65)])
    }
  }
}

#Preview("ProfileDownloadView (< iOS 26)") {
  ProfileDownloadView(
    profileUrl: URL(string: "https://gertrude-dev.nyc3.digitaloceanspaces.com/super.mobileconfig")!,
    osMajorVersion: 18,
    onSafariDismissed: {},
  )
}

#Preview("ProfileDownloadView (iOS 26+)") {
  ProfileDownloadView(
    profileUrl: URL(string: "https://gertrude-dev.nyc3.digitaloceanspaces.com/super.mobileconfig")!,
    osMajorVersion: 26,
    onSafariDismissed: {},
  )
}
