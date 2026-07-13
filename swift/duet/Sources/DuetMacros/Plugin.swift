import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DuetMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DuetModelMacro.self,
  ]
}
