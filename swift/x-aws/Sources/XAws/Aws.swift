import Foundation

public enum AWS {
  public struct Client: Sendable {
    public var _signedS3UploadUrl: @Sendable (String, String, Bool) throws -> URL
    public var _signedS3GetUrl: @Sendable (String) throws -> URL

    public init(
      signedS3UploadUrl: @Sendable @escaping (String, String, Bool) throws -> URL,
      signedS3GetUrl: @Sendable @escaping (String) throws -> URL,
    ) {
      self._signedS3UploadUrl = signedS3UploadUrl
      self._signedS3GetUrl = signedS3GetUrl
    }
  }

  public struct Error: Swift.Error, Sendable {
    public let message: String
  }
}

public extension AWS.Client {
  func signedS3UploadUrl(
    _ objectKey: String,
    contentType: String = "image/jpeg",
    isPublicRead: Bool = true,
  ) throws -> URL {
    try self._signedS3UploadUrl(objectKey, contentType, isPublicRead)
  }

  func signedS3GetUrl(_ objectKey: String) throws -> URL {
    try self._signedS3GetUrl(objectKey)
  }
}

public extension AWS.Client {
  static func live(
    accessKeyId: String,
    secretAccessKey: String,
    endpoint: String,
    bucket: String,
  ) -> Self {
    let endpoint = endpoint.replacingOccurrences(of: "https://", with: "")
    return AWS.Client(
      signedS3UploadUrl: { objectKey, contentType, isPublicRead in
        var signedHeaders: [String: String] = [
          "Content-Type": contentType,
        ]
        if isPublicRead {
          signedHeaders["x-amz-acl"] = "public-read"
        }
        let signedUrl = AWS.Request.signedUrl(
          httpVerb: .PUT,
          endpoint: endpoint,
          bucket: bucket,
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          objectKey: objectKey,
          expires: 90,
          signedHeaders: signedHeaders,
        )
        guard let url = URL(string: signedUrl) else {
          throw AWS.Error(message: "Error creating URL")
        }
        return url
      },
      signedS3GetUrl: { objectKey in
        let signedUrl = AWS.Request.signedUrl(
          httpVerb: .GET,
          endpoint: endpoint,
          bucket: bucket,
          accessKeyId: accessKeyId,
          secretAccessKey: secretAccessKey,
          objectKey: objectKey,
          expires: 600,
        )
        guard let url = URL(string: signedUrl) else {
          throw AWS.Error(message: "Error creating URL")
        }
        return url
      },
    )
  }

  static let mock = AWS.Client(
    signedS3UploadUrl: { _, _, _ in URL(string: "/mock-url")! },
    signedS3GetUrl: { _ in URL(string: "/mock-get-url")! },
  )
}
