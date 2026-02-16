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
      .where(.deviceId == input.vendorId)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    guard !events.isEmpty else {
      throw Abort(.notFound)
    }

    let firstLaunch = events.first { $0.eventId == "8d35f043" }
    let reachedOptOut = events.contains { $0.eventId == "cdb31095" }
    let modelIdentifier = firstLaunch?.modelIdentifier ?? events.first?.modelIdentifier ?? "Unknown"
    let deviceType = ModelIdentifier.deviceType(from: modelIdentifier)
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

    // --- Launch & Lifecycle ---
    case "8d35f043": "🚀 First launch"
    case "7a539f70": "Onboarding needed on launch"
    case "00ec3909": "Filter started"
    case "8e23bea2": "Filter stopped"
    case "118d259f": "Sheet dismissed"
    // --- Happy Path Onboarding ---
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
    case "5dcaa641": #"Install With Passcode → "Next""#
    case "47bee21e": #"Pre-Install Warning → "Got it, next""#
    case "62b6a262": #"Connect Account? → "No thanks""#
    case "b93bb543": #"Connect Account? → "Connect""#
    case "f4986227": #"Connect Account? → "Tell me more""#
    case "0d00951c": #"Explain Account Connect → "Back""#
    case "63d34e4c": #"Connect Success → "Next""#
    case "cdb31095": "✓ Block Groups → Continue (SUCCESS)"
    case "02976f9b": "Block group toggled"
    // --- Post-Onboarding ---
    case "8a8a3033": #"Clear Cache? → "Yes""#
    case "1221f1a3": #"Clear Cache? → "Skip""#
    case "f9f2e206": #"Cache Cleared → "Next""#
    case "72dc8e84": #"Battery Warning → "Next""#
    case "4fc0b1bf": #"Rate App? → "Rate""#
    case "a9480aa2": #"Rate App? → "Leave a review""#
    case "0dddc87c": #"Rate App? → "No thanks""#
    // --- 18+ / Major Path ---
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
    case "b4e7f219": #"MDM Supervision Explainer → "Next""#
    // --- Apple Family Setup ---
    case "97a57eb2": #"Family Required → "Next""#
    case "2badbcb8": #"Family Setup Easy → "Next""#
    case "07cac029": #"Check In Apple Family? → "Yes, in a family""#
    case "b311a78a": #"Check In Apple Family? → "Not in a family yet""#
    case "548e81b6": #"How To Setup Family → "Done, continue""#
    case "1c495932": #"What Is Apple Family? → "Next""#
    // --- Old Supervision (Configurator/Erase, legacy) ---
    case "ad77fbb6": #"Supervision Intro → "Continue""#
    case "896bc216": "Supervision Explain → needs friend w/ Mac"
    case "25a77e6a": "Supervision Explain → has Mac access"
    case "0c5bdbdd": #"Need Friend With Mac → "OK""#
    case "d858eaf8": #"Need Friend With Mac → "Don't have one""#
    case "dc1521e6": #"Requires Erase & Setup → "OK""#
    case "bee80538": #"Requires Erase & Setup → "No way""#
    case "f3b3f3b6": #"Sorry No Other Way → "Start over""#
    // --- New Supervision Setup Flow ---
    case "261ba66b": #"Explain Supervision → "Next""#
    case "a0f78c2c": #"Cost & Branch → "Continue with Gertrude""#
    case "7023c325": #"Cost & Branch → "Free alternatives""#
    case "422d0980": #"Free Alternatives → "Birthday""#
    case "a5229ef2": #"Free Alternatives → "Sibling""#
    case "ed672bfe": #"Free Alternatives → "Apple Configurator""#
    case "7bbba656": #"Free Alternatives → "Gertrude""#
    case "4c9db46e": #"Birthday Explain → "What are the downsides?""#
    case "359543af": #"Birthday Explain → "Back to alternatives""#
    case "d567937a": #"Birthday Cons → "Continue""#
    case "b1c2d3e4": #"Birthday Cons → "Back to alternatives""#
    case "a6b17fd9": #"Birthday Instructions → "Account now under 18""#
    case "5cdeb42b": #"Sibling Explain → "What are the downsides?""#
    case "8c2ed1a5": #"Sibling Explain → "Back to alternatives""#
    case "f3a1b2c4": #"Sibling Cons → "Continue""#
    case "d4e5f6a7": #"Sibling Cons → "Back to alternatives""#
    case "e5f6a7b8": #"Sibling Instructions → "Account now under 18""#
    case "b7c8d9e0": #"Account Now Under 18 → "Continue""#
    case "c6d7e8f9": #"Apple Configurator Explain → "What are the downsides?""#
    case "a0b1c2d3": #"Apple Configurator Explain → "Back to alternatives""#
    case "e4f5a6b7": #"Apple Configurator Cons → "Next""#
    case "c8d9e0f1": #"Apple Configurator Cons → "Back to alternatives""#
    case "39d56d1a": #"Need Someone Else → "Got it, no problem""#
    case "f0a2d33c": #"Need Someone Else → "Self management""#
    case "84555fc8": #"Self Management → "Continue""#
    case "b530239d": "Generate Code → retry"
    case "0aea6b12": #"Instructions for Protector → "Continue""#
    case "65dc5864": "Waiting for Supervision (no-op)"
    case "fcba8692": "✓ Supervision code generated"
    case "498796d3": "✗ Supervision code generation failed"
    // --- Supervision Resume / Profile Install Flow ---
    case "ad87c533": #"Code Not Claimed → "Continue""#
    case "f2729c3c": #"Claimed Not Supervised → "Install profile""#
    case "36d7be7c": #"Claimed Not Supervised → "Retry supervision""#
    case "d664b520": #"Retry Supervision → "Continue""#
    case "00b0c478": "⚠ Unreachable: missing supervision code"
    case "4693f615": #"Profile Removed Recovery → "Install""#
    case "7b5b4726": #"Prompt Install Profile → "Next""#
    case "0cc9747d": #"Explain Profile Download → "Got it""#
    case "f2e0454e": "Installing Profile → Safari dismissed"
    case "c179832d": #"Profile Downloaded → "Continue""#
    case "a1d3f8b2": #"Profile Not Removable → "Continue""#
    case "ee2f2b76": #"Explain Profile Install → "Done, continue""#
    case "d0d44fe4": #"Verifying Profile Install → "Retry""#
    case "a7e31b8f": "✓ Filter verified (profile installed)"
    case "c4d92e1a": "✗ Filter verification failed"
    case "4af7783e": #"Profile Installed → "Next""#
    case "8aa4790f": #"Website Password Warning → "Got it""#
    case "acfc7894": #"Prompt Clear Cache (supervision) → "Yes""#
    case "7d8b61d0": #"Prompt Clear Cache (supervision) → "Skip""#
    case "6ed43005": #"Setup Complete → "Done""#
    case "be1c3c10": #"Network Error (supervision) → "Retry""#
    // --- Supervision Boot-Up Detection ---
    case "e9b86e6b": "Supervision reboot: code not claimed"
    case "80580cd5": "Supervision reboot: claimed not supervised"
    case "0b15e23f": "Supervision reboot: code expired/not found"
    case "05a47c3a": "Supervision reboot: needs profile"
    case "94991de7": "⚠ Supervision reboot: state disagreement"
    case "4f22bd20": "Profile removed recovery (supervised)"
    case "b7f3a2d1": "✗ Supervision reboot: network error"
    // --- Server-Side Supervision Events ---
    case "f2c3863b": "🔗 Dash: supervision code claimed"
    case "7d644b4d": "⬇ Dash: supervision tool downloaded"
    case "3b8f1e2c": "🔑 Supervision tool: code entered"
    case "86af13a9": "🔌 Supervision tool: device connected"
    case "016d03db": "Supervision tool event"
    case "09748184": "✓ Supervision verified"
    case "1c6f6ca8": "✓ Supervision profile installed confirmed"
    case "80451da8": "✓ Self-reported supervision"
    case "df3914fa": "✗ Supervision failed"
    case "d3b4f6e2": "⚠ Unexpected: mark profile w/o supervision"
    case "f9797be9": "⚠ Unreachable: self-report supervision"
    // --- Configurator Supervision ---
    case "bad8adcc": "🎉 Supervision success first launch"
    case "aa563df6": #"Supervision Success → "Next""#
    // --- Auth Outcomes (programmatic) ---
    case "4a0c585f": "✓ Authorization succeeded"
    case "e2e02460": "✗ Authorization failed"
    case "adced334": "✓ Filter install succeeded"
    case "004d0d89": "✗ Filter install failed"
    case "021834f6": "✓ Auth succeeded"
    case "e30624c6": "⚠ Auth succeeded (unexpected screen)"
    case "fa49f256": "⚠ Auth failed (unexpected screen)"
    case "2bcf3d96": "⚠ Auth failed: invalid account (18+)"
    case "e220a765": "⚠ Auth failed: canceled"
    case "6f0a66e4": "⚠ Auth failed: restricted"
    case "24220209": "⚠ Auth failed: conflict"
    case "104a7ef6": "⚠ Auth failed: network error"
    case "d2e2ee7c": "⚠ Auth failed: passcode required"
    case "f4ed05fd": "⚠ Auth failed: unexpected error"
    case "0dc1632a": "✗ Install failed: permission denied"
    case "321558ed": "✗ Install failed: other error"
    case "421d373b": "✓ Install succeeded"
    case "c98b9525": "⚠ Install succeeded (unexpected screen)"
    case "93958bd1": "⚠ Install failed (unexpected screen)"
    case "d9dfd021": "✗ Auth failed"
    // --- Auth Failure Screens ---
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
    // --- Cache Clearing ---
    case "ea3f9c37": "⏳ Starting cache clear..."
    case "cb9cf096": "✓ Cache cleared"
    case "ae941213": "✗ Error creating cache fill dir"
    // --- Recovery Mode ---
    case "a8998540": "Entering recovery mode"
    case "bcca235f": "⚠ Rules missing in recovery mode"
    case "2c3a4481": "✗ Failed to fetch defaults in recovery mode"
    case "59d3c6d1": "⚠ UNEXPECTED no stored disabled block groups"
    case "aeaa467d": "Received retry directive"
    case "e81796af": "⚠ UNEXPECTED (info feature)"
    // --- Migrations ---
    case "5258e97c": "Migration performed (app)"
    case "99bacaaa": "Migration performed (controller)"
    case "7d1ec86d": "Migrated v1 account connection"
    case "edd6e55f": "Migrated v1.3.x → 1.5.x"
    case "c732e0ab": "Migrated v1.1.x → 1.5.x"
    case "fdab6cff": "✗ Unexpected migration error"
    case "8d4a445b": "✗ Error migrating v1.1.x → 1.5.x"
    // --- Warnings & Misc ---
    case "23c207e2": "⚠ Non-running filter w/ stored groups"
    case "d9e93a4b": "⚠ No vendor id on opt out"
    case "ffff30ac": "⚠ Missing rules after opt-out"
    case "7c039b10": "⚠ Unhandled button action"
    case "180e2347": "Handling upgrade"
    // --- Legacy (old app versions, no longer emitted) ---
    case "dcd721aa": "🚀 First launch"
    case "d317c73c": "✓ Authorization succeeded"
    case "101c91ea": "✓ Filter install succeeded"
    case "739c08c6": "✗ Filter install failed"
    default: "Unknown: \(eventId)"
    }
  }
}
