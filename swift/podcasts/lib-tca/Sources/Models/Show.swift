import Foundation
import SharingGRDB

@Table
struct Show: Equatable {
  let id: Int
  let name: String
  let feedURL: String
  let artworkURL: String?
  let showEpisodeArtwork: Bool
  let createdAt: Date
}
