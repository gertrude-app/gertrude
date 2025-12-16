---
title: Gertrude 2.7.0 Released
date: '2025-01-29T16:29:51.973Z'
description:
  'Today we are releasing version 2.7.0 of the Gertrude macOS app, which includes a new
  ability to block Mac apps, updates for changes in macOS Sequoia, safety improvements,
  and more.'
category: mac
---

{% .lead .mb-12 %} Today we're releasing another big update to the Gertrude app, which
includes a new ability to _block apps,_ updates for changes in macOS Sequoia, safety
improvements, keychain warnings, and more.

## Blocking Mac Apps

As an additional layer of safety and control for parents, Gertrude `v2.7.0` now allows you
to block any macOS app&mdash;either on a schedule, or all the time.

{% image src="application-blocked.png" caption="You can now prevent your child from launching certain apps" alt="New in Gertrude 2.7.0 - block any Mac app, all the time or on a schedule" /%}

To access this new feature, make sure your child's Mac has the latest version of Gertrude,
then navigate to their **Settings** screen, and scroll down to the area labeled **Blocked
apps**. From there, you can type the name of an app you want to block, and optionally
configure it to only block on a schedule.

{% image src="add-blocked-app.png" caption="Type the name of an app you want to block" alt="Choose any macOS to block, preventing your child from launching it" /%}

## New Monitoring Safeguard

It was recently brought to our attention that it was possible for very tech-savvy child to
take a specific sequence of steps that would result in the Gertrude app no longer running.
While we don't know that any child has ever exploited this exact sequence, and even if
they did it had no affect on the internet filter, we still felt it was important to
address, because it could theoretically cause parents to temporarily lose screenshot and
keystroke monitoring.

If the new version of Gertrude filter detects that the app is no longer running, the
filter will start blocking all internet access for the user with the non-running app. This
means that any child who attempts this workaround will effectively cut off their internet
access until the app is running again, hopefully mitigating any danger.

## macOS Sequoia Updates

Gertrude 2.7.0 also includes an update that is necessary to workaround changes in privacy
system settings in macOS Sequoia. Apple has recently shipped some changes aimed at making
it harder for malicious software to record your screen without your knowledge. Gertrude's
screenshot monitoring feature only works after an admin grants permission, and always
displays to your child when their screen is being recorded. Despite this, the newest
versions of Sequoia have started producing misleading warnings about Gertrude accessing
the screen. In some cases, these warnings could show up hundreds of times a day, and could
even reveal to your children the approximate cadence and frequency of the screenshots.

The new version is able to suppress these spurious warnings, but requires a new permission
in order to do so. You'll notice when you upgrade that Gertrude will open a large window
explaining the new permission and showing you how to grant it.

## New Keychain Warnings

Some of our public keychains have areas of known risk that cannot be avoided, but still
make sense for certain users. For instance, the keychain for Google Docs makes it possible
for a child to search for and insert images, some of which are moderately inappropriate.
To make sure that parents are aware of the risks, we've surfaced a new warning for any
keychains that we believe are not appropriate for all children.

{% image src="keychain-warning.png" caption="Risky keychains now have visible warnings" /%}

## Detailed Filter Status

The new version of the Gertrude app sends back more detailed information about it's
current filter status, including when it's suspended and when it will resume, downtime,
and more. This information will be showing up soon in the parent's website, helping you
see at a glance with even more clarity exactly what's going on with all your kids'
computers.

## iOS App Updates Coming Soon...

We also have some exciting updates in the works for our Gertrude iOS app, which we
released a few months ago, including the ability to control new areas of content blocking,
a built-in ability to clear the cache from previously viewed GIFs, and a much-improved
onboarding and installation flow.

We think these changes will pave the way towards eventually making the iOS app
configurable and controllable from your parents account, giving you the flexibility and
control you love about Gertrude for Mac, but on their iPhone or iPad. Stay tuned!

## What Next?

We're excited to know if these new features are useful to your family. We'd also love to
know what you think we should be working on next. If you have ideas or feature requests,
please [reach out and let us know!](https://gertrude.app/contact)

{% callout %}

In order to use the new features described in this blog post, you'll need to update the
Gertrude app on your child's computer to the latest version.

{% /callout %}
