import SwiftUI

#if os(iOS)
  public extension View {
    func nowPlayingPresentation(
      isPresented: Binding<Bool>,
      @ViewBuilder background: @escaping () -> some View,
      @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
      self.fullScreenCover(isPresented: isPresented) {
        content()
          .presentationBackground {
            background()
          }
      }
    }
  }

  struct NowPlayingDismissGesture: ViewModifier {
    @Binding var dragOffset: CGFloat
    let onDismiss: @MainActor @Sendable () -> Void

    func body(content: Content) -> some View {
      content
        .contentShape(Rectangle())
        .simultaneousGesture(self.dismissGesture)
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
