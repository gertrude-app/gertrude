import Dependencies
import Foundation
import IOSRoute
import Vapor

extension ScreenshotUploadUrl: Resolver {
  static func resolve(
    with input: Input,
    in context: BlockerApp.ChildContext,
  ) async throws -> Output {
    let unixTime = Int(get(dependency: \.date.now).timeIntervalSince1970)
    let filename = "\(unixTime)--\(get(dependency: \.uuid)().lowercased).jpg"
    let filepath = "\(context.device.id.lowercased)/\(filename)"
    let env = get(dependency: \.env)
    let dir = "\(env.mode == .prod ? "" : "\(env.mode)-")ios-screenshots"
    let objectName = "\(dir)/\(filepath)"
    let uploadUrl = try with(dependency: \.aws).signedS3UploadUrl(objectName, isPublicRead: true)
    return .init(uploadUrl: uploadUrl)
  }
}
