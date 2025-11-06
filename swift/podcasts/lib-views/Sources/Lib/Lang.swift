import Foundation
import SwiftUI

/// officially supported languages
public enum Lang {
  case english
  case spanish
}

extension Lang: Sendable, Equatable {}

public extension Lang {
  init(locale: Locale) {
    if locale.identifier.hasPrefix("es") {
      self = .spanish
    } else {
      self = .english
    }
  }
}

public struct LangEnvKey: EnvironmentKey {
  public static let defaultValue: Lang = .english
}

public extension EnvironmentValues {
  var lang: Lang {
    get { self[LangEnvKey.self] }
    set { self[LangEnvKey.self] = newValue }
  }
}
