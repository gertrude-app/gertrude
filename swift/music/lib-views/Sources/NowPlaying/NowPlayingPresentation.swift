import SwiftUI

#if os(iOS)
  private let nowPlayingZoomSourceID = "now-playing"

  public extension View {
    func nowPlayingPresentation(
      isPresented: Binding<Bool>,
      zoomNamespace: Namespace.ID? = nil,
      @ViewBuilder background: @escaping () -> some View,
      @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
      self.fullScreenCover(isPresented: isPresented) {
        content()
          .presentationBackground {
            background()
          }
          .nowPlayingZoomTransition(in: zoomNamespace)
      }
    }

    @ViewBuilder
    func nowPlayingZoomSource(in namespace: Namespace.ID) -> some View {
      if #available(iOS 26.0, *) {
        self.matchedTransitionSource(id: nowPlayingZoomSourceID, in: namespace)
      } else {
        self
      }
    }
  }

  private extension View {
    @ViewBuilder
    func nowPlayingZoomTransition(in namespace: Namespace.ID?) -> some View {
      if #available(iOS 26.0, *), let namespace {
        self
          .navigationTransition(.zoom(sourceID: nowPlayingZoomSourceID, in: namespace))
          .environment(\.nowPlayingUsesSystemDismiss, true)
      } else {
        self
      }
    }
  }

  private extension EnvironmentValues {
    @Entry var nowPlayingUsesSystemDismiss = false
  }

  struct NowPlayingDismissGesture: ViewModifier {
    @Environment(\.nowPlayingUsesSystemDismiss) private var usesSystemDismiss
    @Binding var dragOffset: CGFloat
    let onDismiss: @MainActor @Sendable () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
      if self.usesSystemDismiss {
        content
      } else {
        content
          .contentShape(Rectangle())
          .simultaneousGesture(self.dismissGesture)
      }
    }

    private var dismissGesture: some Gesture {
      DragGesture(minimumDistance: 8)
        .onChanged { value in
          guard value.translation.height > 0,
                abs(value.translation.height) > abs(value.translation.width) else { return }
          self.dragOffset = value.translation.height * 0.3
        }
        .onEnded { value in
          guard value.translation.height > 0,
                abs(value.translation.height) > abs(value.translation.width) else {
            self.resetDrag()
            return
          }
          if value.translation.height > 90 || value.predictedEndTranslation.height > 180 {
            self.onDismiss()
          } else {
            self.resetDrag()
          }
        }
    }

    private func resetDrag() {
      withAnimation(.snappy(duration: 0.24)) {
        self.dragOffset = 0
      }
    }
  }
#endif
