import ComposableArchitecture
import LibViews
import SwiftUI

struct PlaylistMusicPickerViewContainer: View {
  @Bindable var store: StoreOf<PlaylistMusicPickerFeature>
  let errorMessage: String?
  let errorTitle: String
  let errorTone: NoticeBannerTone
  let isMutating: Bool
  let onErrorDismissTap: @MainActor @Sendable () -> Void

  var body: some View {
    PlaylistMusicPickerSheet(
      playlistName: self.store.playlistName,
      results: self.store.results.map(\.viewData),
      selectedResultIDs: Set(self.store.selectedResultIDs.map(\.rawValue)),
      query: self.$store.query.sending(\.queryChanged),
      duplicatePrompt: self.store.duplicatePrompt?.viewData,
      errorMessage: self.errorMessage,
      errorTitle: self.errorTitle,
      errorTone: self.errorTone,
      isMutating: self.isMutating,
      onAddTap: { self.store.send(.addButtonTapped) },
      onCancelTap: { self.store.send(.dismissButtonTapped) },
      onDuplicateAddAllTap: {
        self.store.send(.duplicateResolutionSelected(.addAll))
      },
      onDuplicateAddOnlyNewTap: {
        self.store.send(.duplicateResolutionSelected(.addOnlyNew))
      },
      onDuplicateCancelTap: {
        self.store.send(.duplicateConfirmationCancelled)
      },
      onErrorDismissTap: self.onErrorDismissTap,
      onResultTap: self.resultTapped,
    )
  }

  private func resultTapped(rawID: String) {
    guard let id = MusicSearchResult.ID(rawValue: rawID) else { return }
    self.store.send(.resultTapped(id))
  }
}

private extension PlaylistMusicPickerFeature.DuplicatePrompt {
  var viewData: PlaylistMusicPickerDuplicatePrompt {
    switch self {
    case .batch(let duplicateCount):
      .batch(duplicateCount: duplicateCount)
    case .track(let title):
      .track(title: title)
    }
  }
}
