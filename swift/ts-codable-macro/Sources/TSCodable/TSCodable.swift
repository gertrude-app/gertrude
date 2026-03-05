@attached(
  member,
  names: named(_NamedCase),
  named(_TypeScriptDecodeError),
  named(encode(to:)),
  named(init(from:)),
  arbitrary
)
@attached(extension, conformances: Codable)
public macro TSCodable() = #externalMacro(module: "TSCodableMacros", type: "TSCodableMacro")
