import DuetSQL
import Foundation
import PairQL
import Vapor

struct RequestMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var redirect: String?
  }
}

// resolver

extension RequestMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let postmark = get(dependency: \.postmark)
    let email = input.email.lowercased()
    guard email.isValidEmail else {
      throw Abort(.badRequest)
    }

    let parent = try? await Parent.query()
      .where(.email == .string(email))
      .first(in: context.db)

    guard let parent else {
      try await postmark.send(template: .magicLinkNoAccount(to: email, model: .init()))
      return .success
    }
    context.telemetry.parentId = parent.id

    let token = await with(dependency: \.ephemeral)
      .createParentIdToken(parent.id)
    var url = "\(context.dashboardUrl)/otp/\(token.lowercased)"
    if let redirect = input.redirect {
      var components = URLComponents(string: url)
      components?.queryItems = [URLQueryItem(name: "redirect", value: redirect)]
      url = components?.string ?? url
    }
    try await postmark.send(template: .magicLink(to: email, model: .init(url: url)))
    return .success
  }
}
