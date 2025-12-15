import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct FileSystemClient: Sendable {
  var removeItem: @Sendable (_ at: URL) throws -> Void
}

extension FileSystemClient: DependencyKey {
  static var liveValue: FileSystemClient {
    .init(
      removeItem: { url in
        try FileManager.default.removeItem(at: url)
      },
    )
  }
}

extension DependencyValues {
  var fileSystem: FileSystemClient {
    get { self[FileSystemClient.self] }
    set { self[FileSystemClient.self] = newValue }
  }
}
