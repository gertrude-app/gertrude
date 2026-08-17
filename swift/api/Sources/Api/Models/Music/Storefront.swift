import Tagged

extension Music {
  typealias Storefront = Tagged<(Music, storefront: ()), String>
}

extension Music.Storefront {
  static let `default`: Self = "us"

  var isValid: Bool {
    self.rawValue.count == 2 && self.rawValue.allSatisfy { $0.isASCII && $0.isLowercase }
  }
}
