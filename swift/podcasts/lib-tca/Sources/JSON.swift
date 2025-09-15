import Foundation

enum JSON {
  enum Error: Swift.Error {
    case dataToStringConversionError
    case stringToDataConversionError
  }

  struct EncodeOptions: OptionSet, Sendable {
    let rawValue: Int
    static let isoDates = EncodeOptions(rawValue: 1 << 0)
    static let prettyPrinted = EncodeOptions(rawValue: 2 << 0)
  }

  struct DecodeOptions: OptionSet, Sendable {
    let rawValue: Int
    static let isoDates = DecodeOptions(rawValue: 1 << 0)
  }

  static func decode<T: Decodable>(
    _ json: String,
    as type: T.Type,
    _ options: DecodeOptions = []
  ) throws -> T {
    let decoder = decoder(from: options)
    guard let data = json.data(using: .utf8) else {
      throw Error.stringToDataConversionError
    }
    return try decoder.decode(type, from: data)
  }

  static func decode<T: Decodable>(
    _ data: Data,
    as type: T.Type,
    _ options: DecodeOptions = []
  ) throws -> T {
    let decoder = decoder(from: options)
    return try decoder.decode(type, from: data)
  }

  static func encode(
    _ value: some Encodable,
    _ options: EncodeOptions = []
  ) throws -> String {
    let data = try data(value, options)
    guard let json = String(data: data, encoding: .utf8) else {
      throw Error.dataToStringConversionError
    }
    return json
  }

  static func data(
    _ value: some Encodable,
    _ options: EncodeOptions = []
  ) throws -> Data {
    let encoder = JSONEncoder()
    if options.contains(.isoDates) {
      encoder.dateEncodingStrategy = .iso8601
    }
    if options.contains(.prettyPrinted) {
      encoder.outputFormatting = .prettyPrinted
    }
    return try encoder.encode(value)
  }

  private static func decoder(from options: DecodeOptions) -> JSONDecoder {
    let decoder = JSONDecoder()
    if options.contains(.isoDates) {
      decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
  }
}
