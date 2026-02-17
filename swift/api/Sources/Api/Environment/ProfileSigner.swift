import Dependencies
import Foundation
import XSlack
@_spi(CMS) import X509

struct ProfileSigner: Sendable {
  var sign: @Sendable (_ xmlBytes: [UInt8]) throws -> [UInt8]
}

extension ProfileSigner: DependencyKey {
  static var liveValue: ProfileSigner {
    let env = ProcessInfo.processInfo.environment
    guard let certPem = env["PROFILE_SIGNING_CERT_PEM"],
          let keyPem = env["PROFILE_SIGNING_KEY_PEM"],
          let chainPem = env["PROFILE_SIGNING_CHAIN_PEM"],
          let cert = try? Certificate(pemEncoded: certPem),
          let key = try? Certificate.PrivateKey(pemEncoded: keyPem),
          let chain = try? Certificate(pemEncoded: chainPem)
    else {
      return ProfileSigner { xmlBytes in
        if get(dependency: \.env).mode == .prod {
          Task {
            await get(dependency: \.slack)
              .error("Failed to sign iOS profile: missing or invalid signing certs")
          }
        }
        return xmlBytes
      }
    }
    return ProfileSigner { xmlBytes in
      try CMS.sign(
        xmlBytes,
        signatureAlgorithm: .sha256WithRSAEncryption,
        additionalIntermediateCertificates: [chain],
        certificate: cert,
        privateKey: key,
        detached: false,
      )
    }
  }
}

extension DependencyValues {
  var profileSigner: ProfileSigner {
    get { self[ProfileSigner.self] }
    set { self[ProfileSigner.self] = newValue }
  }
}

#if DEBUG
  extension ProfileSigner: TestDependencyKey {
    static var testValue: ProfileSigner {
      .init(sign: { $0 })
    }
  }
#endif
