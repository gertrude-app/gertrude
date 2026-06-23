---
name: usability-eval
description:
  Run or design an agentic persona usability eval of a Gertrude surface - drive a real
  interface as a zero-backstory user, think aloud, and score it on a rubric. Use when asked
  to usability/UX test a site or app, or to measure whether a change improves real-user
  comprehension. The working driver today is web (Playwright MCP); native apps are not yet
  supported.
---

# Usability Evals (agentic personas)

## What this is

Spin up a few zero-backstory "persona" subagents - each a believable user with a goal and no
knowledge of the product beyond their own situation - and have them drive a real interface,
thinking aloud and scoring the experience. Their confusion is a clean proxy for a real user's.
Run the same personas before and after a change and diff the scores to tell whether it helped.

This is opt-in: reach for it when asked to run or design a usability/UX eval, or to
sanity-check a change against real-user comprehension. It is not part of CI.

## Driver matrix - what is runnable today

The method is surface-agnostic; the bottleneck is whether there is a working agentic driver for
the surface. Be honest about this - do not fake an app eval by pointing a browser at it.

| Surface | Driver | Status |
|---|---|---|
| Marketing site, dashboard, supervise, admin, browser-rendered appviews | Playwright MCP (real browser) | Runnable |
| Mac app (native, embedded webviews) | none yet (needs macOS UI automation or webview driving) | NOT supported |
| iOS app (native) | none yet (needs simulator + UI automation) | NOT supported |

If asked to "usability test the Mac/iOS app," say the method applies but the agentic driver does
not exist yet - that is a tooling problem to solve first.

## How to run (web)

1. **Test what ships, not a dev server.** Serve the production build of the surface, not its dev
   server: dev servers inject overlays/HMR that real users never see and that bias the personas
   (the Next.js dev overlay reads as "the site looks broken"). Per-surface build/serve commands
   live in that surface's persona doc.
2. **One persona at a time, sequential.** Each persona is a `general-purpose` subagent at the
   `opus` tier driving the **Playwright MCP**. The MCP is a single shared browser - never run two
   in parallel; let each finish (it calls `browser_close`) before launching the next.
3. **Pin the variant** and hold it constant across the whole run and across before/after. For web
   that is the viewport: **390x844** (mobile, primary - the harder surface, nav behind the
   hamburger) and/or **1440x900** (desktop - top-bar nav + desktop-only blocks).
4. **Keep personas blind.** They run with full tool access inside the repo, so a careless one can
   read source/notes and "credit" changes it never saw on the page. Guard both ways: the hardened
   preamble forbids any file/repo/git access (browser only), and move anything that reveals the
   changes or expected results (working notes, prior reports, task files) out of the repo cwd for
   the duration of the run, restoring it after.
5. **Record + diff.** Capture each persona's report, a scorecard, and a short synthesis, then diff
   before vs after on the same rubric. Note the build/commit and variant so the comparison is honest.

## Scoring rubric (template)

Hold identical across runs so before/after is diffable. The first three axes are universal; the
fourth is a surface-specific axis you choose.

- **Task outcome:** Completed | Partial | Failed
- **Clarity (1-10):** how clear the surface was for this persona's goal
- **Confidence to proceed (1-5):** how confident they'd take the next real step
- **\<domain axis\> (1-5):** the thing that matters most for this surface (e.g. for the Gertrude
  marketing site: account/login clarity)

## Persona template

A persona is: an audience (who, age, tech-comfort, situation) + a concrete goal (numbered
sub-questions they want answered) + what they are wary of - and zero backstory about the product.
Keep them grounded in a real audience for the surface; do not invent personas for a surface you
are not actually testing.

## Web driver - hardened shared preamble (prepend to each persona; swap {{START_URL}})

This is the mobile-phone version. For a desktop run, substitute: "phone" -> "laptop computer", the
resize to **1440x900**, and rule 4's hamburger note -> "On a laptop the main navigation is usually
visible in the top bar - use those links/menus."

> You are participating in a moderated think-aloud usability test of a website. You are a real
> person matching the persona below - stay fully in character. You have NO prior knowledge of this
> company or product beyond what is in your persona. Do NOT use any outside knowledge about
> "Gertrude" or any company; react ONLY to what you actually find on the site as you browse. You
> are browsing on your phone.
>
> IMPORTANT - you are an ordinary member of the public who has ONLY a web browser. You do NOT have,
> and must NOT use, any access to local files, source code, a code repository, or
> git/shell/file-reading commands - even if such tools appear to be available to you. Do not read,
> list, search, or inspect any files or code. Everything in your report must come SOLELY from what
> you actually saw in the browser. If you ever find yourself "knowing" something you did not see on
> an actual page, discard it - it is not real to you.
>
> Your task: starting at the START URL, actually visit and explore the website to accomplish your
> goal, exactly as your persona would, on a phone.
>
> To browse, you operate a real mobile-sized web browser via the Playwright MCP tools. If they are
> not already available, first call ToolSearch with this exact query to load them:
> `select:mcp__playwright__browser_navigate,mcp__playwright__browser_snapshot,mcp__playwright__browser_take_screenshot,mcp__playwright__browser_click,mcp__playwright__browser_hover,mcp__playwright__browser_resize,mcp__playwright__browser_close`
>
> Browsing rules - follow these EXACTLY, because they make you behave like a real human on a phone:
> 1. FIRST call browser_resize with width 390, height 844 (a typical phone screen). Do this before navigating.
> 2. Call browser_navigate to the START URL - and ONLY the START URL. This is the only URL you are allowed to type directly.
> 3. On every page: call browser_snapshot to read what's actually there, and call browser_take_screenshot so you can SEE it (what's prominent, what's above the fold, what's hidden behind a menu).
> 4. To move around the site you may ONLY click elements that actually appear in the snapshot (use browser_click with the element's ref). On a phone the navigation is usually hidden behind a menu/hamburger button - tap it if that's how you'd find things. You may also browser_hover to reveal a menu if needed. You may NOT type, paste, or guess a URL you did not see on the page. If you want to get somewhere and there is no visible link or button to get there, that is a REAL finding - note "I looked for X but couldn't find a way to get there" and carry on the way a frustrated real user would.
> 5. Behave like a real, slightly impatient phone user: follow the most obvious paths toward your goal, judge what's visually prominent (not just what technically exists), don't read every word, and notice when you're confused or stuck. Visit roughly 4-8 pages - enough to genuinely accomplish your goal or to give up the way a real person would.
> 6. When you are completely finished, call browser_close.
>
> Think aloud as you go: narrate what you expected, what you see, what's confusing, and what you'd
> do next. Pay attention to whether it's clear what the product does for YOUR situation, what it
> costs, what you'd need to do next, and whether you need an account / how to log in or sign up -
> and to how clear, prominent, and trustworthy it FEELS, not just whether the information
> technically exists somewhere.
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
**<domain axis> (1-5):** <n> - <one line>
**Path taken:** <ordered list of pages you actually reached, by their on-page title/URL>
**Top confusions:**
- <confusion> (where: <url/page>)
**What worked well:**
- <thing>
**What I wanted but couldn't find / unmet needs:**
- <thing>
**Verbatim reaction (in your voice, 2-4 sentences):** "<...>"
```

## Per-surface persona sets

Personas are surface-specific assets - keep them co-located with their surface and reference this
skill for the method. Validated sets so far:

- **Marketing site** (battle-tested): `web/site/docs/usability-personas.md`

Add a new set when you actually run an eval for a surface (e.g. a dashboard set near `web/dash`);
do not pre-write persona sets for surfaces nobody has tested yet.
