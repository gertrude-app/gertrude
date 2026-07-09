import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct DuetModelMacro {}

extension DuetModelMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
  ) throws -> [DeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.diagnose(Diagnostic(node: node, message: DuetModelDiagnostic.notAStruct))
      return []
    }

    let properties = storedProperties(of: structDecl)
    guard properties.contains("id") else {
      context.diagnose(Diagnostic(node: node, message: DuetModelDiagnostic.missingId))
      return []
    }
    guard properties.contains("createdAt") else {
      context.diagnose(Diagnostic(node: node, message: DuetModelDiagnostic.missingCreatedAt))
      return []
    }

    let access = accessPrefix(of: structDecl)
    let typeName = structDecl.name.trimmed.text

    var decls: [DeclSyntax] = []
    decls.append("\(raw: access)typealias Id = Tagged<\(raw: typeName), UUID>")

    let cases = properties.map { "  case \($0)" }.joined(separator: "\n")
    decls.append("""
    \(raw: access)enum CodingKeys: String, CodingKey, CaseIterable, ModelColumns {
    \(raw: cases)
    }
    """)

    return decls
  }
}

extension DuetModelMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext,
  ) throws -> [ExtensionDeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      return []
    }
    guard let args = parseArguments(from: node) else {
      context.diagnose(Diagnostic(node: node, message: DuetModelDiagnostic.invalidArguments))
      return []
    }

    let properties = storedProperties(of: structDecl)
    guard properties.contains("id"), properties.contains("createdAt") else {
      return []
    }

    let access = accessPrefix(of: structDecl)
    let conformance = protocols.isEmpty ? "" : ": Model"

    var values: [String] = []
    for property in properties {
      switch property {
      case "id":
        values.append("      .id: .id(self),")
      case "createdAt" where !args.clientCreatedAt:
        values.append("      .createdAt: .currentTimestamp,")
      case "updatedAt":
        values.append("      .updatedAt: .currentTimestamp,")
      default:
        values.append("      .\(property): self.\(property).postgresData,")
      }
    }

    let ext: DeclSyntax = """
    extension \(type.trimmed)\(raw: conformance) {
      \(raw: access)static let schemaName = "\(raw: args.schema)"
      \(raw: access)static let tableName = "\(raw: args.table)"
      \(raw: access)typealias ColumnName = CodingKeys

      \(raw: access)var insertValues: [ColumnName: Postgres.Data] {
        [
    \(raw: values.joined(separator: "\n"))
        ]
      }
    }
    """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

// MARK: - argument parsing

private struct MacroArguments {
  var schema: String
  var table: String
  var clientCreatedAt: Bool
}

private func parseArguments(from node: AttributeSyntax) -> MacroArguments? {
  guard let args = node.arguments?.as(LabeledExprListSyntax.self) else {
    return nil
  }
  var schema: String?
  var table: String?
  var clientCreatedAt = false
  for arg in args {
    switch arg.label?.text {
    case "schema":
      schema = stringLiteralValue(arg.expression)
    case "table":
      table = stringLiteralValue(arg.expression)
    case "clientCreatedAt":
      clientCreatedAt = arg.expression.as(BooleanLiteralExprSyntax.self)?
        .literal.tokenKind == .keyword(.true)
    default:
      return nil
    }
  }
  guard let schema, let table else {
    return nil
  }
  return MacroArguments(schema: schema, table: table, clientCreatedAt: clientCreatedAt)
}

private func stringLiteralValue(_ expr: ExprSyntax) -> String? {
  guard let literal = expr.as(StringLiteralExprSyntax.self),
        literal.segments.count == 1,
        let segment = literal.segments.first?.as(StringSegmentSyntax.self) else {
    return nil
  }
  return segment.content.text
}

// MARK: - declaration inspection

private func storedProperties(of structDecl: StructDeclSyntax) -> [String] {
  var properties: [String] = []
  for member in structDecl.memberBlock.members {
    guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
    if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
      continue
    }
    for binding in varDecl.bindings {
      if let accessorBlock = binding.accessorBlock {
        switch accessorBlock.accessors {
        case .getter:
          continue
        case .accessors(let accessors):
          let isStored = accessors.allSatisfy {
            $0.accessorSpecifier.tokenKind == .keyword(.willSet)
              || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
          }
          if !isStored { continue }
        }
      }
      guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
      properties.append(pattern.identifier.text)
    }
  }
  return properties
}

private func accessPrefix(of structDecl: StructDeclSyntax) -> String {
  structDecl.modifiers.first(where: {
    $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
  }).map { "\($0.name.text) " } ?? ""
}

// MARK: - diagnostics

enum DuetModelDiagnostic: String, DiagnosticMessage {
  case notAStruct
  case missingId
  case missingCreatedAt
  case invalidArguments

  var severity: DiagnosticSeverity { .error }

  var message: String {
    switch self {
    case .notAStruct:
      "@DuetModel can only be applied to struct declarations"
    case .missingId:
      "@DuetModel requires a stored `id` property"
    case .missingCreatedAt:
      "@DuetModel requires a stored `createdAt` property"
    case .invalidArguments:
      "@DuetModel requires `schema:` and `table:` string literal arguments"
    }
  }

  var diagnosticID: MessageID {
    MessageID(domain: "DuetModelMacro", id: rawValue)
  }
}
