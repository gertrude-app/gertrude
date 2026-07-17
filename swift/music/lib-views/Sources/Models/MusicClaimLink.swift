import Foundation

struct MusicClaimLink {
  let code: Int

  var codeString: String {
    String(format: "%06d", self.code)
  }

  var displayURL: String {
    "gertrude.app/m/\(self.codeString)"
  }

  var url: URL {
    URL(string: "https://\(self.displayURL)")!
  }
}
