import BlockerRoute
import ComposableArchitecture
import GertieUI
import LibApp
import LibCore
import SwiftUI

struct InfoView: View {
  @Bindable var store: StoreOf<InfoFeature>
  @Environment(\.colorScheme) var cs
  @Environment(\.scenePhase) var scenePhase
  @State private var justCopied = false

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .black)
        .ignoresSafeArea()
      if let clearCacheStore = self.store.scope(
        state: \.clearCache,
        action: \.clearCache,
      ) {
        ClearingCacheView(
          store: clearCacheStore,
          clearedMessage: "Previously downloaded GIFs should be gone!",
          clearedBtnLabel: "Back",
        )
        .onAppear { clearCacheStore.send(.onAppear) }
      } else {
        switch self.store.subScreen {
        case .main:
          if let connection = self.store.connection {
            self.connectedView(connection: connection)
          } else {
            self.unconnectedView
          }
        case .explainClearCache1:
          self.explainClearCacheView1
        case .explainClearCache2:
          self.explainClearCacheView2
        case .clearingCache:
          EmptyView()
        case .syncingProfile(let url):
          ProfileDownloadView(
            profileUrl: url,
            osMajorVersion: ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
          ) {
            self.store.send(.profileDownloadDismissed)
          }
        case .syncProfileDownloaded:
          GertieActionScreen(
            message: "Great, profile downloaded! To finish the sync, we just need to reinstall it. You’ll do this in the Settings app—we’ll explain how.",
            action: .button("Next", behavior: .afterExitAnimation) {
              self.store.send(.syncProfileNextTapped)
            },
          )
        case .syncProfileNotRemovableWarning:
          GertieActionScreen(
            message: "When reinstalling the profile, your \(self.deviceType) may warn you that it can’t be removed. Don’t worry—it can be removed at any time from the Gertrude account.",
            action: .button("Got it", behavior: .afterExitAnimation) {
              self.store.send(.syncProfileNextTapped)
            },
          )
        case .syncProfileExplainInstall(let regainedFocus):
          GertieActionScreen(
            message: "Now, open the Settings app:",
            bullets: [
              self.deviceType == "iPad"
                ? "In the left column, tap “Profile Downloaded” near the top"
                : "Tap “Profile Downloaded” near the top",
              "Tap “Install”",
              "Enter your passcode",
              "Come back to this app",
            ],
            action: .button(
              "Done, continue",
              isEnabled: regainedFocus,
              behavior: .afterExitAnimation,
            ) {
              self.store.send(.syncProfileNextTapped)
            },
          )
        }
      }
    }
    .onChange(of: self.scenePhase) { _, newPhase in
      if newPhase == .active {
        self.store.send(.appEnteredForeground)
      }
    }
  }

  var deviceType: String {
    UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
  }

  var unconnectedView: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 24) {
          HStack(spacing: 8) {
            Image(systemName: "gearshape")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
            Text("Info")
              .font(.system(size: 28, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 8)

          self.infoCard(
            title: "Device ID",
            value: self.store.deviceId?.uuidString.lowercased() ?? "(nil)",
            icon: "iphone",
            showCopyButton: true,
            justCopied: self.$justCopied,
          )

          self.infoCard(
            title: "Block Rules",
            value: "\(self.store.numRules) rules active",
            icon: "shield.checkered",
          )

          self.infoCard(
            title: "Block Groups",
            value: self.blockGroupsCardValue,
            icon: "slider.horizontal.3",
          )

          Spacer()

          VStack(spacing: 12) {
            Button {
              self.store.send(.clearCacheTapped)
            } label: {
              HStack(spacing: 8) {
                Text("Clear cache")
                Image(systemName: "trash")
              }
            }
            .buttonStyle(.gertiePrimary)
          }
          .padding(.top, 8)
          .padding(.bottom, 16)
        }
        .frame(minHeight: geometry.size.height - 30)
        .padding(.horizontal, 24)
        .padding(.top, 32)
      }
    }
  }

  var blockGroupsCardValue: String {
    let total = self.store.numTotalBlockGroups
    let enabled = total - self.store.numDisabledBlockGroups
    return "\(max(0, enabled))/\(total) groups enabled"
  }

  func connectedView(connection: ChildIOSDeviceData_v2) -> some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 24) {
          HStack(spacing: 8) {
            Image(systemName: "gearshape")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
            Text("Info")
              .font(.system(size: 28, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 8)

          self.infoCard(
            title: connection.supervisedByGertrude ? "Supervised" : "Child Name",
            value: connection.childName,
            icon: "person.circle",
          )

          self.infoCard(
            title: connection.supervisedByGertrude ? "User ID" : "Child ID",
            value: connection.childId.uuidString.lowercased(),
            icon: "number",
          )

          self.infoCard(
            title: "Device ID",
            value: self.store.deviceId?.uuidString.lowercased() ?? "(nil)",
            icon: "iphone",
            showCopyButton: true,
            justCopied: self.$justCopied,
          )

          self.infoCard(
            title: "Block Rules",
            value: "\(self.store.numRules) rules active",
            icon: "shield.checkered",
          )

          Spacer()

          VStack(spacing: 12) {
            if connection.supervisedByGertrude {
              Button {
                self.store.send(.syncProfileTapped)
              } label: {
                HStack(spacing: 8) {
                  Text("Sync Profile")
                  Image(systemName: "arrow.triangle.2.circlepath")
                }
              }
              .buttonStyle(.gertiePrimary)
            }
            Button {
              self.store.send(.clearCacheTapped)
            } label: {
              HStack(spacing: 8) {
                Text("Clear Cache")
                Image(systemName: "trash")
              }
            }
            .buttonStyle(.gertieSecondary)
          }
          .padding(.top, 8)
          .padding(.bottom, 16)
        }
        .frame(minHeight: geometry.size.height - 30)
        .padding(.horizontal, 24)
        .padding(.top, 32)
      }
    }
  }

  func infoCard(
    title: String,
    value: String,
    icon: String,
    showCopyButton: Bool = false,
    justCopied: Binding<Bool> = .constant(false),
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        Text(title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet200))
        Spacer()
        if showCopyButton {
          Button {
            UIPasteboard.general.string = value
            justCopied.wrappedValue = true
            Task {
              try? await Task.sleep(for: .seconds(2))
              justCopied.wrappedValue = false
            }
          } label: {
            Image(systemName: justCopied.wrappedValue ? "checkmark" : "doc.on.doc")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(
                justCopied.wrappedValue
                  ? Color(self.cs, light: .green, dark: .green)
                  : Color(self.cs, light: .violet500, dark: .violet300),
              )
              .frame(width: 16, height: 16)
          }
        }
      }

      Text(value)
        .font(.system(size: 15, design: .monospaced))
        .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(self.cs, light: .white.opacity(0.7), dark: .violet950)),
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(self.cs, light: .violet300, dark: .violet800), lineWidth: 1),
    )
  }

  var explainClearCacheView1: some View {
    GertieActionScreen(
      message: "Clearing the cache can help if there are images still visible that were downloaded BEFORE Gertrude was installed, especially if the #images GIF search is showing a mixture of images and grey squares.",
      actions: [
        .button("Next", behavior: .afterExitAnimation) {
          self.store.send(.explainClearCacheNextTapped)
        },
        .button("Cancel", behavior: .afterExitAnimation) {
          self.store.send(.cancelClearCacheTapped)
        },
      ],
    )
  }

  var explainClearCacheView2: some View {
    GertieActionScreen(
      message: "However, clearing the cache does not always remove all of these images. If you find that images persist, the only guaranteed way to remove them is to backup the device, do a factory reset, and then restore the backup.",
      actions: [
        .button("Next", behavior: .afterExitAnimation) {
          self.store.send(.explainClearCacheNextTapped)
        },
        .button("Cancel", behavior: .afterExitAnimation) {
          self.store.send(.cancelClearCacheTapped)
        },
      ],
    )
  }
}

#Preview("Unconnected - Light") {
  InfoView(store: .init(
    initialState: .init(
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 42,
      numDisabledBlockGroups: 4,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .light)
}

#Preview("Unconnected - Dark") {
  InfoView(store: .init(
    initialState: .init(
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 42,
      numDisabledBlockGroups: 4,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .dark)
}

#Preview("Connected - Light") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
      ),
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .light)
}

#Preview("Connected - Dark") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
      ),
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .dark)
}

#Preview("Supervised - Light") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
        supervised: .byGertrude(claimCode: 123_456),
      ),
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .light)
}

#Preview("Supervised - Dark") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
        supervised: .byGertrude(claimCode: 123_456),
      ),
      deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .dark)
}

#Preview("iPad Sheet - Supervised") {
  struct Container: View {
    @State private var isPresented = true
    var body: some View {
      Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: self.$isPresented) {
          InfoView(store: .init(
            initialState: .init(
              connection: .init(
                childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
                token: UUID(),
                deviceId: UUID(),
                childName: "Emma Johnson",
                supervised: .byGertrude(claimCode: 123_456),
              ),
              deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
              numRules: 87,
            ),
          ) {
            InfoFeature()
          })
          .pageSheet()
        }
    }
  }
  return Container()
}

#Preview("iPad Sheet - Syncing Profile") {
  struct Container: View {
    @State private var isPresented = true
    var body: some View {
      Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: self.$isPresented) {
          InfoView(store: .init(
            initialState: .init(
              connection: .init(
                childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
                token: UUID(),
                deviceId: UUID(),
                childName: "Emma Johnson",
                supervised: .byGertrude(claimCode: 123_456),
              ),
              deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
              numRules: 87,
              subScreen: .syncingProfile(
                URL(string: "https://gertrude-dev.nyc3.digitaloceanspaces.com/super.mobileconfig")!,
              ),
            ),
          ) {
            InfoFeature()
          })
          .pageSheet()
        }
    }
  }
  return Container()
}

#Preview("iPad Sheet - Unconnected") {
  struct Container: View {
    @State private var isPresented = true
    var body: some View {
      Color.gray.opacity(0.3)
        .ignoresSafeArea()
        .sheet(isPresented: self.$isPresented) {
          InfoView(store: .init(
            initialState: .init(
              deviceId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
              numRules: 42,
              numDisabledBlockGroups: 4,
            ),
          ) {
            InfoFeature()
          })
          .pageSheet()
        }
    }
  }
  return Container()
}
