import Dependencies
import Foundation
import JWT
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct AppStoreConnectClient: Sendable {
  var fetchReviews: @Sendable (_ app: GertrudeIOSApp) async throws -> [CustomerReview]
  var fetchRatings: @Sendable (_ app: GertrudeIOSApp) async throws -> ITunesRatings
  var fetchAppStoreVersion: @Sendable (_ app: GertrudeIOSApp) async throws -> String
}

struct CustomerReview: Codable, Sendable {
  var id: String
  var rating: Int
  var title: String?
  var body: String
  var reviewerNickname: String
  var territory: String
  var createdDate: Date
}

struct ITunesRatings: Codable, Sendable {
  var averageUserRating: Double
  var userRatingCount: Int
}

extension AppStoreConnectClient: DependencyKey {
  static var liveValue: AppStoreConnectClient {
    .init(
      fetchReviews: { app in
        let token = try await generateJWT()
        return try await fetchAllReviews(appId: app.appStoreAppleId, token: token)
      },
      fetchRatings: { app in
        try await fetchITunesRatings(appId: app.appStoreAppleId)
      },
      fetchAppStoreVersion: { app in
        try await fetchITunesVersion(appId: app.appStoreAppleId)
      },
    )
  }
}

private func generateJWT() async throws -> String {
  let env = get(dependency: \.env.appStoreConnect)
  let now = Date()

  let payload = AppStoreConnectPayload(
    iss: .init(value: env.issuerId),
    iat: .init(value: now),
    exp: .init(value: now.addingTimeInterval(20 * 60)),
    aud: .init(value: "appstoreconnect-v1"),
  )

  let privateKeyPEM = env.privateKey
    .replacingOccurrences(of: "\\n", with: "\n")

  let key = try ES256PrivateKey(pem: privateKeyPEM)
  let keyCollection = JWTKeyCollection()
  await keyCollection.add(ecdsa: key, kid: .init(string: env.keyId))
  return try await keyCollection.sign(payload, kid: .init(string: env.keyId))
}

private struct AppStoreConnectPayload: JWTPayload {
  var iss: IssuerClaim
  var iat: IssuedAtClaim
  var exp: ExpirationClaim
  var aud: AudienceClaim

  func verify(using _: some JWTAlgorithm) throws {
    try self.exp.verifyNotExpired()
  }
}

private func fetchAllReviews(appId: String, token: String) async throws -> [CustomerReview] {
  var allReviews: [CustomerReview] = []
  var nextUrl: String? = "https://api.appstoreconnect.apple.com/v1/apps/\(appId)/customerReviews?limit=200&sort=-createdDate"

  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  while let url = nextUrl {
    let (data, _) = try await HTTP.get(
      url,
      headers: [
        "Authorization": "Bearer \(token)",
        "Content-Type": "application/json",
      ],
    )
    let response = try decoder.decode(ReviewsResponse.self, from: data)

    for item in response.data {
      allReviews.append(CustomerReview(
        id: item.id,
        rating: item.attributes.rating,
        title: item.attributes.title,
        body: item.attributes.body,
        reviewerNickname: item.attributes.reviewerNickname,
        territory: item.attributes.territory,
        createdDate: item.attributes.createdDate,
      ))
    }

    nextUrl = response.links?.next
  }

  return allReviews
}

private struct ReviewsResponse: Codable {
  var data: [ReviewData]
  var links: Links?

  struct ReviewData: Codable {
    var id: String
    var attributes: Attributes

    struct Attributes: Codable {
      var rating: Int
      var title: String?
      var body: String
      var reviewerNickname: String
      var territory: String
      var createdDate: Date
    }
  }

  struct Links: Codable {
    var next: String?
  }
}

private func fetchITunesRatings(appId: String) async throws -> ITunesRatings {
  let url = "https://itunes.apple.com/lookup?id=\(appId)&cb=\(Int(Date().timeIntervalSince1970))"
  let response = try await HTTP.get(url, decoding: ITunesLookupResponse.self)

  guard let result = response.results.first else {
    throw AppStoreConnectError.noResults
  }

  return ITunesRatings(
    averageUserRating: result.averageUserRating,
    userRatingCount: result.userRatingCount,
  )
}

private func fetchITunesVersion(appId: String) async throws -> String {
  let url = "https://itunes.apple.com/lookup?id=\(appId)&cb=\(Int(Date().timeIntervalSince1970))"
  let response = try await HTTP.get(url, decoding: ITunesLookupResponse.self)
  guard let result = response.results.first else {
    throw AppStoreConnectError.noResults
  }
  return result.version
}

private struct ITunesLookupResponse: Codable {
  var resultCount: Int
  var results: [Result]

  struct Result: Codable {
    var averageUserRating: Double
    var userRatingCount: Int
    var version: String
  }
}

enum AppStoreConnectError: Error {
  case noResults
}

extension AppStoreConnectClient: TestDependencyKey {
  static var testValue: AppStoreConnectClient {
    .init(
      fetchReviews: unimplemented("AppStoreConnectClient.fetchReviews()", placeholder: []),
      fetchRatings: unimplemented(
        "AppStoreConnectClient.fetchRatings()",
        placeholder: ITunesRatings(averageUserRating: 0, userRatingCount: 0),
      ),
      fetchAppStoreVersion: unimplemented(
        "AppStoreConnectClient.fetchAppStoreVersion()",
        placeholder: "",
      ),
    )
  }
}

extension DependencyValues {
  var appStoreConnect: AppStoreConnectClient {
    get { self[AppStoreConnectClient.self] }
    set { self[AppStoreConnectClient.self] = newValue }
  }
}
