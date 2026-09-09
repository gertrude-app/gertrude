import PairQL
import TypeScriptInterop
import Vapor

protocol PairQLTsCodegenRoute: Sendable {
  static var logName: String { get }
  static var sharedAliases: [Config.Alias] { get }
  static var sharedTypes: [(String, Any.Type)] { get }
  static var pairqlPairs: [any Pair.Type] { get }
}

extension PairQLTsCodegenRoute {
  static func generate() throws -> PairQLTsCodegen.Response {
    try PairQLTsCodegen.generate(
      sharedAliases: self.sharedAliases,
      sharedTypes: self.sharedTypes,
      pairqlPairs: self.pairqlPairs,
    )
  }

  @Sendable static func handler(_ request: Request) async throws -> PairQLTsCodegen.Response {
    request.logger.notice("TS codegen: \(self.logName)")
    return try self.generate()
  }
}

enum PairQLTsCodegen {
  struct Response: Content {
    struct Pair: Content {
      let pair: String
      let fetcher: String
    }

    var shared: [String: String]
    var pairs: [String: Pair]
  }

  static func generate(
    sharedAliases: [Config.Alias],
    sharedTypes: [(String, Any.Type)],
    pairqlPairs: [any Pair.Type],
  ) throws -> Response {
    var shared: [String: String] = [:]
    var sharedAliases = sharedAliases
    var config = Config(compact: true, aliasing: sharedAliases)

    for (name, type) in sharedTypes {
      shared[name] = try CodeGen(config: config).declaration(for: type, as: name)
      sharedAliases.append(.init(type, as: name))
      config = .init(compact: true, aliasing: sharedAliases)
    }

    var pairs: [String: Response.Pair] = [:]
    for pairType in pairqlPairs {
      pairs[pairType.name] = try self.ts(for: pairType, with: config)
    }

    return Response(shared: shared, pairs: pairs)
  }

  private static func ts<P: Pair>(
    for type: P.Type,
    with config: Config,
  ) throws -> Response.Pair {
    let codegen = CodeGen(config: config)
    let name = "\(P.self)"
    var pair = try """
    export namespace \(name) {
      \(codegen.declaration(for: P.Input.self, as: "Input"))

      \(codegen.declaration(for: P.Output.self, as: "Output"))
    }
    """

    // pairs that are only typealiases get compacted more
    let pairLines = pair.split(separator: "\n")
    if pairLines.count == 4, pairLines.allSatisfy({ $0.count < 60 }) {
      pair = pairLines.joined(separator: "\n")
    }

    var fetchName = "\(name)".regexReplace("_.*$", "")
    let firstLetter = fetchName.removeFirst()
    let functionName = String(firstLetter).lowercased() + fetchName

    let fetcher = """
    \(functionName) = (input: P.\(name).Input): Promise<Result<P.\(name).Output>> => {
      return this.query<P.\(name).Output>(input, `\(P.name)`, `\(P.auth)`);
    }
    """
    return .init(pair: pair, fetcher: fetcher)
  }
}
