import SwiftUI

public enum PlaylistMusicPickerDuplicatePrompt: Equatable, Sendable {
  case batch(duplicateCount: Int)
  case track(title: String)
}

public struct PlaylistMusicPickerSheet: View {
  @Binding private var query: String

  private let duplicatePrompt: PlaylistMusicPickerDuplicatePrompt?
  private let errorMessage: String?
  private let errorTitle: String
  private let errorTone: NoticeBannerTone
  private let isMutating: Bool
  private let playlistName: String
  private let results: [MusicSearchResultData]
  private let selectedResultIDs: Set<String>
  private let onAddTap: @MainActor @Sendable () -> Void
  private let onCancelTap: @MainActor @Sendable () -> Void
  private let onDuplicateAddAllTap: @MainActor @Sendable () -> Void
  private let onDuplicateAddOnlyNewTap: @MainActor @Sendable () -> Void
  private let onDuplicateCancelTap: @MainActor @Sendable () -> Void
  private let onErrorDismissTap: (@MainActor @Sendable () -> Void)?
  private let onResultTap: @MainActor @Sendable (String) -> Void

  @State private var isSearchPresented = true

  public init(
    playlistName: String,
    results: [MusicSearchResultData],
    selectedResultIDs: Set<String>,
    query: Binding<String>,
    duplicatePrompt: PlaylistMusicPickerDuplicatePrompt? = nil,
    errorMessage: String? = nil,
    errorTitle: String = "Couldn’t add music",
    errorTone: NoticeBannerTone = .error,
    isMutating: Bool = false,
    onAddTap: @MainActor @escaping @Sendable () -> Void = {},
    onCancelTap: @MainActor @escaping @Sendable () -> Void = {},
    onDuplicateAddAllTap: @MainActor @escaping @Sendable () -> Void = {},
    onDuplicateAddOnlyNewTap: @MainActor @escaping @Sendable () -> Void = {},
    onDuplicateCancelTap: @MainActor @escaping @Sendable () -> Void = {},
    onErrorDismissTap: (@MainActor @Sendable () -> Void)? = nil,
    onResultTap: @MainActor @escaping @Sendable (String) -> Void = { _ in },
  ) {
    self.playlistName = playlistName
    self.results = results
    self.selectedResultIDs = selectedResultIDs
    self._query = query
    self.duplicatePrompt = duplicatePrompt
    self.errorMessage = errorMessage
    self.errorTitle = errorTitle
    self.errorTone = errorTone
    self.isMutating = isMutating
    self.onAddTap = onAddTap
    self.onCancelTap = onCancelTap
    self.onDuplicateAddAllTap = onDuplicateAddAllTap
    self.onDuplicateAddOnlyNewTap = onDuplicateAddOnlyNewTap
    self.onDuplicateCancelTap = onDuplicateCancelTap
    self.onErrorDismissTap = onErrorDismissTap
    self.onResultTap = onResultTap
  }

  public var body: some View {
    NavigationStack {
      self.content
        .searchable(
          text: self.$query,
          isPresented: self.$isSearchPresented,
          prompt: "Search your music",
        )
        .preservingToolbarDuringSearch()
        .disabled(self.isMutating)
        .safeAreaInset(edge: .bottom, spacing: 0) {
          if let errorMessage = self.errorMessage {
            NoticeBanner(
              tone: self.errorTone,
              title: self.errorTitle,
              message: errorMessage,
              onDismissTap: self.onErrorDismissTap,
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
        .animation(.snappy(duration: 0.24), value: self.errorMessage)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(action: self.onCancelTap) {
              Label("Close", systemImage: "xmark")
            }
            .tint(.primary)
            .disabled(self.isMutating)
          }
          ToolbarItem(placement: .confirmationAction) {
            Button(action: self.onAddTap) {
              Text(self.addButtonTitle)
                .foregroundStyle(.white)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gertrudeBrandAccent)
            .disabled(self.selectedResultIDs.isEmpty || self.isMutating)
          }
        }
        .alert(self.duplicateTitle, isPresented: self.duplicateConfirmationBinding) {
          self.duplicateActions
        } message: {
          Text(self.duplicateMessage)
        }
        .overlay {
          if self.isMutating {
            ProgressView("Adding")
              .padding(20)
              .background(.regularMaterial, in: .rect(cornerRadius: 16))
          }
        }
    }
    .interactiveDismissDisabled(self.isMutating)
  }

  @ViewBuilder
  private var content: some View {
    if self.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      ContentUnavailableView(
        "Search your music",
        systemImage: "magnifyingglass",
        description: Text("Find approved songs and albums to add to \(self.playlistName)."),
      )
    } else if self.results.isEmpty {
      ContentUnavailableView("No results", systemImage: "magnifyingglass")
    } else {
      List {
        Section {
          ForEach(self.results) { result in
            PlaylistMusicPickerResultRow(
              result: result,
              isSelected: self.selectedResultIDs.contains(result.id),
              onTap: { self.onResultTap(result.id) },
            )
          }
        }
        .listSectionSeparator(.hidden, edges: [.top, .bottom])
      }
      .listStyle(.plain)
      .scrollDismissesKeyboard(.interactively)
    }
  }

  private var addButtonTitle: String {
    switch self.selectedResultIDs.count {
    case 1:
      "Add 1 Item"
    default:
      "Add \(self.selectedResultIDs.count) Items"
    }
  }

  @ViewBuilder
  private var duplicateActions: some View {
    switch self.duplicatePrompt {
    case .batch:
      Button("Cancel", role: .cancel, action: self.onDuplicateCancelTap)
      Button("Add Only New Songs", action: self.onDuplicateAddOnlyNewTap)
      Button("Add Anyway", action: self.onDuplicateAddAllTap)
    case .track:
      Button("Cancel", role: .cancel, action: self.onDuplicateCancelTap)
      Button("Add Again", action: self.onDuplicateAddAllTap)
    case nil:
      EmptyView()
    }
  }

  private var duplicateConfirmationBinding: Binding<Bool> {
    Binding(
      get: { self.duplicatePrompt != nil },
      set: { isPresented in
        if !isPresented {
          self.onDuplicateCancelTap()
        }
      },
    )
  }

  private var duplicateMessage: String {
    switch self.duplicatePrompt {
    case .batch(let duplicateCount):
      let songText = duplicateCount == 1 ? "song is" : "songs are"
      return "\(duplicateCount) \(songText) already in “\(self.playlistName)”."
    case .track(let title):
      return "“\(title)” is already in “\(self.playlistName)”. Add it again?"
    case nil:
      return ""
    }
  }

  private var duplicateTitle: String {
    switch self.duplicatePrompt {
    case .batch:
      "Some Songs Are Already Added"
    case .track:
      "Song Already Added"
    case nil:
      "Add to Playlist"
    }
  }
}

private extension View {
  @ViewBuilder
  func preservingToolbarDuringSearch() -> some View {
    if #available(iOS 17.1, *) {
      self.searchPresentationToolbarBehavior(.avoidHidingContent)
    } else {
      self
    }
  }
}

private struct PlaylistMusicPickerResultRow: View {
  let result: MusicSearchResultData
  let isSelected: Bool
  let onTap: @MainActor @Sendable () -> Void

  var body: some View {
    Button(action: self.onTap) {
      HStack(spacing: 12) {
        MusicSearchResultArtwork(result: self.result, transitionNamespace: nil)

        VStack(alignment: .leading, spacing: 3) {
          Text(self.result.title)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)

          Text(self.result.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer(minLength: 0)

        Image(systemName: self.isSelected ? "checkmark.circle.fill" : "circle")
          .font(.title3)
          .foregroundStyle(self.isSelected ? Color.gertrudeBrandAccent : Color.secondary
            .opacity(0.55))
          .accessibilityHidden(true)
      }
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(self.accessibilityLabel)
    .accessibilityValue(self.isSelected ? "Selected" : "Not selected")
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
  }

  private var accessibilityLabel: String {
    [
      self.result.kind.title,
      self.result.title,
      self.result.detail,
    ]
    .compactMap(\.self)
    .joined(separator: ", ")
  }
}

#if DEBUG
  #Preview("Add music") {
    @Previewable @State var query = "queen"
    PlaylistMusicPickerSheet(
      playlistName: "Road Trip",
      results: [
        .init(
          id: "song-killer-queen",
          kind: .song,
          collectionID: "killer-queen",
          title: "Killer Queen",
          detail: "Queen · Sheer Heart Attack",
        ),
        .init(
          id: "album-queen-ii",
          kind: .album,
          collectionID: "queen-ii",
          title: "Queen II",
          detail: "Queen",
        ),
      ],
      selectedResultIDs: ["song-killer-queen"],
      query: $query,
    )
  }

  #Preview("Duplicate song") {
    @Previewable @State var query = "queen"
    PlaylistMusicPickerSheet(
      playlistName: "Road Trip",
      results: [
        .init(
          id: "song-killer-queen",
          kind: .song,
          collectionID: "killer-queen",
          title: "Killer Queen",
          detail: "Queen · Sheer Heart Attack",
        ),
      ],
      selectedResultIDs: ["song-killer-queen"],
      query: $query,
      duplicatePrompt: .track(title: "Killer Queen"),
    )
  }

  #Preview("Add music error") {
    @Previewable @State var query = "queen"
    PlaylistMusicPickerSheet(
      playlistName: "Road Trip",
      results: [
        .init(
          id: "song-killer-queen",
          kind: .song,
          collectionID: "killer-queen",
          title: "Killer Queen",
          detail: "Queen · Sheer Heart Attack",
        ),
      ],
      selectedResultIDs: ["song-killer-queen"],
      query: $query,
      errorMessage: "Your selection is still here. Try adding it again.",
      onErrorDismissTap: {},
    )
  }
#endif
