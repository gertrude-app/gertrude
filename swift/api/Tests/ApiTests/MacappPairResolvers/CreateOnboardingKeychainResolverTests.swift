import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CreateOnboardingKeychainResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsFailureForInvalidDomain() async throws {
    let child = try await self.childWithComputer()
    let output = try await CreateOnboardingKeychain.resolve(with: "nope", in: child.context)
    expect(output).toEqual(.failure)
  }

  func testBackgroundTaskCreatesKeychainAndKeys() async throws {
    let child = try await self.childWithComputer()
    let crawlerResponse = CrawlerResponse(
      name: "Khan Academy",
      description: "Free online learning platform",
      domain: "khanacademy.org",
      recommendedKeys: [
        .init(type: "anySubdomain", domain: "khanacademy.org", comment: "main site"),
        .init(type: "domain", domain: "kastatic.org", comment: "CDN"),
      ],
      rejectedDomains: [.init(domain: "google-analytics.com", reason: "tracking")],
      llmFlagged: [],
      warnings: [],
    )

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.logger = .null
      $0.keychainCrawler.validateDomain = { _ in true }
      $0.keychainCrawler.analyze = { _ in crawlerResponse }
      $0.websockets.sendEvent = { self.sent.websocketMessages.append($0) }
    } operation: {
      let output = try await CreateOnboardingKeychain.resolve(
        with: "https://khanacademy.org/",
        in: child.context,
      )
      expect(output).toEqual(.success)
    }

    let keychains = try await Keychain.query()
      .where(.parentId == child.parentId)
      .all(in: self.db)
    let crawlerKeychain = keychains.first { $0.name == "Khan Academy" }
    let kc = try XCTUnwrap(crawlerKeychain)
    expect(kc.description).toEqual("Free online learning platform")
    expect(kc.isPublic).toEqual(false)
    expect(kc.rootDomain).toEqual("khanacademy.org")

    let keys = try await Api.Key.query()
      .where(.keychainId == kc.id)
      .all(in: self.db)
    expect(keys).toHaveCount(2)
    let keyValues: Set<Gertie.Key> = Set(keys.map(\.key))
    XCTAssertTrue(keyValues.contains(.anySubdomain(domain: "khanacademy.org", scope: .webBrowsers)))
    XCTAssertTrue(keyValues.contains(Gertie.Key.domain(
      domain: "kastatic.org",
      scope: .webBrowsers,
    )))

    let childKeychains = try await ChildKeychain.query()
      .where(.childId == child.id)
      .where(.keychainId == kc.id)
      .all(in: self.db)
    expect(childKeychains).toHaveCount(1)

    expect(self.sent.websocketMessages).toHaveCount(1)
    expect(self.sent.websocketMessages[0].message).toEqual(.userUpdated)
    expect(self.sent.websocketMessages[0].matcher).toEqual(.user(child.id))
  }

  func testSkipsInvalidKeyTypes() async throws {
    let child = try await self.childWithComputer()
    let crawlerResponse = CrawlerResponse(
      name: "Test Site",
      description: "A test site",
      domain: "test.com",
      recommendedKeys: [
        .init(type: "anySubdomain", domain: "test.com", comment: nil),
        .init(type: "unknownType", domain: "weird.com", comment: nil),
      ],
      rejectedDomains: [],
      llmFlagged: [],
      warnings: [],
    )

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.logger = .null
      $0.keychainCrawler.validateDomain = { _ in true }
      $0.keychainCrawler.analyze = { _ in crawlerResponse }
      $0.websockets.sendEvent = { self.sent.websocketMessages.append($0) }
    } operation: {
      let output = try await CreateOnboardingKeychain.resolve(
        with: "test.com",
        in: child.context,
      )
      expect(output).toEqual(.success)
    }

    let keychains = try await Keychain.query()
      .where(.parentId == child.parentId)
      .all(in: self.db)
    let kc = keychains.first { $0.name == "Test Site" }!
    let keys = try await Api.Key.query()
      .where(.keychainId == kc.id)
      .all(in: self.db)
    expect(keys).toHaveCount(1)
    expect(keys[0].key).toEqual(Gertie.Key.anySubdomain(domain: "test.com", scope: .webBrowsers))
  }

  func testDoesNotCreateDuplicateKeychainForSameDomain() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(Keychain(
      parentId: child.parentId,
      name: "Khan Academy",
      isPublic: false,
      rootDomain: "khanacademy.org",
    ))

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.logger = .null
      $0.keychainCrawler.validateDomain = { _ in true }
      $0.keychainCrawler.analyze = { _ in
        XCTFail("analyze should not be called for duplicate domain")
        throw CancellationError()
      }
      $0.websockets.sendEvent = { self.sent.websocketMessages.append($0) }
    } operation: {
      let output = try await CreateOnboardingKeychain.resolve(
        with: "khanacademy.org",
        in: child.context,
      )
      expect(output).toEqual(.success)
    }

    let keychains = try await Keychain.query()
      .where(.parentId == child.parentId)
      .where(.rootDomain == "khanacademy.org")
      .all(in: self.db)
    expect(keychains).toHaveCount(1)
    expect(self.sent.websocketMessages).toHaveCount(0)
  }

  func testCrawlerFailureDoesNotCrash() async throws {
    let child = try await self.childWithComputer()

    try await withDependencies {
      $0.db = self.db
      $0.env = .testValue
      $0.logger = .null
      $0.keychainCrawler.validateDomain = { _ in true }
      $0.keychainCrawler.analyze = { _ in throw CancellationError() }
      $0.websockets.sendEvent = { self.sent.websocketMessages.append($0) }
    } operation: {
      let output = try await CreateOnboardingKeychain.resolve(
        with: "example.com",
        in: child.context,
      )
      expect(output).toEqual(.success)
    }

    let keychains = try await Keychain.query()
      .where(.parentId == child.parentId)
      .all(in: self.db)
    expect(keychains.filter { $0.name != "\(child.name)'s Keychain" }).toHaveCount(0)
    expect(self.sent.websocketMessages).toHaveCount(0)
  }
}
