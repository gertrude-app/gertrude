import Foundation
import SwiftUI

@main
struct FakeEntry: App {
  var body: some Scene {
    WindowGroup { EmptyView() }
  }
}

extension Bundle? {
  static var module: Bundle? {
    Bundle.main
  }
}
