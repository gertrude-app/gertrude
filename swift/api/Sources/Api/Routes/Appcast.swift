import Dependencies
import DuetSQL
import Gertie
import Vapor

enum AppcastRoute {
  static let suppressedReleases: [String: Set<String>] = [
    "2.9.1": ["2.9.2"],
  ]

  static func hiddenReleases(forRequestingAppVersion version: String?) -> Set<String> {
    version.flatMap { self.suppressedReleases[$0] } ?? []
  }

  @Sendable static func handler(_ request: Request) async throws -> Response {
    let query = try request.query.decode(AppcastQuery.self)
    let hidden = Self.hiddenReleases(forRequestingAppVersion: query.requestingAppVersion)
    let releases = try await request.context.db.query(Release.self)
      .orderBy(.createdAt, .desc)
      .all(in: request.context.db)
      .filter { $0.channel.isAtLeastAsStable(as: query.channel ?? .stable) }
      .filter { !hidden.contains($0.semver) }

    return Response(
      headers: ["Content-Type": "application/xml"],
      body: .init(string: feedXml(
        for: releases,
        force: query.force == true || query.version != nil,
      )),
    )
  }
}

// helpers

func feedXml(for releases: [Release], force: Bool = false) -> String {
  let items = releases.enumerated().map { index, release in
    release.sparkleItemXml(forceUpdate: force && index == 0)
  }.joined(separator: "\n")

  return """
  <?xml version="1.0" standalone="yes"?>
  <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
      <title>Gertrude</title>
      \(items)
    </channel>
  </rss>
  """
}

extension Release {
  func sparkleItemXml(forceUpdate: Bool = false) -> String {
    let description = notes.map { "\n  <description><![CDATA[\($0)]]></description>" } ?? ""
    let formatter = DateFormatter()
    formatter.timeZone = .init(abbreviation: "UTC")
    formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
    return """
    <item>
      <title>\(forceUpdate ? "99.99.99" : semver)</title>
      <pubDate>\(formatter.string(from: createdAt))</pubDate>
      <sparkle:version>\(forceUpdate ? "99.99.99" : semver)</sparkle:version>
      <sparkle:shortVersionString>\(forceUpdate ? "99.99.99" : semver)</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>\(minVersion)</sparkle:minimumSystemVersion>
      <enclosure
        url="\(get(dependency: \.env).s3.bucketUrl)/releases/Gertrude.\(semver).zip"
        length="\(length)"
        type="application/octet-stream"
        sparkle:edSignature="\(signature)"
      />\(description)
    </item>
    """
  }
}
