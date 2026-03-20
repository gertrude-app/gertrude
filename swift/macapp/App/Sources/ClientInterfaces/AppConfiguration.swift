import Foundation

public enum AppConfiguration {
  public static var apiBaseURL: URL {
    url(for: "API_BASE_URL") ?? defaultApiBaseURL
  }

  public static var appcastURL: URL {
    url(for: "APPCAST_URL") ?? defaultAppcastURL
  }

  private static func url(for key: String) -> URL? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
      return nil
    }

    guard !value.contains("$("),
          let url = URL(string: value),
          let scheme = url.scheme?.lowercased(),
          ["http", "https"].contains(scheme),
          url.host != nil else {
      return nil
    }

    return url
  }

  private static var defaultApiBaseURL: URL {
    #if DEBUG
      URL(string: "http://127.0.0.1:8080")!
    #else
      URL(string: "https://api.gertrude.app")!
    #endif
  }

  private static var defaultAppcastURL: URL {
    #if DEBUG
      URL(string: "http://127.0.0.1:8080/appcast.xml")!
    #else
      URL(string: "https://api.gertrude.app/appcast.xml")!
    #endif
  }
}
