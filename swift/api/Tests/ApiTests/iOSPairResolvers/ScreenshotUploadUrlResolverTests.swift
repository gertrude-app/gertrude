import Dependencies
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class ScreenshotUploadUrlResolverTests: ApiTestCase, @unchecked Sendable {
  func testScreenshotUploadUrl() async throws {
    let child = try await self.childWithIOSDevice()

    let output = try await withDependencies {
      $0.aws._signedS3UploadUrl = { objectName, _, isPublicRead in
        expect(objectName.contains("ios-screenshots")).toEqual(true)
        expect(objectName.contains(child.device.id.lowercased)).toEqual(true)
        expect(isPublicRead).toEqual(true)
        return URL(string: "https://upload.test")!
      }
    } operation: {
      try await ScreenshotUploadUrl.resolve(
        with: .init(width: 111, height: 222, createdAt: .epoch),
        in: child.context,
      )
    }

    expect(output.uploadUrl.absoluteString).toEqual("https://upload.test")
  }
}
