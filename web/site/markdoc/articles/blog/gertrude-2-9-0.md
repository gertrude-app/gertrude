---
title: Gertrude 2.9.0 Released
date: '2026-04-21T12:00:00.000Z'
description:
  'Today we are releasing Gertrude v2.9.0 - our biggest single update to our flagship Mac
  app ever. It includes new features like unfiltered-mode and always-blocked items,
  screenshot privacy enhancements, a major performance improvement, fixes for non-Safari
  browsers, and a substantially more full-featured setup wizard.'
category: mac
---

{% .lead .mb-12 %} Today we are releasing Gertrude `v2.9.0` - our biggest single update to
our flagship Mac app ever. It includes new features like _unfiltered-mode_ and
_always-blocked_ items, screenshot privacy enhancements, a major performance improvement,
fixes for non-Safari browsers, and a substantially more full-featured setup wizard.

## {% new-feature /%} Unfiltered Internet Mode

The vast majority of Gertrude mac users want the internet to be filtered. But a small but
important subset of users want all of the monitoring, oversight and accountability that
Gertrude can provide, without actually blocking the internet. This often makes a lot of
sense for older teens, or adults in accountability relationships.

Before this version, this setup was technically possible to achieve, but really difficult.
Now it's a first-class option you can enable if this makes sense for the loved-one you're
protecting.

{% image src="unfiltered-mode.png" caption="Turning off internet filtering still leaves screenshots and keylogging in place" alt="Filtering card in the dashboard with the 'Filter internet access' toggle switched off, showing a warning that Harriet has unrestricted internet access and is only protected by screenshots and keylogging" /%}

If you have internet filtering disabled, you still get tons of really great safety
guarantees from Gertrude, like:

1. Screenshots and keystroke logging continue
2. If screenshots or keystroke logging ever stop for an unexpected reason, all internet
   will be blocked.
3. Security events are emitted (you can subscribe to notifications for these) when unusual
   or possibly unsafe events occur.
4. **Always-Blocked** items (see below) are still blocked by the filter allowing you to
   still restrict access to certain apps and sites.
5. Any blocked apps are still unusable, even with filtering disabled.

## {% new-feature /%} Always-Blocked

Several times over the years I've gotten an email from a parent asking:

> Does the Gertrude Mac app block the `#images` GIF search in Messages?

(Blocking animated GIF search inside Apple's texting app is probably the most popular
feature of our [iPhone and iPad app](/iphone-and-ipad). The same dangerous feature exists
on the Mac version of the texting app _Messages_.)

The answer I always had to give was:

> Yup! ...Except when your child is on a filter suspension, then all bets are off.

I always hated saying the second part&mdash;it made me realize there was a **missing
feature** here: there are some things that we want **always to be blocked** even when the
filter is suspended. Gertrude `v2.9.0` adds this option. You can now choose some things
that will **always be blocked,** even during filter suspensions.

{% image src="always-blocked-groups.png" caption="Opt into curated always-blocked groups from the parent dashboard" alt="Always-Blocked groups dashboard panel with four toggle cards: Adult content (blocked), Messages GIF Search (blocked), Social media (not blocked), and Spotlight search (blocked), each with a short description and a help icon" /%}

We start by giving you 4 basic groups of blocks, that you can opt into:

1. animated GIF `#images` search in Messages mac app
2. top adult/porn sites, including all `.xxx`, `.porn`, and `.sex` sites
3. spotlight image/web searches
4. top social media sites (Facebook, Instagram, Twitter/X, TikTok, Snapchat, Pinterest)

You can also create your own custom always-block rules. This can be especially helpful if
you have kids who sometimes are tempted to go to certain websites when on filter
suspensions.

## {% new-feature /%} Unlock request batch-mode

When you're first getting started with Gertrude for Mac, or when your child is requesting
access to new websites and platforms, it's not unusual to receive **many unlock requests**
at once. Until recently, responding to multiple unlock requests was... ehm... a little
painful to say the least. Lots and lots of clicks.

We recently overhauled this part of the [parent's website](https://parents.gertrude.app)
to make it much easier to respond to groups of unlock requests.

{% image src="batch-unlock-requests.png" caption="Respond to a batch of unlock requests all at once" alt="Pending unlock requests list with keychain pickers and accept/deny toggles for each row, plus a Submit button that summarizes the batch decision" /%}

## Major improvements for Chrome and Firefox

{% image src="non-safari-browsers.png" alt="Gertrude now identifies websites more reliably in Chrome, Firefox, and other non-Safari browsers"
   /%}

Ever since Gertrude was first created, it has worked better for Safari than for other
non-Safari browsers like Chrome and Firefox. When I say _better_, I don't mean
_safer_&mdash;Gertrude has always been just as safe for all browsers, but it has been
_easier to use in Safari._ Unlocking was easier, required fewer keys, blocked requests
were easier to understand, and public keychains worked better. The reason for all this is
a little technical, but boils down to the fact that Safari is a first-party Apple app, and
provides Gertrude with better information than other browsers.

This finally changes with `v2.9.0` - Gertrude is now able to extract comparable data from
raw socket flows to what is provided by default by Apple in Safari, resulting in a much
better experience for non-Safari browsers.

## Faster filter decisions

Because Gertrude is a **deny-by-default** filter (meaning, every network request is
blocked unless specifically permitted by a **key**) - every single network request on the
computer must be checked against every key attached to a protected Gertrude user. Gertrude
has always been fast in this decision-making hot path, microseconds at worst, but `v2.9.0`
includes a major performance rewrite of the core filter decision-making process. In our
benchmarks, the new version runs **10-50x faster!!** For children with many keys, this can
produce a noticeable speedup in perceived performance.

## More Private Screenshots

Our Mac app screenshots have always been very private and secure, but did suffer from the
vulnerability that if a dashboard screenshot URL was accidentally or maliciously revealed
and shared, the image could be visible to non-parents. (By the way, we have zero records
of this having ever happened, or of any security breaches of our own data; this is
hypothetical only.) The latest version of the Gertrude Mac app switches to
private-by-default images with short-lived signed URLs, eliminating this vulnerability.

## A Completely Rebuilt Setup Experience

I always tell parents something like "Getting Gertrude setup for the first time is a bit
tricky, but once it's installed, you're gonna love it!" In `v2.9.0` we put in a huge
effort to improve the initial setup wizard. Instead of just walking new parents through
the complicated but necessary permissions required for Gertrude to protect and monitor
your child, the setup wizard now walks you through a series of new steps to help you:

- block apps
- grant other apps unrestricted internet access
- turn on and configure downtime
- opt-in to unfiltered mode
- choose always-blocked items
- choose from public keychains
- create new keychains from website addresses
- set up text notifications

{% image src="onboarding-grant-apps.png" caption="The new setup wizard walks parents step-by-step thru helpful new steps" alt="Gertrude onboarding wizard screen titled 'Grant apps internet access' with a grid of installed Mac apps — Home, Image Capture, Image Playground, iPhone Mirroring, Journal, Mail, Maps, Messages, Music, News, Notes, Passwords, Phone, Photo Booth — each with a toggle marked 'No internet' or 'Unrestricted internet', and an 'Allow (2) apps' button at the bottom" /%}

## Protection Against Screen Time Conflicts

Running Apple's Screen Time website blocking alongside of Gertrude is not only not
necessary, it actually is the
[one thing that can break Gertrude's filter](/blog/screen-time-web-filter-conflict).

Gertrude now **proactively detects** this issue, partially shuts down the internet filter
to prevent any incorrect website allowances, and notifies the parent how to fix the issue.

{% callout %}

This feature actually shipped in `v2.8.0`, we just never blogged about it. Sorry!

{% /callout %}

## {% new-feature /%} Ntfy&mdash;New parent notification method

Gertrude has always supported email, text, and Slack notifications. But we recently added
the free push notification service [ntfy](https://ntfy.sh/) as a new notification method.
If you have the ntfy app installed on your phone (it supports Android and iOS), you can
now receive push notifications for important events like unlock requests, filter
suspensions, security events and more.

If you'd like to do _a small favor_ to support Gertrude, switch from text notifications to
ntfy, it saves us a lot of money!

{% image src="ntfy-logo.png" caption="ntfy is a free, open-source push notification service" alt="ntfy logo — a green rounded square containing a white terminal-prompt speech bubble — next to the tagline 'ntfy | Push notifications made easy'" /%}

## Small Touches

There's loads more too, some highlights include:

- made it way easier to create a safer non-admin user account during setup
- smarter app identification makes app keys work more reliably
- cmd-W now closes Gertrude windows like other Mac apps (haha, sorry)
- support copy/paste in Gertrude connection windows
- expanded browser identification list for post-suspension termination
- cleaned up duplicate keys for better performance

## What Next?

We're excited to know if these new features are useful to your family. We'd also love to
know what you think we should be working on next. We're building faster than ever, so if
you have ideas or feature requests, please
[reach out and let us know!](https://gertrude.app/contact)

{% callout %}

In order to use the new features described in this blog post, you'll need to update the
Gertrude app on your child's computer to the latest version.

{% /callout %}
