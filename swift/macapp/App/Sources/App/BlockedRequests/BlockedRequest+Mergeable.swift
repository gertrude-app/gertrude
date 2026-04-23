import Core

extension BlockedRequest {
  var hiddenFromParent: Bool {
    guard let hostname else { return false }
    return hostname == "cloudflare-ech.com" || hostname.hasSuffix(".cloudflare-ech.com")
  }

  func mergeable(with newer: BlockedRequest) -> Bool {
    if self.app.bundleId.droppingDotPrefix != newer.app.bundleId.droppingDotPrefix {
      return false
    } else if self.ipProtocol != newer.ipProtocol {
      return false
    } else if self.hostname != nil, self.hostname == newer.hostname {
      return true
    } else if newer.hostname != nil, self.hostname == nil {
      return false
    } else if newer.url != nil, self.url == nil {
      return false
    } else if self.url != nil, self.url == newer.url {
      return true
    } else if self.ipAddress != nil, self.ipAddress == newer.ipAddress {
      return true
    }
    return false
  }
}

private extension String {
  var droppingDotPrefix: Substring {
    self.first == "." ? self.dropFirst() : self[...]
  }
}
