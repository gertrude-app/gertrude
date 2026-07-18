import Foundation
import SwiftUI

struct ArtistEditorialNotesSection: View {
  let notes: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("About")
        .font(.title3.weight(.bold))

      Text(self.notes)
        .font(.body)
        .foregroundStyle(.secondary)
        .lineSpacing(3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct ArtistDetailSectionHeader: View {
  let title: String

  var body: some View {
    Text(self.title)
      .font(.title3.weight(.bold))
      .foregroundStyle(.primary)
      .padding(.horizontal, 20)
  }
}

struct ArtistDetailArtworkThumbnail: View {
  let url: URL?
  let systemImage: String
  let cornerRadius: CGFloat
  let size: CGFloat

  init(
    url: URL?,
    systemImage: String,
    cornerRadius: CGFloat = 9,
    size: CGFloat = 44,
  ) {
    self.url = url
    self.systemImage = systemImage
    self.cornerRadius = cornerRadius
    self.size = size
  }

  var body: some View {
    CachedArtworkImageView(url: self.url) { image in
      image
        .resizable()
        .scaledToFill()
        .frame(width: self.size, height: self.size)
        .clipShape(
          .rect(cornerRadius: self.cornerRadius, style: .continuous),
        )
    } placeholder: {
      RoundedRectangle(
        cornerRadius: self.cornerRadius,
        style: .continuous,
      )
      .fill(Color.gertrudeBrandAccent.opacity(0.14))
      .frame(width: self.size, height: self.size)
      .overlay {
        Image(systemName: self.systemImage)
          .font(.system(size: self.size * 0.38, weight: .semibold))
          .foregroundStyle(Color.gertrudeBrandAccent.opacity(0.68))
      }
    }
    .accessibilityHidden(true)
  }
}

struct ArtistDetailEmptyCard: View {
  let systemImage: String
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: self.systemImage)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      Text(self.title)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)

      Text(self.message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(18)
    .background(
      .primary.opacity(0.05),
      in: .rect(cornerRadius: 18, style: .continuous),
    )
    .frame(maxWidth: 700)
    .frame(maxWidth: .infinity)
  }
}
