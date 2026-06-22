import ClientInterfaces
import Foundation
import MacAppRoute
import PairQLClient

func authed<T: Pair>(
  _ pair: T.Type,
  _ route: AuthedUserRoute,
  using overrideToken: UUID? = nil,
) async throws -> T.Output {
  let currentToken = await userToken.value
  // NB: prefer overrideToken
  guard let token = overrideToken ?? currentToken else {
    throw ApiClient.Error.missingUserToken
  }
  return try await pairql.call(pair, authed: route, token: token)
}

let pairql = PairQLClient<MacAppRoute>(
  endpoint: { ApiClient.endpoint },
)
