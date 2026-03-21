import IOSRoute
import LibApp
import SwiftUI

struct ChooseWhatToBlockView: View {
  @Environment(\.colorScheme) var cs

  let allGroups: [GetBlockGroups.BlockGroupInfo]
  let disabledGroupIds: [UUID]
  let onGroupToggle: (UUID) -> Void
  let onDone: () -> Void

  @State private var sheetItem: GetBlockGroups.BlockGroupInfo? = nil
  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var paragraphOffset = Vector(x: 0, y: 20)
  @State private var itemOffsets: [Vector]
  @State private var buttonOffset = Vector(x: 0, y: 20)
  @State private var showBg = false
  @State private var showTooltip = false

  init(
    allGroups: [GetBlockGroups.BlockGroupInfo],
    disabledGroupIds: [UUID],
    onGroupToggle: @escaping (UUID) -> Void,
    onDone: @escaping () -> Void,
  ) {
    self.allGroups = allGroups
    self.disabledGroupIds = disabledGroupIds
    self.onGroupToggle = onGroupToggle
    self.onDone = onDone
    self._itemOffsets = State(initialValue: Array(
      repeating: Vector(x: 0, y: 40),
      count: allGroups.count,
    ))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .center) {
        Image(systemName: "party.popper")
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet400))
          .padding(12)
          .background(Color(self.cs, light: .violet300.opacity(0.6), dark: .violet950))
          .cornerRadius(24)
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .zero, for: .seconds(0.6))

        Text("Success! We're nearly done.")
          .multilineTextAlignment(.center)
          .font(.system(size: 24, weight: .bold))
          .padding(.top, 28)
          .padding(.bottom, 8)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.1),
            for: .seconds(0.6),
          )

        Text(
          "Gertrude is all set to block content. Take a moment to decide if there are any of these types of content that you don't want to block:",
        )
        .multilineTextAlignment(.center)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
        .padding(.bottom, 20)
        .swooshIn(
          tracking: self.$paragraphOffset,
          to: .zero,
          after: .seconds(0.2),
          for: .seconds(0.6),
        )

        self.selectableGroups

        BigButton(
          "Done, continue",
          type: .button {
            self.vanishingAnimations()
            delayed(by: .seconds(0.5)) {
              self.onDone()
            }
          },
          variant: .primary,
          disabled: !self.allGroups.isEmpty
            && self.allGroups.allSatisfy { self.disabledGroupIds.contains($0.id) },
        )
        .swooshIn(
          tracking: self.$buttonOffset,
          to: .zero,
          after: .seconds(0.2),
          for: .seconds(0.6),
        )
      }
      .frame(maxWidth: 500)
      .padding(.top, 100)
      .padding(.bottom, 50)
      .padding(.horizontal, 30)
    }
    .frame(maxWidth: .infinity)
    .background(Color(self.cs, light: .violet100, dark: .violet950.opacity(0.4)))
    .opacity(self.showBg ? 1 : 0)
    .onAppear {
      withAnimation(.smooth(duration: 0.5)) {
        self.showBg = true
      }
    }
    .ignoresSafeArea()
    .sheet(item: self.$sheetItem) { item in
      NavigationStack {
        ZStack {
          Color(self.cs, light: .white, dark: .violet950.opacity(0.3))
            .edgesIgnoringSafeArea(.vertical)
          VStack {
            if let imageName = item.imageSlug {
              Image(imageName)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .shadow(color: .black.opacity(0.1), radius: 8)
            }
            Text(item.name)
              .font(.system(size: 24, weight: .bold))
              .padding(.top, 20)
              .padding(.bottom, 4)
            Text(item.longDescription)
              .font(.system(size: 16))
              .foregroundStyle(
                Color(
                  self.cs,
                  light: .black.opacity(0.7),
                  dark: .white.opacity(0.7),
                ),
              )
              .multilineTextAlignment(.center)
          }
          .presentationDetents([.height(600)])
          .padding(20)
          .toolbar {
            ToolbarItem {
              Button {
                self.sheetItem = nil
              } label: {
                Image(systemName: "xmark")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(
                    Color(
                      self.cs,
                      light: .black.opacity(0.4),
                      dark: .white.opacity(0.5),
                    ),
                  )
                  .padding(8)
                  .background(
                    Color(
                      self.cs,
                      light: .black.opacity(0.05),
                      dark: .white.opacity(0.08),
                    ),
                  )
                  .cornerRadius(16)
              }
            }
          }
        }
      }
    }
  }

  var selectableGroups: some View {
    VStack(alignment: .leading) {
      ForEach(
        Array(self.allGroups.enumerated()),
        id: \.1.id,
      ) { (index: Int, item: GetBlockGroups.BlockGroupInfo) in
        Button {
          withAnimation(.smooth(duration: 0.1)) {
            self.onGroupToggle(item.id)
          }
        } label: {
          ZStack {
            HStack(alignment: .top, spacing: 12) {
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .scaleEffect(self.isEnabled(item) ? 1 : 0)
                .foregroundStyle(.white)
                .padding(4)
                .background(
                  self.isEnabled(item)
                    ? Color.violet500
                    : Color(
                      self.cs,
                      light: .white,
                      dark: .black,
                    ),
                )
                .cornerRadius(6)
                .overlay {
                  RoundedRectangle(cornerRadius: 6)
                    .stroke(
                      self.isEnabled(item) ? Color.violet500 : Color.gray.opacity(0.2),
                      lineWidth: 2,
                    )
                }

              VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                  Text(item.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(self.cs, light: .black, dark: .white))

                  Button {
                    withAnimation {
                      self.showTooltip = false
                    }
                    // if analytics show high engagement here, consider adding
                    // image_url_light + image_url_dark columns to iosapp.block_groups
                    self.sheetItem = item
                  } label: {
                    Image(systemName: "questionmark.circle")
                      .font(.system(size: 12, weight: .medium))
                      .foregroundStyle(
                        Color(
                          self.cs,
                          light: .black.opacity(0.4),
                          dark: .white.opacity(0.4),
                        ),
                      )
                      .padding(.horizontal, 8)
                      .padding(.vertical, 4)
                      .multilineTextAlignment(.leading)
                  }
                }

                Text(item.shortDescription)
                  .font(.system(size: 15, weight: .regular))
                  .foregroundStyle(
                    Color(
                      self.cs,
                      light: .black.opacity(0.6),
                      dark: .white.opacity(0.6),
                    ),
                  )
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
              Gradient(colors: [
                Color(self.cs, light: .white, dark: .white.opacity(0.15)),
                Color(self.cs, light: .white.opacity(0.7), dark: .white.opacity(0.07)),
              ]),
            )
            .cornerRadius(16)
            .shadow(
              color: Color(self.cs, light: .violet200, dark: .violet900.opacity(0.3)),
              radius: 3,
            )
            .opacity(self.isEnabled(item) ? 1 : self.cs == .light ? 0.7 : 0.5)

            if index == 0 {
              VStack(spacing: -24) {
                Text("Tap to find\nout more")
                  .font(.system(size: 14, weight: .medium))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(Color(self.cs, light: .white, dark: .violet900))
                  .padding(.horizontal, 8)
                  .padding(.vertical, 6)
                  .background(Color(self.cs, light: .violet500, dark: .violet300))
                  .cornerRadius(8)
                  .frame(width: 120, height: 80)
                  .shadow(
                    color: Color(self.cs, light: .violet900, dark: .black).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 2,
                  )
                Rectangle()
                  .fill(Color(self.cs, light: .violet500, dark: .violet300))
                  .frame(width: 12, height: 12)
                  .rotationEffect(.degrees(45))
              }
              .position(x: 98, y: -22)
              .opacity(self.showTooltip ? 1 : 0)
              .offset(y: self.showTooltip ? 0 : -10)
              .onAppear {
                delayed(by: .seconds(1.5)) {
                  withAnimation(.bouncy(duration: 0.4, extraBounce: 0.3)) {
                    self.showTooltip = true
                  }
                }
              }
            }
          }
        }
        .buttonStyle(BounceButtonStyle())
        .sensoryFeedback(.selection, trigger: self.isEnabled(item))
        .swooshIn(
          tracking: self.$itemOffsets[index],
          to: .zero,
          after: .seconds(Double(index) / 15.0 + 0.3),
          for: .milliseconds(600),
        )
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }

  func isEnabled(_ group: GetBlockGroups.BlockGroupInfo) -> Bool {
    !self.disabledGroupIds.contains(group.id)
  }

  func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.titleOffset.y = -20
      self.paragraphOffset.y = -20
      self.itemOffsets = Array(repeating: .init(x: 0, y: -20), count: self.allGroups.count)
    }

    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.buttonOffset.y = -20
        self.showBg = false
      }
    }
  }
}

extension GetBlockGroups.BlockGroupInfo: @retroactive Identifiable {}

#Preview("none selected") {
  ChooseWhatToBlockView(
    allGroups: previewBlockGroups,
    disabledGroupIds: previewBlockGroups.map(\.id),
    onGroupToggle: { _ in },
    onDone: {},
  )
}

#Preview("all selected") {
  ChooseWhatToBlockView(
    allGroups: previewBlockGroups,
    disabledGroupIds: [],
    onGroupToggle: { _ in },
    onDone: {},
  )
}

private let previewBlockGroups: [GetBlockGroups.BlockGroupInfo] = [
  "MessagesGIFs", "MapsImages", "AIFeatures", "AppStoreImages", "SpotlightSearch",
  "AdBlocking", "BadWhatsAppFeatures", "AppleWebsite", "SpotifyImages", "AppleMusicImages",
].map { slug in
  .init(
    id: UUID(),
    name: slug,
    shortDescription: "Short description for \(slug)",
    longDescription: "Long description for \(slug)",
    imageSlug: slug,
  )
}

struct BounceButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
  }
}
