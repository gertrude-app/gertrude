import Testing

@testable import Api

@Test
func `infer new ratings by diffing snapshots`() {
  let cases: [(RatingSnapshot, RatingSnapshot, InferredRating?)] = [
    (
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 5),
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 5),
      nil,
    ),
    (
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 5),
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 6),
      nil,
    ),
    (
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 5),
      RatingSnapshot(averageRating: 4.1, totalCount: 11, reviewCount: 5),
      InferredRating(count: 1, stars: 5.1),
    ),
    (
      RatingSnapshot(averageRating: 4.855, totalCount: 75, reviewCount: 22),
      RatingSnapshot(averageRating: 4.856, totalCount: 76, reviewCount: 22),
      InferredRating(count: 1, stars: 4.931),
    ),
    (
      RatingSnapshot(averageRating: 5.0, totalCount: 4, reviewCount: 4),
      RatingSnapshot(averageRating: 4.8, totalCount: 5, reviewCount: 4),
      InferredRating(count: 1, stars: 4.0),
    ),
    (
      RatingSnapshot(averageRating: 4.0, totalCount: 10, reviewCount: 5),
      RatingSnapshot(averageRating: 3.5, totalCount: 12, reviewCount: 5),
      InferredRating(count: 2, stars: 1.0),
    ),
    (
      RatingSnapshot(averageRating: 4.5, totalCount: 100, reviewCount: 50),
      RatingSnapshot(averageRating: 4.55, totalCount: 110, reviewCount: 50),
      InferredRating(count: 10, stars: 5.05),
    ),
  ]

  for (prev, new, expected) in cases {
    let result = Api.inferRatingOnlySubmissions(prev: prev, new: new)
    if let expected {
      #expect(result != nil, "Expected non-nil result for prev=\(prev), new=\(new)")
      if let result {
        #expect(result.count == expected.count)
        #expect(abs(result.stars - expected.stars) < 0.001)
      }
    } else {
      #expect(result == nil, "Expected nil result for prev=\(prev), new=\(new)")
    }
  }
}
