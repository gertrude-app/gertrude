import XCTest
import XExpect

@testable import Api

final class IosOnlyMacTrialFragmentTests: XCTestCase {
  func testFragment() {
    let cases: [(email: String, kids: [(String, Set<DeviceKind>)], expected: String)] = [
      ("parent@example.com", [("Sarah", [.iPhone])], "Sarah's iPhone"),
      ("parent@example.com", [("Emma", [.iPad])], "Emma's iPad"),
      ("parent@example.com", [("Sam", [.iPhone, .iPad])], "Sam's iPhone and iPad"),
      ("parent@example.com", [("Jussy ", [.iPhone])], "Jussy's iPhone"),
      ("parent@example.com", [("Averi Coll", [.iPhone])], "Averi's iPhone"),
      ("parent@example.com", [("Philip's iPhone", [.iPhone])], "Philip's iPhone"),
      ("parent@example.com", [("Isaiah iPad", [.iPad])], "Isaiah's iPad"),
      ("parent@example.com", [("Jonas iPhone", [.iPhone])], "Jonas' iPhone"),
      ("parent@example.com", [("ryan", [.iPhone])], "Ryan's iPhone"),
      ("parent@example.com", [("James", [.iPhone])], "James' iPhone"),
      ("parent@example.com", [("Jens", [.iPhone])], "Jens' iPhone"),
      ("parent@example.com", [("PEF", [.iPhone])], "your child's iPhone"),
      ("parent@example.com", [("MJ", [.iPhone])], "your child's iPhone"),
      ("parent@example.com", [("Test", [.iPhone])], "your child's iPhone"),
      ("parent@example.com", [("Kid", [.iPad])], "your child's iPad"),
      ("sarah7@example.com", [("Sarah", [.iPhone])], "your iPhone"),
      ("michaelbrown@example.com", [("Michael", [.iPhone])], "your iPhone"),
      ("danieljones@example.com", [("Daniel", [.iPhone, .iPad])], "your iPhone and iPad"),
      // "adam" mid-local → parent's name, not the kid
      ("maryadamsmith@example.com", [("Adam", [.iPhone])], "Adam's iPhone"),
      // self-detect requires >= 4 chars
      ("bobann@example.com", [("Bob", [.iPhone])], "Bob's iPhone"),
      // dedupe: same sanitized name merges devices
      (
        "parent@example.com",
        [("Isaiah", [.iPhone]), ("Isaiah iPad", [.iPad])],
        "Isaiah's iPhone and iPad",
      ),
      (
        "parent@example.com",
        [("Nathaniel", [.iPhone]), ("Isaiah", [.iPhone])],
        "Nathaniel and Isaiah's iPhones",
      ),
      ("parent@example.com", [("Miles", [.iPhone]), ("Lily", [.iPad])], "Miles and Lily's devices"),
      (
        "parent@example.com",
        [("Jane", [.iPhone]), ("Bobby", [.iPhone]), ("Susie", [.iPhone])],
        "Jane, Bobby, and Susie's iPhones",
      ),
      (
        "parent@example.com",
        [
          ("Jane", [.iPad]), ("Joe", [.iPad]), ("Bobby", [.iPad]),
          ("Susie", [.iPad]), ("Billy", [.iPad]),
        ],
        "Jane, Joe, Bobby, Susie, and Billy's iPads",
      ),
      (
        "parent@example.com",
        [("Samantha", [.iPhone]), ("Miles", [.iPhone])],
        "Samantha and Miles' iPhones",
      ),
    ]
    for (email, kids, expected) in cases {
      let actual = iosOnlyMacTrialFragment(
        email: email,
        kids: kids.map { .init(name: $0.0, kinds: $0.1) },
      )
      expect(actual).toEqual(expected)
    }
  }
}
