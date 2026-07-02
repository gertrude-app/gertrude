import ComposableArchitecture
import GertieApp
import SwiftUI

public struct AppUpdateGateModifier: ViewModifier {
  @Bindable var store: StoreOf<AppUpdateGateFeature>
  @Environment(\.scenePhase) var scenePhase
  let suggestedUpdatesEnabled: Bool

  public init(
    store: StoreOf<AppUpdateGateFeature>,
    suggestedUpdatesEnabled: Bool = true,
  ) {
    self.store = store
    self.suggestedUpdatesEnabled = suggestedUpdatesEnabled
  }

  public func body(content: Content) -> some View {
    content
      .task {
        self.store.send(.viewAppeared(suggestedPresentationEnabled: self.suggestedUpdatesEnabled))
      }
      .onChange(of: self.scenePhase) { _, phase in
        guard phase == .active else { return }
        self.store.send(.appDidEnterForeground(
          suggestedPresentationEnabled: self.suggestedUpdatesEnabled,
        ))
      }
      .onChange(of: self.suggestedUpdatesEnabled) { _, enabled in
        self.store.send(.suggestedPresentationAvailabilityChanged(enabled))
      }
    #if os(iOS)
      .fullScreenCover(item: self.requiredBinding) { directive in
        AppUpdatePromptView(
          directive: directive,
          isRequired: true,
          onUpdate: { self.store.send(.updateButtonTapped(directive)) },
          onDismiss: nil,
        )
        .interactiveDismissDisabled(true)
      }
    #else
      .sheet(item: self.requiredBinding) { directive in
          AppUpdatePromptView(
            directive: directive,
            isRequired: true,
            onUpdate: { self.store.send(.updateButtonTapped(directive)) },
            onDismiss: nil,
          )
          .interactiveDismissDisabled(true)
        }
    #endif
        .sheet(item: self.suggestedBinding) { directive in
          AppUpdatePromptView(
            directive: directive,
            isRequired: false,
            onUpdate: { self.store.send(.updateButtonTapped(directive)) },
            onDismiss: { self.store.send(.suggestedDismissButtonTapped) },
          )
          #if os(iOS)
          .presentationDetents([.fraction(0.75)])
          .presentationDragIndicator(.visible)
          #endif
        }
  }

  private var requiredBinding: Binding<AppUpdateDirective?> {
    Binding(get: { self.store.required }, set: { _ in })
  }

  private var suggestedBinding: Binding<AppUpdateDirective?> {
    Binding(
      get: { self.store.required == nil ? self.store.suggested : nil },
      set: { newValue in
        if newValue == nil { self.store.send(.suggestedDismissButtonTapped) }
      },
    )
  }
}

public extension View {
  func appUpdateGate(
    store: StoreOf<AppUpdateGateFeature>,
    suggestedUpdatesEnabled: Bool = true,
  ) -> some View {
    self.modifier(AppUpdateGateModifier(
      store: store,
      suggestedUpdatesEnabled: suggestedUpdatesEnabled,
    ))
  }
}

struct AppUpdatePromptView: View {
  @Environment(\.colorScheme) var scheme
  let directive: AppUpdateDirective
  let isRequired: Bool
  let onUpdate: () -> Void
  let onDismiss: (() -> Void)?

  var body: some View {
    ZStack {
      LinearGradient(
        colors: self.scheme == .dark
          ? [.brandViolet950.opacity(0.65), .black]
          : [.brandViolet200, .white],
        startPoint: .top,
        endPoint: .bottom,
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {
        Spacer(minLength: 0)

        Image(systemName: self
          .isRequired ? "exclamationmark.triangle.fill" : "arrow.up.circle.fill")
          .font(.system(size: 46, weight: .semibold))
          .foregroundStyle(self.brand(light: .brandViolet500, dark: .brandViolet400))
          .padding(.bottom, 22)

        Text(self.directive.title)
          .font(.system(size: 26, weight: .bold))
          .foregroundStyle(self.brand(light: .brandViolet950, dark: .brandViolet100))
          .padding(.bottom, 10)

        Text(self.directive.message)
          .font(.system(size: 17, weight: .medium))
          .foregroundStyle(self.brand(light: .brandViolet950, dark: .brandViolet100).opacity(0.85))
          .fixedSize(horizontal: false, vertical: true)

        Spacer(minLength: 28)

        self.bigButton(
          title: "Update in App Store",
          foreground: .white,
          background: self.brand(light: .brandViolet500, dark: .brandViolet600.opacity(0.9)),
          action: self.onUpdate,
        )

        if let onDismiss {
          self.bigButton(
            title: "Later",
            foreground: self.brand(light: .brandViolet500, dark: .brandViolet400),
            background: self.brand(
              light: .brandViolet500.opacity(0.1),
              dark: .brandViolet500.opacity(0.16),
            ),
            action: onDismiss,
          )
          .padding(.top, 10)
        }
      }
      .frame(maxWidth: 460, alignment: .leading)
      .padding(30)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: self.isRequired ? .center : .bottom,
      )
    }
  }

  private func bigButton(
    title: String,
    foreground: Color,
    background: Color,
    action: @escaping () -> Void,
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(background)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private func brand(light: Color, dark: Color) -> Color {
    self.scheme == .dark ? dark : light
  }
}

private extension Color {
  static let brandViolet100 = Color(red: 0.929, green: 0.914, blue: 0.996) // #ede9fe
  static let brandViolet200 = Color(red: 0.867, green: 0.839, blue: 0.996) // #ddd6fe
  static let brandViolet400 = Color(red: 0.655, green: 0.545, blue: 0.980) // #a78bfa
  static let brandViolet500 = Color(red: 0.545, green: 0.361, blue: 0.965) // #8b5cf6
  static let brandViolet600 = Color(red: 0.486, green: 0.227, blue: 0.929) // #7c3aed
  static let brandViolet950 = Color(red: 0.180, green: 0.063, blue: 0.396) // #2e1065
}

#if DEBUG
  private extension AppUpdateDirective {
    static let previewRequired = Self(
      policyId: "preview-required",
      latestVersion: "2.4.0",
      minimumVersion: "2.3.0",
      title: "Update Required",
      message: "This version of Gertrude is no longer supported. Please update to keep protection active.",
      appStoreUrl: "https://apps.apple.com/app/id1234567890",
    )

    static let previewSuggested = Self(
      policyId: "preview-suggested",
      latestVersion: "2.4.0",
      requiredOn: .now.addingTimeInterval(60 * 60 * 24 * 7),
      title: "Update Available",
      message: "A newer version of Gertrude is available and will be required soon.",
      appStoreUrl: "https://apps.apple.com/app/id1234567890",
    )
  }

  private struct AppUpdatePreviewContent: View {
    var body: some View {
      NavigationStack {
        List {
          Section {
            Label("Filtering is active", systemImage: "shield.checkered")
            Label("Rules updated 12 minutes ago", systemImage: "arrow.triangle.2.circlepath")
            Label("No recent alerts", systemImage: "checkmark.circle")
          }
          Section {
            Label("7 blocked requests today", systemImage: "hand.raised")
            Label("Setup complete", systemImage: "checkmark.seal")
          }
        }
        .navigationTitle("Gertrude")
      }
    }
  }

  private struct SuggestedSheetPreview: View {
    @State private var presented = true

    var body: some View {
      AppUpdatePreviewContent()
        .sheet(isPresented: self.$presented) {
          AppUpdatePromptView(
            directive: .previewSuggested,
            isRequired: false,
            onUpdate: {},
            onDismiss: { self.presented = false },
          )
          #if os(iOS)
          .presentationDetents([.fraction(0.75)])
          .presentationDragIndicator(.visible)
          #endif
        }
    }
  }

  #Preview("Required (full screen)") {
    AppUpdatePromptView(
      directive: .previewRequired,
      isRequired: true,
      onUpdate: {},
      onDismiss: nil,
    )
  }

  #Preview("Suggested (75% sheet)") {
    SuggestedSheetPreview()
  }
#endif
