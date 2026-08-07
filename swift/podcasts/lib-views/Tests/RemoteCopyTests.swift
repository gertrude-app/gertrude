import Foundation
import Testing

@testable import LibViews

@Test
func `remote copy falls back unless the override has real content`() {
  #expect(remoteCopy(nil, or: "baked in") == "baked in")
  #expect(remoteCopy("", or: "baked in") == "baked in")
  #expect(remoteCopy("  \n\t ", or: "baked in") == "baked in") // can't blank a screen
  #expect(remoteCopy("from server", or: "baked in") == "from server")
  #expect(remoteCopy(" padded ", or: "baked in") == " padded ") // trim decides, never rewrites
}
