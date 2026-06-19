import Foundation
import GertieBlocker
import PairQL

/// v1.5.0 - present
public struct ConnectAccountFeatureFlag: Pair {
  public static let auth: ClientAuth = .none

  public struct Output: PairOutput {
    public var isEnabled: Bool
    public var offerScreenText: String?
    public var offerScreenConnectBtnText: String?
    public var offerScreenSkipBtnText: String?
    public var explainScreenText: String?
    public var connectAccountSheetInfoBlurb: String?
    public var releasedAppStoreVersion: String?

    public init(
      isEnabled: Bool,
      offerScreenText: String? = nil,
      offerScreenConnectBtnText: String? = nil,
      offerScreenSkipBtnText: String? = nil,
      explainScreenText: String? = nil,
      connectAccountSheetInfoBlurb: String? = nil,
      releasedAppStoreVersion: String? = nil,
    ) {
      self.isEnabled = isEnabled
      self.offerScreenText = offerScreenText
      self.offerScreenConnectBtnText = offerScreenConnectBtnText
      self.offerScreenSkipBtnText = offerScreenSkipBtnText
      self.explainScreenText = explainScreenText
      self.connectAccountSheetInfoBlurb = connectAccountSheetInfoBlurb
      self.releasedAppStoreVersion = releasedAppStoreVersion
    }
  }
}
