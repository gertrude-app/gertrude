import PairQL

extension GetApprovedMusicLibrary.Output.Track: PairOutput {}

public struct GetApprovedMusicAlbumTracks: Pair {
  public static let auth: ClientAuth = .child

  public struct Input: PairInput {
    public var albumId: String

    public init(albumId: String) {
      self.albumId = albumId
    }
  }

  public typealias Output = [GetApprovedMusicLibrary.Output.Track]
}
