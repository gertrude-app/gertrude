import SwiftUI

#if os(iOS)
  public extension View {
    func nowPlayingPresentation(
      isPresented: Binding<Bool>,
      @ViewBuilder background: @escaping () -> some View,
      @ViewBuilder content: @escaping () -> some View,
    ) -> some View {
      self.fullScreenCover(isPresented: isPresented) {
        NowPlayingPresentationContent(
          isPresented: isPresented,
          content: content(),
        )
        .presentationBackground {
          background()
        }
      }
    }
  }

  private struct NowPlayingPresentationContent<Content: View>: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    let content: Content

    var body: some View {
      self.content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .offset(y: self.dragOffset)
        .simultaneousGesture(self.dismissGesture)
        .accessibilityAction(.escape) {
          self.isPresented = false
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
            self.isPresented = false
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
