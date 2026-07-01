import BlockerRoute
import Vapor

extension SelfReportSupervision: Resolver {
  static func resolve(
    with input: Input,
    in ctx: BlockerApp.ChildContext,
  ) async throws -> Output {
    // self-report only ever caused problems, so removed, now a no-op
    await ctx.db.logDeprecated("SelfReportSupervision")
    return .success
  }
}
