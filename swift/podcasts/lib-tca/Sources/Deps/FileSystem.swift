import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct FileSystemClient: Sendable {
  var removeItem: @Sendable (_ at: URL) throws -> Void
  var fileExists: @Sendable (_ at: URL) -> Bool = { _ in true }
  var fileSize: @Sendable (_ at: URL) -> Int64? = { _ in 1 }
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
      fileSize: { url in
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else {
          return nil
        }
        return size.int64Value
      },
    )
  }

  static var testValue: FileSystemClient {
    .init(
      removeItem: { _ in },
      fileExists: { _ in true },
      fileSize: { _ in 1 },
    )
  }
}

extension DependencyValues {
  var fileSystem: FileSystemClient {
    get { self[FileSystemClient.self] }
    set { self[FileSystemClient.self] = newValue }
  }
}
