import Foundation
import XSlack

struct AdminLink {
  enum Path {
    case parent(Parent.Id)
    case iosDeviceEvents(vendorId: UUID)
    case verify(token: UUID)

    var pathComponent: String {
      switch self {
      case .parent(let id):
        "parents/\(id.lowercased)"
      case .iosDeviceEvents(let vendorId):
        "ios/\(vendorId.lowercased)/events"
      case .verify(let token):
        "verify/\(token.uuidString.lowercased())"
      }
    }
  }

  private let baseUrl: String

  init(_ overrideAdminUrl: String? = nil) {
    if let override = overrideAdminUrl, !override.isEmpty {
      self.baseUrl = override
    } else {
      self.baseUrl = get(dependency: \.env).get("ADMIN_SITE_URL") ?? "http://localhost:4243"
    }
  }

  func url(to path: Path) -> String {
    "\(self.baseUrl)/\(path.pathComponent)"
  }

  func slack(to path: Path, text: String) -> String {
    XSlack.Slack.Message.link(to: self.url(to: path), withText: text)
  }

  func email(to path: Path, text: String) -> String {
    "<a href=\"\(self.url(to: path))\">\(text)</a>"
  }
}
