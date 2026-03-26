import Dependencies
import Foundation
import MacAppRoute
import Vapor

extension CreateSignedScreenshotUpload_v2: Resolver {
  static func resolve(with input: Input, in context: MacApp.ChildContext) async throws -> Output {
    try await createSignedScreenshotUpload(input: input, isPublicRead: false, in: context)
  }
}

func createSignedScreenshotUpload(
  input: CreateSignedScreenshotUpload_v2.Input,
  isPublicRead: Bool,
  in context: MacApp.ChildContext,
) async throws -> CreateSignedScreenshotUpload_v2.Output {
  let computerUser = try await context.computerUser()
  let unixTime = Int(Date().timeIntervalSince1970)
  let filename = "\(unixTime)--\(context.uuid().lowercased).jpg"
  let filepath = "\(computerUser.id.lowercased)/\(filename)"
  let dir = "\(context.env.mode == .prod ? "" : "\(context.env.mode)-")screenshots"
  let objectName = "\(dir)/\(filepath)"
  let webUrlString = "\(context.env.s3.bucketUrl)/\(objectName)"

  let aws = with(dependency: \.aws)
  let uploadUrl = try aws.signedS3UploadUrl(objectName, isPublicRead: isPublicRead)

  try await context.db.create(Screenshot(
    computerUserId: computerUser.id,
    url: webUrlString,
    width: input.width,
    height: input.height,
    filterSuspended: input.filterSuspended ?? false,
    createdAt: input.createdAt ?? get(dependency: \.date.now),
  ))

  return .init(uploadUrl: uploadUrl)
}
