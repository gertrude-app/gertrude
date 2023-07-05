---
title: Frequently Asked Questions
description:
  What makes Gertrude better? Does it work on iPhones? ...and more frequently asked
  questions.
---

## What makes Gertrude better?

I'm a software developer who built Gertrude because I was trying to protect my kids
online, and was frustrated with the lack of _safety_ and _usability_ of other parental
controls apps for Mac on the market. A lot of Gertrude's core features came out of things
I wished I had while trying to protect my kids online using other off-the shelf software,
things like:

- **Real safety.** Nearly every other internet security tool tries to block _categories_
  of websites, like pornography, gambling, etc. This is tantalizing because its _so easy_,
  but it doesn't actually work. With 1.7 billion websites on the internet, and thousands
  being added every day, a motivated user will always be able to find inappropriate
  content not properly categorized. I needed something that _blocked the entire internet,_
  and let me choose what parts to unblock.
- **Ease of use.** A few solutions do exist that will block the entire internet and let
  you specify what to unlock, but they are incredibly _onerous and cumbersome to use_. For
  instance, my two oldest kids needed many of the same websites unblocked, but I had to
  manually type dozens of domains twice: once for each of their computers. Gertrude fixes
  this by allowing you to create "keychains"&mdash;groups of shareable and reusable "keys"
  that unlock parts of the internet. It also allows my kids to identify blocked requests,
  and send me a notification requesting it be unblocked.
- **Supervision.** Previous solutions I tried sometimes failed. I wanted a backup, so I
  tried installing software that would monitor keystrokes, but it was hard to find
  anything that was affordable and actually worked, and that didn't seem slimy. I'm not
  trying to hide the fact that I'm watching my kids computer use, they know it. So I built
  Gertrude to take _periodic screenshots_ of my kids screens, and to _record their
  keystrokes_. I get to review these on my phone, any time I want. And it's not
  hidden&mdash;the Gertrude app clearly lets the user know if their screen and keystrokes
  are being recorded. This also makes it so I can now temporarily suspend the
  filter&mdash;I know it's safe because I'll see their activity afterwards, and they know
  it too.
- **Remote control.** Every other solution I tried had to be configured and managed _on my
  kids' computer_. Every time they needed something changed or unlocked, they would have
  to bring me their computer so I could authenticate and tweak the settings. I built
  Gertrude so that I could manage every aspect of their protection from the comfort of _my
  own computer or phone, no matter where I was._

## Can it block or filter the internet?

Yes, this is one of Gertrude's flagship features. We think it's the best mac internet
filter and website blocker on the market right now because:

- It takes the only safe approach, blocking _every website_ by default, and only allowing
  those sites you specifically label as safe. Most mac website blockers work by hoping to
  categorize and block just the bad websites.
- It provides _convenient controls,_ letting you set up lists of unblocked websites from
  your own computer or phone, and share them between your kids.
- We provide tools for your child to _identify blocked websites_ and request access. You
  get to respond on your time, from your own phone, unblocking sites you deem safe.

## Does it provide keylogging?

Yes. Observing and monitoring what your child types can be an extremely powerful form of
accountability and safety. Gertrude comes with a built-in mac keylogger which, when
enabled, captures nearly everything they type (except passwords and credit card numbers).
This keylogger data is uploaded for the parent to later review from their computer or
phone. Gertrude is not meant for spying&mdash;when keystroke monitoring is enabled, your
child is clearly notified that their typing is being recorded. But, provided their
computer is configured correctly, they are not able to disable the keylogging&mdash;making
it a perfect fit for trusting relationships of accountability like between a parent and
child, or a peer with a trusted accountability partner.

{% image src="recording-keystrokes.png" caption="We clearly display when keylogging is active" alt="Mac keylogging for parents" /%}

{% image src="review-keylogging.png" caption="Review everything your child types, on your own time" alt="mac parental controls keylogger" /%}

## Does it work on iPhones or iPads?

No. It only works for _Mac computers._ This is primarily because I built Gertrude
originally for myself, and I only needed a solution for the computers where my kids did
their homework. I already had a very reliable way of keeping them safe on a
phone&mdash;don't give them one. When I finally got my 16+ year old a phone, I protected
it using the Apple Screen Time feature, which is very effective, although difficult to
setup. Check out our
[guide to locking down an iPhone](/docs/definitive-guide-to-locking-down-an-iphone) for
more information.

## I can't access the internet on my admin user account

_TLDR_&mdash;Sign in as your protected user, go to the "Administrate" > "Exempt Users"
screen, and click to allow unrestricted access for the admin user account.

{% image src="exempt-users.png" caption="Exempt an admin user from filtering" /%}

If you share a computer with your kid, and the Gertrude app is installed on their macOS
user, the filter will by default block all the internet requests from every other user on
the computer. That's because the Gertrude filter system extension runs as `root` and has
to make a decision about every network request attempted by every user on the system. For
maximum safety, I built Gertrude to be _very defensive_, when in doubt, it always takes
the most safe option, which is to forbid network requests for users it has no instructions
about.

Therefore, you need to explicitly instruct the filter about macOS users who should be
_exempt from filtering_. To do this, sign in as the macOS user being protected by
Gertrude. Click the Gertrude menu bar icon, then click _Administrate..._ and choose the
_Exempt Users_ option from the left sidebar, then click to exempt the user.

{% callout type="warning" title="Be careful with exemptions!" %}

It's critical that any user that is exempt from filtering be **protected by a password**
that is unknown to any of your kids. Otherwise, they would be able to sign in to the
exempt user and have unrestricted internet and no monitoring from the Gertrude app.

{% /callout %}

## Why are browsers forced to quit after a filter suspension expires?

For maximum safety. Modern web browsers use `http2`, allowing them to _re-use socket
connections_ to transmit data. In English, what that means is that any websites your user
has opened during a filter suspension _will remain partially unblocked after the filter
suspension expires,_ as the browser will keep using a connection opened during the
suspension. To prevent this, we terminate all browsers 60 seconds after a suspension
expires.
