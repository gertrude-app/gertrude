# 010 — Music connection flow trades usability for App Store admission

_Date: 2026-08-06._

## The trade

We knowingly shipped a worse onboarding and account-connection flow for Gertrude Music. It
cannot tell a parent which plan they need, cannot send them anywhere they could buy it,
and leaves a family without entitlement at a dead end that explains almost nothing. Those
are real usability defects, not oversights, and we accepted them on purpose. The
alternative was not shipping on the App Store at all.

Apple rejected Gertrude Music under **Guideline 3.1.1** (purchases must use IAP). An
argument that the app was a 3.1.3(a) reader app was tried and failed — Apple repeated the
rejection. The posture in the code now aims at **3.1.3(f)**, the stand-alone-companion
exemption: a free app may authenticate against a service bought elsewhere, provided the
app-originated flow does not steer the user toward that purchase. Qualifying means the
entire flow the app launches has to complete for an account that has never paid, and has
to end somewhere that sells nothing.

So the flow is deliberately unhelpful at precisely the moments where it would be most
natural to help.

## Why it looks broken

Each of these will read as a bug or an oversight to someone encountering it cold.

**Why does the claim link land on `/login` instead of `/signup`?** The signup page carries
no purchase language and would have been defensible either way. Landing on login is a
framing choice: the flow presents as connecting an existing account rather than acquiring
a customer. The cost is that a genuinely new parent has to notice the signup link in the
blurb.

**Why doesn't the app say "you need a Medium plan"?** Naming the required tier _is_ a
purchase steer, link or no link. The cost is real and specific: most accounts without
Music entitlement are light-tier, meaning they already pay us — their problem is one
upgrade away and we deliberately don't tell them.

**Why doesn't the completed claim land on the device page?** Because the iOS device page's
Music section is itself a plan gate. Deep-linking there would put a paywall at the end of
the app-originated flow, which is the exact funnel that got rejected. The dashboard root
is the nearest neutral destination, which is why the flow ends somewhere so generic.

**Why does the claim succeed for an account that cannot use the product?** Intentionally.
`GetMusicClaimData` no longer consults billing and `ClaimMusicDevice` dropped
`requireGertrudeMusicAccess` from both its fresh and resumed paths. Enforcement lives on
the surfaces that serve the actual paid product — `MusicAuthedRoute`, which gates every
authed music route including catalog search, and
`ParentContext.verifiedChildWithConnectedMusicApp`. Re-adding a check to the claim path
recreates the rejected funnel.

**Why does the unavailable screen offer nothing at all?** No upgrade link, no billing
link, no "ask a parent to subscribe" — any of those is the steer. It also has no retry
button, for an unrelated reason: the screen polls every 5s while visible, so a button
would visibly do nothing when tapped. The Library's "Check again" is the right home for
manual retry.

The known gap this leaves: a light-tier parent connects a child's device and the phone
just says unavailable, with no path forward from either surface. The intended repair is an
external account email to the owner, which Apple's 3.1.3 preamble expressly permits. It
was deferred, not rejected — it needs decisions on transactional-vs-marketing, consent,
and unsubscribe.

## Other non-obvious decisions

**Rejected: showing an empty library instead of the unavailable wall.** It recasts the
paid product as in-app content, which strengthens Apple's 3.1.1 reading, and it
manufactures a funnel — the implied fix ("get a parent to approve albums") is impossible,
since curation is gated too, so the only resolution runs back through the web paywall.

**Route-versioned rather than wire-broken.** `GetMusicAppStatus` v1 is retained as a
delegating shim mapping `.unavailable` back to the legacy `.unpaid(remediationUrl:)`.
Renaming the enum case in place would have broken decode on the ~12 released 0.2.0 clients
and hung them on the claim-code screen. Delete `GetMusicAppStatus.swift` and its test once
those clients have aged out.

**Internal naming is not user-facing copy.** Admin and telemetry labels still read
"subscription required" on purpose — they are staff-facing and more legible that way.
Event IDs are unchanged throughout. Do not neutralize them to match the app copy.

**Ordinary web subscription sales and Apple's own MusicKit subscription offer are
unchanged.** This posture is scoped to the app-originated connection flow; it is not a
general retreat from selling.

**Strategy-level alternatives considered and rejected**, recorded so they are not
re-tread: adding IAP; shipping a small freemium Music tier; the 3.1.3(a) reader-app
argument (tried, failed); relying on 3.1.3(b) multiplatform; relying on US-only
distribution. Gertrude Podcasts was also deliberately not cited to App Review.
