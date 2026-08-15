import Foundation
import Gertie
import PairQL
import TypeScriptInterop
import Vapor

enum AccountTsCodegenRoute {
  struct Response: Content {
    struct Pair: Content {
      let pair: String
      let fetcher: String
    }

    var shared: [String: String]
    var pairs: [String: Pair]
  }

  static var sharedTypes: [(String, Any.Type)] {
    [
      ("ServerPqlError", PqlError.self),
      ("SuccessOutput", SuccessOutput.self),
      ("ClientAuth", ClientAuth.self),
      ("PersonRelationship", Child.Relationship.self),
      ("BlockRule", Gertie.BlockRule.self),
    ]
  }

  static var pairqlPairs: [any Pair.Type] {
    [
      AccountLogin.self,
      AccountRequestMagicLink.self,
      AccountLoginMagicLink.self,
      GetPeople.self,
      CreatePerson.self,
      UpdatePersonBasicDetails.self,
      DeletePerson.self,
      GetPersonMacSettings.self,
      GetPersonInstalledMacApps.self,
      UpdatePersonMacMonitoringSettings.self,
      UpdatePersonMacInternetFiltering.self,
      UpdatePersonMacApps.self,
      RequestAccountPublicKeychain.self,
      GetSuspensionRequests.self,
      DecideSuspensionRequest.self,
      GetActivitySummaries.self,
      GetDayActivity.self,
      GetPersonActivitySummaries.self,
      GetPersonDayActivity.self,
      ToggleActivityFlag.self,
      DeleteActivity.self,
    ]
  }

  static func generate() throws -> Response {
    var shared: [String: String] = [:]
    var sharedAliases: [Config.Alias] = [
      .init(NoInput.self, as: "void"),
      .init(Date.self, as: "ISODateString"),
      .init(URL.self, as: "string"),
    ]
    var config = Config(compact: true, aliasing: sharedAliases)

    for (name, type) in self.sharedTypes {
      shared[name] = try CodeGen(config: config).declaration(for: type, as: name)
      sharedAliases.append(.init(type, as: name))
      config = .init(compact: true, aliasing: sharedAliases)
    }

    var pairs: [String: Response.Pair] = [:]
    for pairType in self.pairqlPairs {
      pairs[pairType.name] = try self.ts(for: pairType, with: config)
    }

    return Response(shared: shared, pairs: pairs)
  }

  @Sendable static func handler(_ request: Request) async throws -> Response {
    request.logger.notice("TS codegen: \("Account".green)")
    return try self.generate()
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
