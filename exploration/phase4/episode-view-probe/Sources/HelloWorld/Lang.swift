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

public extension EnvironmentValues {
  @Entry var lang: Lang = .english
}
