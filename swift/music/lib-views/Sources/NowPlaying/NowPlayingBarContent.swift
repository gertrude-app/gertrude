import Foundation
import SwiftUI

#if os(iOS)
  enum NowPlayingBarLayout {
    case expanded
    case inline
  }

  struct NowPlayingBarContent: View {
    let layout: NowPlayingBarLayout
    let item: NowPlayingBarItem
    let nextItem: NowPlayingBarItem?
    let isPlaying: Bool
    var isLoading = false
    let isEnabled: Bool
    let foregroundColor: Color
    let onTap: @MainActor @Sendable () -> Void
    let onPlayTap: @MainActor @Sendable () -> Void
    let onNextTap: @MainActor @Sendable () -> Void

    var body: some View {
      switch self.layout {
      case .expanded:
        self.expanded
      case .inline:
        self.inline
      }
    }

    private var expanded: some View {
      HStack(spacing: 12) {
        NowPlayingBarTrackCarousel(
          item: self.item,
          nextItem: self.nextItem,
          artworkSize: 32,
          artworkCornerRadius: 4,
          spacing: 10,
          isEnabled: self.isEnabled,
          foregroundColor: self.foregroundColor,
          onTap: self.onTap,
          onNext: self.onNextTap,
        )
        .frame(minWidth: 0, maxWidth: .infinity)

        HStack(spacing: 2) {
          NowPlayingIconButton(
            systemName: self.isPlaying ? "pause.fill" : "play.fill",
            size: 18,
            foregroundColor: self.foregroundColor,
            isLoading: self.isLoading,
            isEnabled: self.isEnabled && !self.isLoading,
            accessibilityLabel: self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play",
            action: self.onPlayTap,
          )
          NowPlayingIconButton(
            systemName: "forward.fill",
            size: 17,
            foregroundColor: self.foregroundColor,
            isEnabled: self.isEnabled,
            accessibilityLabel: "Next",
            action: self.onNextTap,
          )
        }
      }
      .padding(.leading, 15)
      .padding(.trailing, 9)
      .frame(height: 46)
    }

    private var inline: some View {
      HStack(spacing: 11) {
        NowPlayingBarTrackCarousel(
          item: self.item,
          nextItem: self.nextItem,
          artworkSize: 30,
          artworkCornerRadius: 7,
          spacing: 9,
          isEnabled: self.isEnabled,
          foregroundColor: self.foregroundColor,
          onTap: self.onTap,
          onNext: self.onNextTap,
        )
        .frame(minWidth: 0, maxWidth: .infinity)

        NowPlayingIconButton(
          systemName: self.isPlaying ? "pause.fill" : "play.fill",
          size: 17,
          foregroundColor: self.foregroundColor,
          isLoading: self.isLoading,
          isEnabled: self.isEnabled && !self.isLoading,
          accessibilityLabel: self.isLoading ? "Loading" : self.isPlaying ? "Pause" : "Play",
          action: self.onPlayTap,
        )
      }
      .padding(.leading, 14)
      .padding(.trailing, 5)
      .frame(height: 44)
    }
  }

  private struct NowPlayingBarTrackCarousel: View {
    private struct Transition {
      enum Phase {
        case sliding
        case awaitingPlayback
        case playbackAdvanced
      }

      let id = UUID()
      let item: NowPlayingBarItem
      let nextItem: NowPlayingBarItem
      var phase = Phase.sliding
    }

    let item: NowPlayingBarItem
    let nextItem: NowPlayingBarItem?
    let artworkSize: CGFloat
    let artworkCornerRadius: CGFloat
    let spacing: CGFloat
    let isEnabled: Bool
    let foregroundColor: Color
    let onTap: @MainActor @Sendable () -> Void
    let onNext: @MainActor @Sendable () -> Void

    @GestureState private var gestureIsActive = false
    @State private var position: CGFloat = 0
    @State private var transition: Transition?
    @State private var dragID: UUID?
    @State private var maximumDragDistance: CGFloat = 0

    var body: some View {
      GeometryReader { geometry in
        let width = max(geometry.size.width, 1)
        let offset = width * self.position
        let item = self.transition?.item ?? self.item
        let nextItem = self.transition?.nextItem ?? self.nextItem
        let pageProgress = min(abs(self.position), 1)
        let edgeFade = min(
          Double(pageProgress) * 100,
          Double(1 - pageProgress) * 100,
          1,
        )

        ZStack(alignment: .leading) {
          NowPlayingBarTrackIdentity(
            item: item,
            artworkSize: self.artworkSize,
            artworkCornerRadius: self.artworkCornerRadius,
            spacing: self.spacing,
            foregroundColor: self.foregroundColor,
          )
          .frame(width: width, alignment: .leading)
          .offset(x: offset)

          if let nextItem {
            NowPlayingBarTrackIdentity(
              item: nextItem,
              artworkSize: self.artworkSize,
              artworkCornerRadius: self.artworkCornerRadius,
              spacing: self.spacing,
              foregroundColor: self.foregroundColor,
            )
            .frame(width: width, alignment: .leading)
            .offset(x: width + offset)
          }
        }
        .frame(width: width, height: self.artworkSize, alignment: .leading)
        .mask {
          HStack(spacing: 0) {
            LinearGradient(
              colors: [.black.opacity(1 - edgeFade), .black],
              startPoint: .leading,
              endPoint: .trailing,
            )
            .frame(width: 28)

            Rectangle()

            LinearGradient(
              colors: [.black, .black.opacity(1 - edgeFade)],
              startPoint: .leading,
              endPoint: .trailing,
            )
            .frame(width: 28)
          }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(self.interactionGesture(width: width))
      }
      .frame(height: self.artworkSize)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(self.item.title), \(self.item.artist)")
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        guard self.isEnabled else { return }
        self.onTap()
      }
      .onChange(of: self.gestureIsActive) { _, isActive in
        self.gestureActivityChanged(isActive)
      }
      .onChange(of: self.item.id) { _, _ in
        self.currentItemChanged(to: self.item.playbackID)
      }
      .task(id: self.transition?.id) {
        guard let transitionID = self.transition?.id else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled,
              self.transition?.id == transitionID else { return }
        self.cancelCommittedTransition(transitionID)
      }
    }

    private func interactionGesture(width: CGFloat) -> some Gesture {
      DragGesture(minimumDistance: 0)
        .updating(self.$gestureIsActive) { _, isActive, _ in
          isActive = true
        }
        .onChanged { value in
          guard self.isEnabled, self.transition == nil else { return }
          if self.dragID == nil {
            self.dragID = UUID()
            self.maximumDragDistance = 0
          }
          let translation = value.translation
          self.maximumDragDistance = max(
            self.maximumDragDistance,
            hypot(translation.width, translation.height),
          )
          var transaction = Transaction()
          transaction.disablesAnimations = true
          withTransaction(transaction) {
            if abs(translation.width) > abs(translation.height) {
              self.position = self.constrainedPosition(
                translation.width,
                width: width,
              )
            } else {
              self.position = 0
            }
          }
        }
        .onEnded { value in
          guard self.isEnabled, self.transition == nil else {
            self.resetDrag()
            return
          }
          let wasDrag = self.maximumDragDistance >= 7
          self.resetDrag()
          guard wasDrag else {
            self.resetPosition()
            self.onTap()
            return
          }
          guard abs(value.translation.width) > abs(value.translation.height),
                let nextItem = self.nextItem else {
            self.settleBack()
            return
          }
          let translation = value.translation.width
          let predictedTranslation = value.predictedEndTranslation.width
          let shouldAdvance = translation < -12
            && (translation < -width * 0.28 || predictedTranslation < -width * 0.55)
          guard shouldAdvance else {
            self.settleBack()
            return
          }
          self.commitTransition(
            Transition(item: self.item, nextItem: nextItem),
            from: self.constrainedPosition(translation, width: width),
          )
        }
    }

    private func constrainedPosition(_ translation: CGFloat, width: CGFloat) -> CGFloat {
      let position = translation / width
      if position < 0, self.nextItem != nil {
        let resistanceStart: CGFloat = -0.9
        guard position < resistanceStart else { return position }
        return max(
          resistanceStart + (position - resistanceStart) * 0.08,
          -0.96,
        )
      }
      return position * 0.12
    }

    private func gestureActivityChanged(_ isActive: Bool) {
      guard !isActive, let dragID = self.dragID else { return }
      Task { @MainActor in
        await Task.yield()
        guard self.dragID == dragID, self.transition == nil else { return }
        self.resetDrag()
        self.settleBack()
      }
    }

    private func resetDrag() {
      self.dragID = nil
      self.maximumDragDistance = 0
    }

    private func resetPosition() {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        self.position = 0
      }
    }

    private func settleBack() {
      withAnimation(.easeOut(duration: 0.18)) {
        self.position = 0
      }
    }

    private func commitTransition(
      _ transition: Transition,
      from position: CGFloat,
    ) {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        self.transition = transition
        self.position = min(max(position, -0.96), 0)
      }
      withAnimation(.easeOut(duration: 0.2), completionCriteria: .removed) {
        self.position = -1
      } completion: {
        self.slideFinished(transition.id)
      }
    }

    private func slideFinished(_ transitionID: UUID) {
      guard var transition = self.transition,
            transition.id == transitionID else { return }
      switch transition.phase {
      case .sliding:
        transition.phase = .awaitingPlayback
        self.transition = transition
        self.onNext()
      case .playbackAdvanced:
        self.resetTransition()
      case .awaitingPlayback:
        break
      }
    }

    private func currentItemChanged(to playbackID: String) {
      guard var transition = self.transition else { return }
      guard playbackID == transition.nextItem.playbackID else {
        self.resetTransition()
        return
      }
      switch transition.phase {
      case .sliding:
        transition.phase = .playbackAdvanced
        self.transition = transition
      case .awaitingPlayback:
        self.resetTransition()
      case .playbackAdvanced:
        break
      }
    }

    private func cancelCommittedTransition(_ transitionID: UUID) {
      guard self.transition?.id == transitionID else { return }
      withAnimation(.easeOut(duration: 0.2)) {
        self.position = 0
      } completion: {
        guard self.transition?.id == transitionID else { return }
        self.resetTransition()
      }
    }

    private func resetTransition() {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        self.position = 0
        self.transition = nil
      }
    }
  }

  private struct NowPlayingBarTrackIdentity: View {
    let item: NowPlayingBarItem
    let artworkSize: CGFloat
    let artworkCornerRadius: CGFloat
    let spacing: CGFloat
    let foregroundColor: Color

    var body: some View {
      HStack(spacing: self.spacing) {
        NowPlayingArtwork(
          url: self.item.artworkURL,
          size: self.artworkSize,
          cornerRadius: self.artworkCornerRadius,
        )
        NowPlayingBarText(
          title: self.item.title,
          artist: self.item.artist,
          foregroundColor: self.foregroundColor,
        )
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .clipped()
    }
  }

  private struct NowPlayingBarText: View {
    let title: String
    let artist: String
    let foregroundColor: Color

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        Text(self.title)
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(self.foregroundColor)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)

        Text(self.artist)
          .font(.system(size: 12, weight: .regular, design: .rounded))
          .foregroundStyle(self.foregroundColor.opacity(0.86))
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
      }
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .clipped()
      .mask(alignment: .trailing) {
        HStack(spacing: 0) {
          Rectangle()
          LinearGradient(
            stops: [
              .init(color: .black, location: 0),
              .init(color: .clear, location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing,
          )
          .frame(width: 24)
        }
      }
    }
  }

  private struct NowPlayingArtwork: View {
    let url: URL?
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
      CachedArtworkImageView(url: self.url) { image in
        image
          .resizable()
          .scaledToFill()
          .frame(width: self.size, height: self.size)
          .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous))
      } placeholder: {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
          .fill(.secondary.opacity(0.18))
          .frame(width: self.size, height: self.size)
      }
    }
  }

  private struct NowPlayingIconButton: View {
    let systemName: String
    let size: CGFloat
    let foregroundColor: Color
    var isLoading = false
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: @MainActor @Sendable () -> Void

    var body: some View {
      Button(action: self.action) {
        Group {
          if self.isLoading {
            ProgressView()
              .controlSize(.small)
              .tint(self.foregroundColor)
          } else {
            Image(systemName: self.systemName)
              .font(.system(size: self.size, weight: .black))
          }
        }
        .foregroundStyle(self.foregroundColor)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .contentShape(Rectangle())
      .disabled(!self.isEnabled)
      .opacity(self.isEnabled ? 1 : 0.35)
      .accessibilityLabel(self.accessibilityLabel)
    }
  }

  #if DEBUG
    #Preview("Expanded") {
      NowPlayingBarContent(
        layout: .expanded,
        item: NowPlayingBarItem(
          id: "current",
          title: PreviewMusicData.nowPlayingTitle,
          artist: PreviewMusicData.nowPlayingArtist,
          artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        ),
        nextItem: NowPlayingBarItem(
          id: "next",
          title: "Stories",
          artist: "Alasdair Fraser & Natalie Haas",
          artworkURL: PreviewMusicData.storiesArtworkURL,
        ),
        isPlaying: true,
        isEnabled: true,
        foregroundColor: .black,
        onTap: {},
        onPlayTap: {},
        onNextTap: {},
      )
      .padding(24)
      .background(Color(.systemGroupedBackground))
    }

    #Preview("Inline") {
      NowPlayingBarContent(
        layout: .inline,
        item: NowPlayingBarItem(
          id: "current",
          title: PreviewMusicData.nowPlayingTitle,
          artist: PreviewMusicData.nowPlayingArtist,
          artworkURL: PreviewMusicData.nowPlayingArtworkURL,
        ),
        nextItem: NowPlayingBarItem(
          id: "next",
          title: "Stories",
          artist: "Alasdair Fraser & Natalie Haas",
          artworkURL: PreviewMusicData.storiesArtworkURL,
        ),
        isPlaying: false,
        isEnabled: true,
        foregroundColor: .black,
        onTap: {},
        onPlayTap: {},
        onNextTap: {},
      )
      .padding(24)
      .background(Color(.systemGroupedBackground))
    }
  #endif
#endif
