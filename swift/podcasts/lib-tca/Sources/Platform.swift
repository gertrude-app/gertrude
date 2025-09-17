import AVFoundation
import Foundation
import MediaPlayer

#if !os(iOS)
  struct UIImage {
    init?(data: Data) {}
    var size: CGSize { CGSize(width: 100, height: 100) }
    var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in .init() }
    }

    func jpegData(compressionQuality: CGFloat) -> Data? { nil }
  }

  struct AVAudioSession {
    enum Category { case playback, NOT_REAL_CHECK_XCODE }
    enum Mode { case spokenAudio, NOT_REAL_CHECK_XCODE }

    static func sharedInstance() -> AVAudioSession {
      AVAudioSession()
    }

    func setCategory(_ category: Category) throws {}
    func setMode(_ mode: Mode) throws {}
    func setActive(_ active: Bool) throws {}
  }
#else
  import UIKit

  public typealias UIImage = UIKit.UIImage

  extension UIImage {
    var mediaItemArtwork: MPMediaItemArtwork {
      .init(boundsSize: self.size) { _ in self }
    }
  }

#endif
