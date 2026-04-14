import DuetSQL
import MacAppRoute

extension GetPublicKeychains: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let keychains = try await Keychain.query()
      .where(.isPublic == true)
      .all(in: context.db)
    return keychains.map { keychain in
      PublicKeychain(
        id: keychain.id.rawValue,
        name: keychain.name,
        description: keychain.description,
        warning: keychain.warning,
        brandColor: keychain.brandColor,
      )
    }
  }
}
