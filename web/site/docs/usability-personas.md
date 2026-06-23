# Marketing Site Usability Personas

The validated persona set for usability evals of the Gertrude marketing site (`web/site`).
For the method - how to run, the rubric, the hardened browser preamble, anti-peek,
before/after diffing - read `.agents/skills/usability-eval/SKILL.md`. This file is the
marketing-site instantiation: the personas, the site-specific run notes, and what these
runs have surfaced.

## Site-specific run notes

- **Build + serve the production bundle** (not `next dev`, whose dev overlay biases
  personas):

  ```bash
  just web build-site                 # static export -> web/site/out
  npx serve web/site/out -l 4555      # the real artifact Cloudflare deploys
  ```

  A Cloudflare branch-preview URL or prod work too; only the marketing content differs.

- `PARENTS_APP_URL` is hardcoded to the real `parents.gertrude.app`, so Log in / Sign up
  land on the real auth pages even when serving locally - the account flow stays faithful.
- **START URL:** the homepage. Let personas navigate from there, so nav findability is
  part of the test.
- **Domain axis (the rubric's 4th score): account/login clarity** - whether it was clear
  if/why they need an account and how to log in or sign up. It is the recurring weak spot
  for this audience.

## When it has paid off

- Caught that "Mac App"-scoped login labeling left a returning user unsure they were in
  the right place; de-gating the auth UI fixed it.
- Showed a new pricing page rescued the multi-device-parent persona (task outcome Partial
  -> Completed) while introducing a "wait, do I need a free account?" contradiction for
  the free-iOS persona - a copy fix we would not have found by eyeballing.
- Confirmed the desktop-only Compare-plans matrix resolves "which plan do I need," which
  the mobile layout (matrix hidden) does not.

## The personas

Each persona is the block below, appended to the shared preamble from the skill.

### P1 - Free iOS seeker (Maria)

You're Maria, 41, not very techy. Your 13-year-old son just got his first iPhone. A friend
mentioned an app called "Gertrude" that can block inappropriate websites and content on an
iPhone, and said it was free. YOUR GOAL: figure out (1) what Gertrude does for an iPhone,
(2) whether it's actually free, (3) what you'd have to do to set it up on your son's
iPhone, and (4) whether you need to create an account. You're a bit wary of signing up for
things you don't need.

### P2 - Mac parent (David)

You're David, 45, comfortable with computers but not a developer. Your 15-year-old
daughter has a MacBook for school and you want to block distracting/inappropriate websites
and limit her internet use on it. YOUR GOAL: figure out (1) whether Gertrude can do this
on a Mac, (2) how it works, (3) what it costs, and (4) how you'd get started.

### P3 - Returning user / log in (Sam)

You're Sam, 38. You started using Gertrude for your family a few months ago. Today you
want to log into your account to adjust some settings. YOUR GOAL: from the website, find
where and how to log into your account. Note how easy or hard the login was to find, and
whether anything made you second-guess whether you were in the right place.

### P4 - Multi-device parent (Priya)

You're Priya, 43. You have two kids - a 12-year-old with an iPhone and a 16-year-old with
a MacBook. You'd love ONE tool (and ideally one account/login) to manage protections on
both. YOUR GOAL: figure out (1) whether Gertrude can protect both an iPhone and a Mac, (2)
whether it's a single account or separate setups per device, (3) what the combined cost
would be, and (4) how you'd get started.

### P5 - Podcast-curious (Tom)

You're Tom, 39. You want a safe, kid-friendly podcast app for your two young kids so they
stop using YouTube. Someone mentioned Gertrude makes one. YOUR GOAL: find Gertrude's
podcast app on the site, and figure out (1) what it is / how it keeps content safe, (2)
what it costs, and (3) how to get it. Note whether you needed an account and whether that
was clear.

## Maintenance

These personas encode Gertrude's audience and current surfaces (the free iOS blocker, the
Mac filter, Gertrude AM podcasts, and the layered Free / Light / Full plans). Update them
as the product changes - e.g. when Gertrude FM / Music ships, or the "Gertrude AM" ->
"Gertrude Podcasts" rename lands - so the eval keeps measuring the real thing. Prefer
adding a persona for a new audience over overloading an existing one. Reuse the wording
byte-identical between the before and after runs so the score diff is real.
