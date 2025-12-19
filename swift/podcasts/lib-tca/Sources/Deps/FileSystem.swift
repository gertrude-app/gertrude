import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct FileSystemClient: Sendable {
  var removeItem: @Sendable (_ at: URL) throws -> Void
  var fileExists: @Sendable (_ at: URL) -> Bool = { _ in true }
}

extension FileSystemClient: DependencyKey {
  static var liveValue: FileSystemClient {
    .init(
      removeItem: { url in
        try FileManager.default.removeItem(at: url)
      },
      fileExists: { url in
        FileManager.default.fileExists(atPath: url.path)
      },
    )
  }

  static var testValue: FileSystemClient {
    .init(
      removeItem: { _ in },
      fileExists: { _ in true },
    )
  }
}

extension DependencyValues {
  var fileSystem: FileSystemClient {
    get { self[FileSystemClient.self] }
    set { self[FileSystemClient.self] = newValue }
  }
}
