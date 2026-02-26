import Foundation
import Vapor

public struct TsCodegenCommand: AsyncCommand {
  public struct Signature: CommandSignature {
    @Argument(name: "output-dir", help: "Directory to write per-domain JSON files")
    var outputDir: String
    public init() {}
  }

  public init() {}
  public var help: String { "Generate TypeScript codegen JSON files for each PairQL domain" }

  public func run(using context: CommandContext, signature: Signature) async throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let dir = URL(fileURLWithPath: signature.outputDir)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    for (name, data) in try [
      ("dashboard", encoder.encode(DashboardTsCodegenRoute.generate())),
      ("admin", encoder.encode(AdminTsCodegenRoute.generate())),
      ("supervise", encoder.encode(SuperviseTsCodegenRoute.generate())),
    ] {
      try data.write(to: dir.appendingPathComponent("\(name).json"))
      context.console.print("wrote \(name).json")
    }
  }
}
