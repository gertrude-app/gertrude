import DuetSQL
import PairQL
import Vapor

struct IOSDeviceEvents: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var vendorId: UUID
  }

  struct Output: PairOutput {
    var vendorId: UUID
    var deviceType: String
    var iosVersion: String
    var firstLaunch: Date?
    var reachedOptOut: Bool
    var events: [Event]
  }

  struct Event: PairNestable {
    var id: String
    var eventId: String
    var label: String
    var detail: String?
    var createdAt: Date
    var elapsedSeconds: Int?
  }
}

extension IOSDeviceEvents: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let events = try await IOSEvent.query()
      .where(.vendorId == input.vendorId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    guard !events.isEmpty else {
      throw Abort(.notFound)
    }

    let firstLaunch = events.first { $0.eventId == "8d35f043" }
    let reachedOptOut = events.contains { $0.eventId == "cdb31095" }
    let deviceType = firstLaunch?.deviceType ?? events.first?.deviceType ?? "Unknown"
    let iosVersion = firstLaunch?.iosVersion ?? events.first?.iosVersion ?? "Unknown"

    var outputEvents: [Event] = []
    for (index, event) in events.enumerated() {
      let elapsedSeconds: Int?
      if index == 0 {
        elapsedSeconds = nil
      } else {
        let previousEvent = events[index - 1]
        elapsedSeconds = Int(event.createdAt.timeIntervalSince(previousEvent.createdAt))
      }
      outputEvents.append(Event(
        id: event.id.rawValue.uuidString,
        eventId: event.eventId,
        label: Self.eventLabel(for: event.eventId),
        detail: event.detail,
        createdAt: event.createdAt,
        elapsedSeconds: elapsedSeconds,
      ))
    }

    return .init(
      vendorId: input.vendorId,
      deviceType: deviceType,
      iosVersion: iosVersion,
      firstLaunch: firstLaunch?.createdAt,
      reachedOptOut: reachedOptOut,
      events: outputEvents,
    )
  }

  private static func eventLabel(for eventId: String) -> String {
    switch eventId {
    case "8d35f043": "🚀 First launch"
    case "6f97eb1b": #"Hi There → "Get Started""#
    case "762bf9bf": #"Time Expectation → "Next""#
    case "666d5e0f": #"Is This Child's Device? → "Yes""#
    case "30fac4e6": #"Is This Child's Device? → "No, it's mine""#
    case "6bc91c73": #"Only minors/supervised → "Next""#
    case "e17137b0": #"Is Device Minor? → "Yes""#
    case "a21c9040": #"Is Device Minor? → "No, 18+""#
    case "51611498": #"Parent Onboarding? → "Yes, I'm the parent""#
    case "3c4772ad": #"Parent Onboarding? → "No, child is""#
    case "7d0fd46e": #"In Apple Family? → "Yes""#
    case "daa8c7fd": #"In Apple Family? → "No""#
    case "232fb200": #"In Apple Family? → "What's that?""#
    case "6582656c": #"Two Install Steps → "Next""#
    case "5d3a5ba2": #"Auth With Parent Account → "Next""#
    case "87601352": #"Pre-Auth Warning → "Got it, next""#
    case "4a0c585f": "✓ Authorization succeeded"
    case "e2e02460": "✗ Authorization failed"
    case "5dcaa641": #"Install With Passcode → "Next""#
    case "47bee21e": #"Pre-Install Warning → "Got it, next""#
    case "adced334": "✓ Filter install succeeded"
    case "004d0d89": "✗ Filter install failed"
    case "62b6a262": #"Connect Account? → "No thanks""#
    case "b93bb543": #"Connect Account? → "Connect""#
    case "f4986227": #"Connect Account? → "Tell me more""#
    case "0d00951c": #"Explain Account Connect → "Back""#
    case "63d34e4c": #"Connect Success → "Next""#
    case "cdb31095": "✓ Block Groups → Continue (SUCCESS)"
    case "8a8a3033": #"Clear Cache? → "Yes""#
    case "1221f1a3": #"Clear Cache? → "Skip""#
    case "4fc0b1bf": #"Rate App? → "Rate""#
    case "a9480aa2": #"Rate App? → "Leave a review""#
    case "0dddc87c": #"Rate App? → "No thanks""#
    case "02976f9b": "Block group toggled"
    case "085eb5a6": #"18+ Harder But Possible → "Next""#
    case "6d88421b": #"Who's Onboarding? → "Someone else""#
    case "bbc0dac1": #"Who's Onboarding? → "I am (self)""#
    case "e0605ab9": #"Is Helper a Parent? → "Yes""#
    case "db2a8c0b": #"Is Helper a Parent? → "No""#
    case "1ed887e0": #"Fix Account Easy Way → "Done""#
    case "fd166517": #"Fix Account Easy Way → "Another way?""#
    case "605151b9": #"In Apple Family? (18+) → "Yes""#
    case "0fa6bc2a": #"In Apple Family? (18+) → "No""#
    case "d17b9ef6": #"In Apple Family? (18+) → "What's that?""#
    case "62f783e1": #"Explain Apple Family → "Continue""#
    case "219ba991": #"Own a Mac? → "Yes""#
    case "c1f63c92": #"Own a Mac? → "No""#
    case "97a57eb2": #"Family Required → "Next""#
    case "2badbcb8": #"Family Setup Easy → "Next""#
    case "07cac029": #"Check In Apple Family? → "Yes, in a family""#
    case "b311a78a": #"Check In Apple Family? → "Not in a family yet""#
    case "548e81b6": #"How To Setup Family → "Done, continue""#
    case "1c495932": #"What Is Apple Family? → "Next""#
    case "ad77fbb6": #"Supervision Intro → "Continue""#
    case "896bc216": "Supervision Explain → needs friend w/ Mac"
    case "25a77e6a": "Supervision Explain → has Mac access"
    case "0c5bdbdd": #"Need Friend With Mac → "OK""#
    case "d858eaf8": #"Need Friend With Mac → "Don't have one""#
    case "dc1521e6": #"Requires Erase & Setup → "OK""#
    case "bee80538": #"Requires Erase & Setup → "No way""#
    case "f3b3f3b6": #"Sorry No Other Way → "Start over""#
    case "285efafb": #"Invalid Account → "Next""#
    case "e90ff997": #"Invalid: In Family? → "Yes""#
    case "39c52acf": #"Invalid: In Family? → "No""#
    case "a9cbe4fe": #"Invalid: In Family? → "Not sure""#
    case "9d0d9eac": #"Invalid: Is Minor? → "No, it's adult""#
    case "e457cf15": #"Invalid: Is Minor? → "Yes, it's minor""#
    case "b8422c3a": #"Auth Restricted → "Start over""#
    case "7b53bdc0": #"Auth Conflict → "Try again""#
    case "16e57d91": #"Network Error → "Try again""#
    case "d2888470": #"Passcode Required → "Try again""#
    case "6e3b2c93": #"Auth Canceled → "Try again""#
    case "87c5ad82": #"Unexpected Error → "Try again""#
    case "b122af01": #"Install Permission Denied → "Try again""#
    case "cf059547": #"Install Failed → "Try again""#
    case "566a3484": #"Child Onboarding Fail → "Start over""#
    case "2bcf3d96": "⚠ Auth failed: invalid account (18+)"
    case "e220a765": "⚠ Auth failed: canceled"
    case "6f0a66e4": "⚠ Auth failed: restricted"
    case "24220209": "⚠ Auth failed: conflict"
    case "104a7ef6": "⚠ Auth failed: network error"
    case "d2e2ee7c": "⚠ Auth failed: passcode required"
    case "f4ed05fd": "⚠ Auth failed: unexpected error"
    case "021834f6": "✓ Auth succeeded"
    case "e30624c6": "⚠ Auth succeeded (unexpected screen)"
    case "fa49f256": "⚠ Auth failed (unexpected screen)"
    case "0dc1632a": "✗ Install failed: permission denied"
    case "321558ed": "✗ Install failed: other error"
    case "421d373b": "✓ Install succeeded"
    case "c98b9525": "⚠ Install succeeded (unexpected screen)"
    case "93958bd1": "⚠ Install failed (unexpected screen)"
    case "bad8adcc": "🎉 Supervision success first launch"
    case "aa563df6": #"Supervision Success → "Next""#
    case "ea3f9c37": "⏳ Starting cache clear..."
    case "cb9cf096": "✓ Cache cleared"
    case "ae941213": "✗ Error creating cache fill dir"
    case "118d259f": "Sheet dismissed"
    case "5258e97c": "Migration performed"
    case "23c207e2": "⚠ Non-running filter w/ stored groups"
    case "d9e93a4b": "⚠ No vendor id on opt out"
    case "ffff30ac": "⚠ Missing rules after opt-out"
    case "00ec3909": "Filter started"
    case "d9dfd021": "✗ Auth failed"
    case "7c039b10": "⚠ Unhandled button action"
    default: "Unknown: \(eventId)"
    }
  }
}
