public protocol CodeGenerator {
  func write() throws
}

public protocol AggregateCodeGenerator: CodeGenerator {
  var generators: [CodeGenerator] { get }
}

public extension AggregateCodeGenerator {
  func write() throws {
    try generators.write()
  }
}

public extension Sequence<CodeGenerator> {
  func write() throws {
    for element in self {
      try element.write()
    }
  }
}
