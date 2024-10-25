---
title: Frequently Asked Questions
description:
  What makes Gertrude better? Does it work on iPhones? ...and more frequently asked
  questions.
---

### [Does it work on iPhones or iPads?](#ios) {% class="pt-4" %}

### [Is it just for kids? Or can adults use it too?](#adults)

### [Can two kids share a computer with different protections?](#share-computer)

### [Does the parent need an Apple device?](#apple-device)

### [Can kids request websites to be unblocked?](#unlock-requests)

### [Why would a website seem broken after I unblocked it?](#broken-website)

### [Should I unblock YouTube?](#youtube)

### [Can it block or filter the internet?](#filter-internet)

### [Does it provide keylogging?](#keylogging)

### [What makes Gertrude different?](#different)

### [Why do browsers quit after a filter suspension ends?](#browser-quit)

### [I just installed Gertrude, but it's not blocking anything. Why?](#not-blocking)

### [Why can't I access the internet on my admin user account?](#admin-internet)

### [I'm no good with tech. Will this be too hard for me?](#dont-give-up) {% class="mb-16" %}

## Does it work on iPhones or iPads? {% id="ios" %}

No. It currently only works for _Mac computers._ This is primarily because I built
Gertrude originally for myself, and I only needed a solution for the computers where my
kids did their homework. I already had a very reliable way of keeping them safe on a
phone&mdash;don't give them one. When I finally got my 16+ year old a phone, I protected
it using the Apple Screen Time feature, which is very effective, although difficult to
setup. Check out our
[guide to locking down an iPhone](/blog/definitive-guide-to-locking-down-an-iphone) for
more information.

{% callout title="UPDATE: 10/2024" %}

Due to the [increasing difficulty](/blog/ios18-screentime-what-parents-should-know) of
locking down iPhones and iPads with the most recent versions of iOS, and due to numerous
requests from Gertrude parents, we recently released the first version of a Gertrude
[iOS app that blocks GIFs](/blog/how-parents-can-block-images-gif-search-ios-18) and
closes other loopholes in Apple's Screen Time parental controls. We are exploring the
possibility of growing this into a more full-featured complement to Gertrude on macOS in
the months to come.

{% /callout %}

## Is it just for kids? Or can adults use it too? {% id="adults" %}

While Gertrude was designed primarily for parents to use with kids, it can (and does) work
quite well for adults in a relationship of accountability. In order for it to work for
this use case, you'll need a nearby trusted accountability partner who can oversee your
computer and occasionally make changes to it in person. This person will assume the
"parent" role, and you'll be the "child," at least in the language of Gertrude.

In order for the protections to be effective, the individual being protected should be
given a [standard macOS user account](https://youtu.be/ntnFEW0bRVQ), (not an admin
account), and their accountability partner should change the password of the admin
account, keeping it a secret.

Adults looking for solutions for self-managing their iOS devices should check out
[Tech Lockdown](https://www.techlockdown.com).

## Can two kids share a computer with different protections? {% id="share-computer" %}

Absolutely! All you need to do is
[create a separate macOS user account](https://youtu.be/ntnFEW0bRVQ) for each child, and
connect each of those user accounts to a Gertrude "Child". This allows each child to have
their own individually customized sets of allowed websites and monitoring settings.

Just be sure that if one of your children has more permissive settings than the other,
that their computer user is protected by a password the other child does not know.

## Does the parent need an Apple device? {% id="apple-device" %}

Nope. While the Gertrude app itself is only installed on Mac computers, the parent can
manage all aspects of the Gertrude app from any kind of phone, computer, or device, as
long as it can access the internet with a browser. Parents control their kids protections
from a parents-only website, and can receive notifications via text, email, or Slack.

## Can kids request websites to be unblocked? {% id="unlock-requests" %}

Yes! If a child is blocked from visiting a website or using an app they think their parent
would allow, they can bring up a list of recently blocked requests, and request their
parent to unblock them. The parent receives a notification on their phone and can accept
or deny the request.

{% image src="triple-unlock-request.png" caption="Kids can view blocked requests and send <b>unlock requests</b> to their parents" /%}

For tips and tricks on how to unblock websites, check out our
[unblocking guide](/docs/unblocking-guide). Be sure to
[create a notification](https://parents.gertrude.app/settings) to receive these requests.

## Why would a website seem broken after I unblocked it? {% id="broken-website" %}

Because of how websites are built, it often takes several keys to get a website fully
working&mdash;this is totally normal. Check out our
[unblocking guide](/docs/unblocking-guide) for a detailed description on why this happens,
and a simple technique to get any website working 100%.

## Should I unblock YouTube? {% id="youtube" %}

We recommend **NOT** unblocking YouTube because there's just too much inappropriate
content and the family safety restrictions provided by Google are nowhere near sufficient.
That said, many kids need to watch a small number of specific videos assigned by teachers.
For these cases, we recommend using temporary **filter suspensions,** which will grant
access to YouTube only for a designated amount of time, before revoking access again
automatically. As long as you have Gertrude's screenshot monitoring feature enabled, you
will be able to see their activity while the filter is suspended, which makes these short
bursts of unfiltered activity safe.

## Can it block or filter the internet? {% id="filter-internet" %}

Yes, this is one of Gertrude's flagship features. We think it's the best mac internet
filter and website blocker on the market right now because:

- It takes the only safe approach, blocking _every website_ by default, and only allowing
  those sites you specifically label as safe. Most mac website blockers work by hoping to
  categorize and block just the bad websites.
- It provides _convenient controls,_ letting you set up lists of unblocked websites from
  your own computer or phone, and share them between your kids.
- We provide tools for your child to _identify blocked websites_ and request access. You
  get to respond on your time, from your own phone, unblocking sites you deem safe.

## Does it provide keylogging? {% id="keylogging" %}

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

## What makes Gertrude different? {% id="different" %}

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

## Why are browsers forced to quit after a filter suspension expires? {% id="browser-quit" %}

For maximum safety. Modern web browsers use `http2`, allowing them to _re-use socket
connections_ to transmit data. In English, what that means is that any websites your child
has opened during a filter suspension _will remain partially unblocked after the filter
suspension expires,_ as the browser will keep using a connection opened during the
suspension. To prevent this, we terminate all browsers 60 seconds after a suspension
expires.

## I just installed Gertrude, but it's not blocking anything. Why? {% id="not-blocking" %}

Double-check that you got the **System Extension** installed by going to the
_Administrate..._ screen after clicking the Gertrude menu bar icon. If the extension
wasn't installed properly, click the button to install it.

If for some reason it seems to be installed properly and the filter is still not blocking
anything, it's very likely caused by a conflict with Apple's **Screen Time** website
blocker. For some reason, when Apple is trying to filter websites on a Mac using it's own
Screen Time functionality, it bypasses Gertrude's filter. To fix it, you just need to
disable Screen Time on the Mac computer, in the System Settings app. Don't worry, you can
keep using Screen Time for your kids' iPhones and iPads, it just can't be used on the Mac
at the same time as Gertrude.

## Why can't I access the internet on my admin user account? {% id="admin-internet" %}

_TLDR_&mdash;Sign in as your child, go to the "Administrate" > "Exempt Users" screen, and
click to allow unrestricted access for the admin user account.

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

## I'm no good with tech. Will this be too hard for me? {% id="dont-give-up" %}

Many parents feel this way. I wish I could promise you a perfectly smooth and easy
experience, but that would be a lie. Keeping our kids safe on the internet takes time,
will be annoying and frustrating at times, but is **unbelievably important.** Here's a
workshop I gave at a Christian homeschool conference in May 2024, where I pass on all my
tips, tricks and words of encouragement for parents:

{% video videoId="syC94X5LBIc" title="Gertrude | Internet Safety 101" /%}
