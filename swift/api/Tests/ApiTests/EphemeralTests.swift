import XCTest
import XExpect

@testable import Api

class EphemeralTests: DependencyTestCase {
  func testAddingAndRetrievingParentToken() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(parent.id)
    let retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.notExpired(parent.id, claimCode: nil, claimIntent: nil))
    let retrievedAgain = await ephemeral.parentIdFromToken(token)
    expect(retrievedAgain).toEqual(.previouslyRetrieved(
      parent.id,
      claimCode: nil,
      claimIntent: nil,
    ))
  }

  func testParentTokenRoundTripsClaimCodeAndApp() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(
      parent.id,
      claimCode: "123456",
      claimIntent: .podcasts,
    )
    let retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.notExpired(parent.id, claimCode: "123456", claimIntent: .podcasts))
    let retrievedAgain = await ephemeral.parentIdFromToken(token) // <-- claim survives retrieval
    expect(retrievedAgain)
      .toEqual(.previouslyRetrieved(parent.id, claimCode: "123456", claimIntent: .podcasts))
  }

  func testExpiredParentTokenReturnsNil() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(5),
    )
    var retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.expired(parent.id, claimCode: nil, claimIntent: nil))
    // can retrieve expired multiple times
    retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.expired(parent.id, claimCode: nil, claimIntent: nil))
  }

  func testExpiredParentTokenPreservesClaimContext() async {
    let ephemeral = Ephemeral()
    let parent = Parent.mock
    let token = await ephemeral.createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(5),
      claimCode: "123456",
      claimIntent: .podcasts,
    )
    let retrieved = await ephemeral.parentIdFromToken(token)
    expect(retrieved).toEqual(.expired(parent.id, claimCode: "123456", claimIntent: .podcasts))
  }

  func testUnknownParentTokenReturnsNotFound() async {
    let retrieved = await Ephemeral().parentIdFromToken(UUID())
    expect(retrieved).toEqual(.notFound)
  }
}
