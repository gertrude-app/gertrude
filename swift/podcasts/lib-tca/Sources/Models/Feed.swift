import Foundation

struct Feed: Equatable, Hashable {
  let show: Show.FeedData
  let episodes: [Episode.FeedData]
}
