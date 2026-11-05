import ComposableArchitecture
import GertieApp
import GertieUI
import LibViews
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

#if os(iOS) && !canImport(SwiftUI, _version: 8.0.85) && !DEBUG
  #error("Archive Gertrude Music with Xcode 27.1 or newer, or the iPhone Duo layouts are left out.")
#endif

public struct EntryPoint: View {
  private let store: AppStore

  public init(store: AppStore) {
    self.store = store
    #if canImport(UIKit)
      UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(
        Color.gertrudeBrandAccent,
      )
    #endif
  }

  public var body: some View {
    AppView(store: self.store.inner)
      .tint(.gertrudeBrandAccent)
  }
}

#if canImport(UIKit)
  public final class MusicAppDelegate: NSObject, UIApplicationDelegate {
    public func application(
      _: UIApplication,
      supportedInterfaceOrientationsFor _: UIWindow?,
    ) -> UIInterfaceOrientationMask {
      if UIDevice.current.userInterfaceIdiom == .pad {
        return .all
      }
      if IOSDeviceInfo.modelIdentifier() == "iPhone19,4" {
        return .allButUpsideDown
      }
      return .portrait
    }
  }
#endif

@MainActor
public struct AppStore {
  let inner: StoreOf<AppFeature>

  public init() {
    self.inner = Store(
      initialState: .init(
        identityGeneration: 0,
        identity: .init(available: false),
      ),
      reducer: { AppFeature() },
    )
  }
}
