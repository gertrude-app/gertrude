---
title: The One Thing That Can Break Gertrude's Mac Filter
date: '2026-01-08T12:00:00.000Z'
description:
  "If Apple's Screen Time web content filtering is enabled on your child's Mac alongside
  Gertrude, the Gertrude filter can stop working. Here's how to fix it."
category: mac
---

I built the Gertrude Mac app originally to protect my own kids, and I've always been
pretty intense—maybe even a little nutty—about safety and security. After five years and
many families using Gertrude, the only failure mode I know of that can actually cause kids
to be exposed to parts of the internet their parents don't want them to see is a _conflict
with Screen Time's web filtering_ on the Mac.

## What's happening

Apple's Screen Time includes its own web content filter. When both Screen Time's web
filter and Gertrude are running on the same Mac, Screen Time seems to take priority. This
means Gertrude's filter gets bypassed—websites that should be blocked slip right through,
even though Gertrude appears to be running normally. We've observed that sometimes this
filter failure only affects non-Safari browsers, like Chrome or Firefox, while Safari
seems to remain blocked (by either Gertrude or Screen Time).

## How to fix it

You just need to disable Screen Time's Content & Privacy on the Mac.

### Step 1: Open System Settings &rarr; Screen Time

On your child's Mac, open **System Settings**, click on **Screen Time** in the sidebar,
then _click_ the section labeled **Restrictions**.

{% image src="mac-screentime-restrictions.jpg" caption="Go to System Settings -> Screen Time -> Restrictions" alt="Open System Settings, click Screen Time, then Content & Privacy" /%}

### Step 2: Disable Content & Privacy

Toggle off completely the setting labeled **Content & Privacy**.

{% image src="mac-screentime-disable.jpg" alt="Disable Content & Privacy in Screen Time" caption="Toggle off Content & Privacy to prevent the conflict with Gertrude" /%}

That's it. Gertrude's filter will now work correctly.

{% callout title="Two important things to know" %}

1. **You do NOT need to disable ALL of Screen Time**—only the Content & Privacy section.
   You can keep using Screen Time for app limits, downtime, and other features.

2. **This only affects Macs.** You do NOT need to change any Screen Time settings on your
   kids' iPhones or iPads.

{% /callout %}

## How to verify it's working

After making the change, try visiting a blocked website in Chrome or another non-Safari
browser. If it's blocked, you're all set.

## Questions?

[Reach out here](/contact) and we'll get back to you quickly.
