# Marketing Site Usability Evals (agentic personas)

## What this is

A lightweight, repeatable way to pressure-test the marketing site's clarity. Spin up a few
zero-backstory "persona" subagents, each a believable parent with a goal, and have them
drive a real browser through the live site, thinking aloud and scoring the experience.
Because a persona knows nothing about Gertrude beyond its own situation, its confusion is
a clean proxy for a real visitor's. Run the same personas before and after a change (e.g.
against prod, then against a branch build) and diff the scores to see whether the change
actually helped.

This is **opt-in**: reach for it only when asked to run or design a usability/UX eval, or
to sanity-check a marketing-site change against real-user comprehension. It is not part of
CI.

## When it has paid off

- Caught that "Mac App"-scoped login labeling left a returning user unsure they were in
  the right place; de-gating the auth UI fixed it.
- Showed a new pricing page rescued the multi-device-parent persona (task outcome Partial
  -> Completed) while introducing a "wait, do I need a free account?" contradiction for
  the free-iOS persona — a copy fix we would not have found by eyeballing.
- Confirmed the desktop-only Compare-plans matrix resolves "which plan do I need," which
  the mobile layout (matrix hidden) does not.

## How to run

1. **Build and serve the PRODUCTION bundle — not `next dev`.** The dev server paints the
   Next.js dev overlay (the "N" button + an "N Issues" badge) over every page; personas
   read it as "the site looks broken," which depresses trust/clarity and never appears in
   production. The static export has no such overlay.

   ```bash
   just web build-site                 # static export -> web/site/out
   npx serve web/site/out -l 4555      # serve the real artifact (same files Cloudflare deploys)
   ```

   A Cloudflare branch-preview URL or prod work too; only the marketing content differs.
   `PARENTS_APP_URL` is hardcoded to the real `parents.gertrude.app`, so Log in / Sign up
   land on the real auth pages even when serving locally — the account flow stays
   faithful.

2. **Run one persona at a time, sequentially.** Each persona is a `general-purpose`
   subagent at the `opus` tier driving the **Playwright MCP**. The MCP is a single shared
   browser, so never run two in parallel; let each finish (it calls `browser_close`)
   before launching the next.

3. **Pin a viewport** and hold it constant across the whole run and across before/after:

   - Mobile (primary): **390x844** — the audience skews mobile, and the nav lives behind
     the hamburger, the harder surface with the most room to detect change.
   - Desktop (optional): **1440x900** — exercises the top-bar nav and desktop-only blocks
     (e.g. the `hidden md:block` Compare-plans matrix on `/pricing`).

4. **Keep personas blind.** They run with full tool access inside the repo, so a careless
   one can read source/notes and "credit" changes it never saw on the page. Guard both
   ways: the hardened preamble forbids any file/repo/git access (browser only), and move
   anything that reveals the changes or expected results (working notes, prior reports,
   task files) out of the repo cwd for the duration of the run, restoring it after.

5. **Record + diff.** Capture each persona's report, a scorecard, and a short synthesis,
   then diff before vs after on the same rubric. Note the build/commit and viewport so the
   comparison is honest. (Past runs were kept in gitignored `agent.report.eval-*.md` files
   at the repo root.)

## Scoring rubric (hold identical across runs, so before/after is diffable)

- **Task outcome:** Completed | Partial | Failed
- **Clarity (1-10):** how clear the site was for this persona's goal
- **Confidence to proceed (1-5):** how confident they'd take the next real step
- **Account/login clarity (1-5):** was it clear whether/why they need an account + how to
  log in or sign up

## The personas

Each persona is the block below, appended to the shared preamble. They encode Gertrude's
actual audience and surfaces; keep them current (see Maintenance).

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

## Shared preamble (prepend to each persona; swap {{START_URL}} per run)

This is the mobile-phone version. For a desktop run, substitute: "phone" -> "laptop
computer", the resize to **1440x900**, and rule 4's hamburger note -> "On a laptop the
main navigation is usually visible in the top bar - use those links/menus."

> You are participating in a moderated think-aloud usability test of a website. You are a
> real person matching the persona below - stay fully in character. You have NO prior
> knowledge of this company or product beyond what is in your persona. Do NOT use any
> outside knowledge about "Gertrude" or any company; react ONLY to what you actually find
> on the site as you browse. You are browsing on your phone.
>
> IMPORTANT - you are an ordinary member of the public who has ONLY a web browser. You do
> NOT have, and must NOT use, any access to local files, source code, a code repository,
> or git/shell/file-reading commands - even if such tools appear to be available to you.
> Do not read, list, search, or inspect any files or code. Everything in your report must
> come SOLELY from what you actually saw in the browser. If you ever find yourself
> "knowing" something you did not see on an actual page, discard it - it is not real to
> you.
>
> Your task: starting at the START URL, actually visit and explore the website to
> accomplish your goal, exactly as your persona would, on a phone.
>
> To browse, you operate a real mobile-sized web browser via the Playwright MCP tools. If
> they are not already available, first call ToolSearch with this exact query to load
> them:
> `select:mcp__playwright__browser_navigate,mcp__playwright__browser_snapshot,mcp__playwright__browser_take_screenshot,mcp__playwright__browser_click,mcp__playwright__browser_hover,mcp__playwright__browser_resize,mcp__playwright__browser_close`
>
> Browsing rules - follow these EXACTLY, because they make you behave like a real human on
> a phone:
>
> 1. FIRST call browser_resize with width 390, height 844 (a typical phone screen). Do
>    this before navigating.
> 2. Call browser_navigate to the START URL - and ONLY the START URL. This is the only URL
>    you are allowed to type directly.
> 3. On every page: call browser_snapshot to read what's actually there, and call
>    browser_take_screenshot so you can SEE it (what's prominent, what's above the fold,
>    what's hidden behind a menu).
> 4. To move around the site you may ONLY click elements that actually appear in the
>    snapshot (use browser_click with the element's ref). On a phone the navigation is
>    usually hidden behind a menu/hamburger button - tap it if that's how you'd find
>    things. You may also browser_hover to reveal a menu if needed. You may NOT type,
>    paste, or guess a URL you did not see on the page. If you want to get somewhere and
>    there is no visible link or button to get there, that is a REAL finding - note "I
>    looked for X but couldn't find a way to get there" and carry on the way a frustrated
>    real user would.
> 5. Behave like a real, slightly impatient phone user: follow the most obvious paths
>    toward your goal, judge what's visually prominent (not just what technically exists),
>    don't read every word, and notice when you're confused or stuck. Visit roughly 4-8
>    pages - enough to genuinely accomplish your goal or to give up the way a real person
>    would.
> 6. When you are completely finished, call browser_close.
>
> Think aloud as you go: narrate what you expected, what you see, what's confusing, and
> what you'd do next. Pay attention to whether it's clear what the product does for YOUR
> situation, what it costs, what you'd need to do next, and whether you need an account /
> how to log in or sign up - and to how clear, prominent, and trustworthy it FEELS, not
> just whether the information technically exists somewhere.
>
> START URL: {{START_URL}}
>
> [persona block here]
>
> [report format here]

## Report format (each persona returns ONLY this)

```
### Persona: <name>
**Task outcome:** Completed | Partial | Failed - <one line why>
**Clarity score (1-10):** <n> - <one line>
**Confidence to proceed (1-5):** <n>
**Account/login clarity (1-5):** <n> - <one line>
**Path taken:** <ordered list of pages you actually reached, by their on-page title/URL>
**Top confusions:**
- <confusion> (where: <url/page>)
**What worked well:**
- <thing>
**What I wanted but couldn't find / unmet needs:**
- <thing>
**Verbatim reaction (in your voice, 2-4 sentences):** "<...>"
```

## Maintenance

These personas encode Gertrude's audience and current surfaces (the free iOS blocker, the
Mac filter, Gertrude AM podcasts, and the layered Free / Light / Full plans). Update them
as the product changes - e.g. when Gertrude FM / Music ships, or the "Gertrude AM" ->
"Gertrude Podcasts" rename lands - so the eval keeps measuring the real thing. Prefer
adding a persona for a new audience over overloading an existing one. Treat the wording as
canonical: reuse it byte-identical between the before and after runs so the score diff is
real.
