import Foundation

struct ChildScopedDiskJSONCache<Value: Codable & Sendable>: Sendable {
  static func directory(named cacheName: String) -> URL {
    let applicationSupportDirectory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
    ).first ?? FileManager.default.temporaryDirectory

    return applicationSupportDirectory
      .appendingPathComponent("GertrudeMusic", isDirectory: true)
      .appendingPathComponent(cacheName, isDirectory: true)
  }

  let directory: URL
  let version: Int
  let isValid: @Sendable (Value) -> Bool

  init(
    directory: URL,
    version: Int = 1,
    isValid: @escaping @Sendable (Value) -> Bool = { _ in true },
  ) {
    self.directory = directory
    self.version = version
    self.isValid = isValid
  }

  func load(childId: UUID) throws -> Value? {
    let fileURL = self.fileURL(childId: childId)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
    let data = try Data(contentsOf: fileURL)
    guard let envelope = try? JSONDecoder().decode(
      DiskJSONCacheEnvelope<Value>.self,
      from: data,
    ), envelope.version == self.version,
    self.isValid(envelope.value) else {
      return nil
    }
    return envelope.value
  }

  func save(_ value: Value, childId: UUID) throws {
    try FileManager.default.createDirectory(
      at: self.directory,
      withIntermediateDirectories: true,
    )
    let envelope = DiskJSONCacheEnvelope(version: self.version, value: value)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(envelope)
    try data.write(to: self.fileURL(childId: childId), options: [.atomic])
  }

  func delete(childId: UUID) throws {
    let fileURL = self.fileURL(childId: childId)
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
    try FileManager.default.removeItem(at: fileURL)
  }

  func fileURL(childId: UUID) -> URL {
    self.directory.appendingPathComponent(
      "\(childId.uuidString.lowercased()).json",
      isDirectory: false,
    )
  }
}

private struct DiskJSONCacheEnvelope<Value: Codable>: Codable {
  var version: Int
  var value: Value
}
