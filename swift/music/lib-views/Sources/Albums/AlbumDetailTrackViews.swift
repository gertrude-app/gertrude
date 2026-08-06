import SwiftUI

struct AlbumDetailTrackRow: Identifiable, Equatable {
  let number: String?
  let track: TrackData

  var id: String { self.track.id }
}

struct AlbumDetailEmptyTracksView: View {
  var body: some View {
    Text("No tracks yet")
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity)
      .padding(24)
      .background(
        .primary.opacity(0.05),
        in: .rect(cornerRadius: 24, style: .continuous),
      )
  }
}
