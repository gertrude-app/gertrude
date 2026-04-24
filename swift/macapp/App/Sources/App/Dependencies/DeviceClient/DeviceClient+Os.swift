import Foundation
import Gertie

struct MacOSVersion: Sendable {
  typealias Name = MacOSName

  let major: Int
  let minor: Int
  let patch: Int

  var semver: Semver {
    .init(major: self.major, minor: self.minor, patch: self.patch)
  }

  var name: Name {
    .init(major: self.major, minor: self.minor)
  }

  var description: String {
    "\(self.name.rawValue)@\(self.semver.string)"
  }
}

@Sendable func macOSVersion() -> MacOSVersion {
  let version = ProcessInfo.processInfo.operatingSystemVersion
  return MacOSVersion(
    major: version.majorVersion,
    minor: version.minorVersion,
    patch: version.patchVersion,
  )
}

#if DEBUG
  extension MacOSVersion {
    static let tahoe = Self(major: 26, minor: 0, patch: 0)
    static let sonoma = Self(major: 14, minor: 0, patch: 0)
    static let sequoia = Self(major: 15, minor: 0, patch: 0)
  }
#endif
