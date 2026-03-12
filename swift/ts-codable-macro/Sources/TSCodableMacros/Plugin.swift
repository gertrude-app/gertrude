import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TSCodablePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    TSCodableMacro.self,
  ]
}
