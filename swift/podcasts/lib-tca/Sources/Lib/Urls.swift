import Foundation

func upgradeToHttps(_ urlString: String) -> String {
  guard urlString.hasPrefix("http://") else { return urlString }
  return "https://" + urlString.dropFirst(7)
}
