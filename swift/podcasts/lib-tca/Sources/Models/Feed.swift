import Foundation

struct Feed: Equatable {
  let show: Show.FeedData
  let episodes: [Episode.FeedData]
}
