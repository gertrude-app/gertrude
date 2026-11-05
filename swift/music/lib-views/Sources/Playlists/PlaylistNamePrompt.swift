import GertieUI
import SwiftUI

struct PlaylistNamePrompt: View {
  @Binding private var name: String
  @Environment(\.layoutDirection) private var layoutDirection
  @FocusState private var isNameFocused: Bool
  @State private var contentHeight: CGFloat = 260

  private let title: String
  private let message: String
  private let actionTitle: String
  private let onCancel: @MainActor @Sendable () -> Void
  private let onSubmit: @MainActor @Sendable () -> Void

  init(
    title: String,
    message: String,
    actionTitle: String,
    name: Binding<String>,
    onCancel: @MainActor @escaping @Sendable () -> Void,
    onSubmit: @MainActor @escaping @Sendable () -> Void,
  ) {
    self.title = title
    self.message = message
    self.actionTitle = actionTitle
    self._name = name
    self.onCancel = onCancel
    self.onSubmit = onSubmit
  }

  var body: some View {
    #if os(iOS)
      ScrollView {
        self.promptContent
          .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
            self.contentHeight = $0
          }
      }
      .scrollBounceBehavior(.basedOnSize)
      .ignoresSafeArea(.container, edges: self.physicalRightEdge)
      .frame(idealWidth: 420)
      .presentationDetents([.height(self.contentHeight)])
      .presentationDragIndicator(.visible)
      .presentationBackground(.background)
      .modifier(FittedPresentationSizing())
    #else
      self.promptContent
        .frame(minWidth: 380)
    #endif
  }

  private var promptContent: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text(self.title)
          .font(.title2.bold())
          .accessibilityAddTraits(.isHeader)
        Text(self.message)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      TextField("Playlist Name", text: self.$name)
        .font(.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.fill.tertiary)
        }
        .focused(self.$isNameFocused)
        .submitLabel(.done)
        .onSubmit(self.submitButtonTapped)

      HStack(spacing: 12) {
        Button("Cancel", action: self.onCancel)
          .buttonStyle(.gertieSecondary)
          .keyboardShortcut(.cancelAction)

        Button(self.actionTitle, action: self.submitButtonTapped)
          .buttonStyle(.gertiePrimary)
          .disabled(!self.name.isValidPlaylistName)
      }
    }
    .padding(24)
    .onAppear { self.isNameFocused = true }
  }

  private var physicalRightEdge: Edge.Set {
    self.layoutDirection == .rightToLeft ? .leading : .trailing
  }

  private func submitButtonTapped() {
    guard self.name.isValidPlaylistName else { return }
    self.onSubmit()
  }
}

private struct FittedPresentationSizing: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 18.0, macOS 15.0, *) {
      content.presentationSizing(.fitted)
    } else {
      content
    }
  }
}

#if DEBUG
  #Preview("Playlist name prompt") {
    @Previewable @State var name = "Road Trip"
    Color.clear
      .sheet(isPresented: .constant(true)) {
        PlaylistNamePrompt(
          title: "Rename Playlist",
          message: "Enter a new name for this playlist.",
          actionTitle: "Save",
          name: $name,
          onCancel: {},
          onSubmit: {},
        )
      }
  }
#endif
