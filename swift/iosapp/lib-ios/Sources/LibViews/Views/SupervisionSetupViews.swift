import SwiftUI

// TODO: superios finalize screen text

struct InstructionsForProtectorView: View {
  @Environment(\.colorScheme) var cs

  let code: Int
  let onNext: () -> Void

  @State private var showBg = false

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "link.circle")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        Text(
          "Share this link with your protector. They'll need to open it on a computer to complete the setup.",
        )
        .font(.system(size: 18, weight: .medium))

        Text(self.supervisionUrl)
          .font(.system(size: 20, weight: .semibold, design: .monospaced))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)

        Spacer()
          .frame(height: 40)

        BigButton(
          "Send link to protector",
          type: .share(self.supervisionUrl),
          variant: .secondary,
          icon: "square.and.arrow.up",
        )

        BigButton("Next", type: .button { self.onNext() }, variant: .primary)
          .padding(.top, 8)
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }
}

struct WaitingForSupervisionView: View {
  @Environment(\.colorScheme) var cs

  let code: Int

  @State private var showBg = false

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var supervisionUrl: String {
    "https://gertrude.app/s/\(self.codeString)"
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          Gradient(colors: [
            Color(self.cs, light: .violet200, dark: .violet950.opacity(0.7)),
            .clear,
          ]),
        )
        .ignoresSafeArea()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation(.smooth(duration: 0.7)) {
            self.showBg = true
          }
        }

      VStack(alignment: .leading, spacing: 16) {
        Image(systemName: "hourglass")
          .font(.system(size: 40, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .violet500, dark: .violet400))
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer()

        // TODO: superios finalize screen text
        Text(
          "Now close this app and wait for your protector to complete the supervision process on their computer.",
        )
        .font(.system(size: 18, weight: .medium))

        // TODO: superios finalize screen text
        Text(
          "Once they're done, your device will restart. After it restarts, open this app again to finish setup.",
        )
        .font(.system(size: 18, weight: .medium))

        Spacer()
          .frame(height: 40)

        BigButton(
          "Send link again",
          type: .share(self.supervisionUrl),
          variant: .secondary,
          icon: "square.and.arrow.up",
        )
      }
      .frame(maxWidth: 500)
      .padding(30)
      .padding(.top, 50)
    }
  }
}

#Preview("InstructionsForProtector") {
  InstructionsForProtectorView(code: 123_456, onNext: {})
}

#Preview("WaitingForSupervision") {
  WaitingForSupervisionView(code: 123_456)
}
