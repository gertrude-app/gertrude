import Testing

@testable import LibViews

@MainActor
@Test
func packageLoads() {
  _ = GertrudeMusicView()
}

@Test
func onboardingBlurbFallsBackWhenNilOrBlank() {
  let fallback = "hardcoded copy"
  #expect(musicOnboardingBlurb(override: nil, device: "x", fallback: fallback) == fallback)
  #expect(musicOnboardingBlurb(override: "", device: "x", fallback: fallback) == fallback)
  #expect(musicOnboardingBlurb(override: "   \n ", device: "x", fallback: fallback) == fallback)
}

@Test
func onboardingBlurbInterpolatesDevicePlaceholder() {
  let out = musicOnboardingBlurb(
    override: "This is {{device}}. Open this link:",
    device: "Billy’s iPhone",
    fallback: "hardcoded copy",
  )
  #expect(out == "This is Billy’s iPhone. Open this link:")
}

@Test
func onboardingBlurbUsesPlainOverrideWithNoPlaceholder() {
  let out = musicOnboardingBlurb(
    override: "Just $5 a month.",
    device: "iPhone",
    fallback: "hardcoded copy",
  )
  #expect(out == "Just $5 a month.")
}

@Test
func onboardingBlurbFallsBackOnResidualMustache() {
  let fallback = "hardcoded copy"
  // unknown/misspelled placeholder the client can't fill
  #expect(musicOnboardingBlurb(
    override: "Hi {{childName}}, open this:",
    device: "iPhone",
    fallback: fallback,
  ) == fallback)
  // malformed / unbalanced delimiters
  #expect(musicOnboardingBlurb(
    override: "This is {{device}. Open:",
    device: "iPhone",
    fallback: fallback,
  ) == fallback)
}
