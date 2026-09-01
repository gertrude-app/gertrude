import DuetSQL
import XCTest
import XExpect

@testable import Api

final class PrepIOSAppConnectionResolverTests: FixedVerificationCodeApiTestCase,
  @unchecked Sendable {

  func testNewChild_getsMonitoringEnabledByDefault() async throws {
    let parent = try await self.parent()

    try await PrepIOSAppConnection.resolve(
      with: .init(child: .newChild(name: "Susanna")),
      in: parent.context,
    )

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(children).toHaveCount(1)
    let child = children[0]
    expect(child.name).toEqual("Susanna")
    expect(child.keyloggingEnabled).toBeTrue()
    expect(child.screenshotsEnabled).toBeTrue()
  }
}
