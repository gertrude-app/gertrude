import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct TSCodableMacro {}

extension TSCodableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
  ) throws -> [ExtensionDeclSyntax] {
    if protocols.isEmpty { return [] }
    let ext: DeclSyntax = "extension \(type.trimmed): Codable {}"
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension TSCodableMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      context.diagnose(Diagnostic(
        node: node,
        message: TSCodableDiagnostic.notAnEnum,
      ))
      return []
    }

    let cases = extractCases(from: enumDecl)
    let accessLevel = enumDecl.modifiers.first(where: {
      $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
    })?.name.text
    var decls: [DeclSyntax] = []

    decls.append("""
    private struct _NamedCase: Codable {
      var `case`: String
      static func extract(from decoder: Decoder) throws -> String {
        let container = try decoder.singleValueContainer()
        return try container.decode(_NamedCase.self).case
      }
    }
    """)

    decls.append("""
    private struct _TypeScriptDecodeError: Error {
      var message: String
    }
    """)

    for c in cases {
      if case .flattened(let type, let paramNode) = c.kind,
         singleValueEncodingTypes.contains(type) {
        context.diagnose(Diagnostic(
          node: paramNode,
          message: TSCodableDiagnostic.flattenedPrimitive,
        ))
      }
    }

    let hasFlattenedCases = cases.contains { if case .flattened = $0.kind { true } else { false } }
    if hasFlattenedCases {
      decls.append("""
      private enum _CodingKeys: String, CodingKey {
        case `case`
      }
      """)
    }

    for c in cases {
      if case .labeled(let params) = c.kind {
        decls.append(DeclSyntax(stringLiteral: helperStruct(name: c.name, params: params)))
      }
    }

    decls.append(DeclSyntax(stringLiteral: generateEncode(cases: cases, accessLevel: accessLevel)))
    decls.append(DeclSyntax(stringLiteral: generateInit(cases: cases, accessLevel: accessLevel)))

    return decls
  }
}

// MARK: - case extraction

private struct EnumCaseInfo {
  enum Kind {
    case simple
    case labeled([ParamInfo])
    case flattened(type: String, paramNode: Syntax)
  }

  let name: String
  let kind: Kind
}

private struct ParamInfo {
  let label: String
  let type: String
}

private func extractCases(from enumDecl: EnumDeclSyntax) -> [EnumCaseInfo] {
  var result: [EnumCaseInfo] = []
  for member in enumDecl.memberBlock.members {
    guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
    for element in caseDecl.elements {
      let name = element.name.text
      guard let paramClause = element.parameterClause else {
        result.append(EnumCaseInfo(name: name, kind: .simple))
        continue
      }
      let params = Array(paramClause.parameters)
      if params.count == 1,
         let param = params.first,
         param.firstName == nil,
         param.secondName == nil {
        let type = param.type.trimmedDescription
        result.append(EnumCaseInfo(
          name: name,
          kind: .flattened(type: type, paramNode: Syntax(param.type)),
        ))
      } else {
        var labeled: [ParamInfo] = []
        for param in params {
          let label = (param.firstName ?? param.secondName)?.text ?? "_"
          let type = param.type.trimmedDescription
          labeled.append(ParamInfo(label: label, type: type))
        }
        result.append(EnumCaseInfo(name: name, kind: .labeled(labeled)))
      }
    }
  }
  return result
}

// MARK: - helper struct

private func helperStruct(name: String, params: [ParamInfo]) -> String {
  let structName = "_Case\(capitalizeFirst(name))"
  var lines: [String] = []
  lines.append("private struct \(structName): Codable {")
  lines.append("  var `case` = \"\(name)\"")
  for p in params {
    lines.append("  var \(p.label): \(p.type)")
  }
  lines.append("}")
  return lines.joined(separator: "\n")
}

// MARK: - encode

private func generateEncode(cases: [EnumCaseInfo], accessLevel: String?) -> String {
  let prefix = accessLevel.map { "\($0) " } ?? ""
  var lines: [String] = []
  lines.append("\(prefix)func encode(to encoder: Encoder) throws {")
  lines.append("  switch self {")
  for c in cases {
    switch c.kind {
    case .simple:
      lines.append("  case .\(c.name):")
      lines.append("    try _NamedCase(case: \"\(c.name)\").encode(to: encoder)")
    case .labeled(let params):
      let structName = "_Case\(capitalizeFirst(c.name))"
      let bindings = params.map { "let \($0.label)" }.joined(separator: ", ")
      let args = params.map { "\($0.label): \($0.label)" }.joined(separator: ", ")
      lines.append("  case .\(c.name)(\(bindings)):")
      lines.append("    try \(structName)(\(args)).encode(to: encoder)")
    case .flattened:
      lines.append("  case .\(c.name)(let value):")
      lines.append("    var container = encoder.container(keyedBy: _CodingKeys.self)")
      lines.append("    try container.encode(\"\(c.name)\", forKey: .case)")
      lines.append("    try value.encode(to: encoder)")
    }
  }
  lines.append("  }")
  lines.append("}")
  return lines.joined(separator: "\n")
}

// MARK: - init(from:)

private func generateInit(cases: [EnumCaseInfo], accessLevel: String?) -> String {
  let prefix = accessLevel.map { "\($0) " } ?? ""
  var lines: [String] = []
  lines.append("\(prefix)init(from decoder: Decoder) throws {")
  lines.append("  let caseName = try _NamedCase.extract(from: decoder)")
  let needsContainer = cases.contains {
    if case .labeled = $0.kind { true } else { false }
  }
  if needsContainer {
    lines.append("  let container = try decoder.singleValueContainer()")
  }
  lines.append("  switch caseName {")
  for c in cases {
    switch c.kind {
    case .simple:
      lines.append("  case \"\(c.name)\":")
      lines.append("    self = .\(c.name)")
    case .labeled(let params):
      let structName = "_Case\(capitalizeFirst(c.name))"
      let args = params.map { "\($0.label): value.\($0.label)" }
        .joined(separator: ", ")
      lines.append("  case \"\(c.name)\":")
      lines.append("    let value = try container.decode(\(structName).self)")
      lines.append("    self = .\(c.name)(\(args))")
    case .flattened(let type, _):
      lines.append("  case \"\(c.name)\":")
      lines.append("    self = .\(c.name)(try \(type)(from: decoder))")
    }
  }
  lines.append("  default:")
  lines
    .append("    throw _TypeScriptDecodeError(message: \"Unexpected case name: `\\(caseName)`\")")
  lines.append("  }")
  lines.append("}")
  return lines.joined(separator: "\n")
}

// MARK: - helpers

private func capitalizeFirst(_ s: String) -> String {
  s.prefix(1).uppercased() + s.dropFirst()
}

// MARK: - diagnostics

private let singleValueEncodingTypes: Set<String> = [
  "String", "Int", "Int8", "Int16", "Int32", "Int64",
  "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
  "Double", "Float", "Bool", "UUID", "Date", "Data", "URL", "Decimal",
]

enum TSCodableDiagnostic: String, DiagnosticMessage {
  case notAnEnum
  case flattenedPrimitive

  var severity: DiagnosticSeverity { .error }

  var message: String {
    switch self {
    case .notAnEnum:
      "@TSCodable can only be applied to enum declarations"
    case .flattenedPrimitive:
      "single unnamed primitive parameter cannot be flattened; add a label to encode it as a named field"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "TSCodableMacro", id: rawValue)
  }
}
