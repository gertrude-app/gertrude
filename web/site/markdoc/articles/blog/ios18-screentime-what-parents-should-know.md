---
title: 'iOS 18 & Screen Time: What Parents Should Know'
date: '2024-10-02T20:00:45.219Z'
description:
  'Unfortunately, iOS18 seems to be another step backwards for parents. #images GIF search
  is still not preventable, and a new loophole with Spotlight searching has been found. We
  recommend sticking with iOS 16 or 17 until fixes or workarounds are ready.'
category: parental-controls
---

{% .lead .mb-12 %} iOS 18, released in September 2024, continues the discouraging trend of
making iOS harder for parents to lockdown safely for kids. If possible, we recommend
**keeping your kids devices on iOS 16 or 17** until Apple fixes these issues.

{% callout title="UPDATE: 10/2024" %}

We've just released a free iOS app called
[Gertrude Blocker](https://apps.apple.com/us/app/gertrude-blocker/id6736368820) which can
disable GIF search and Spotlight image search in Screen Time for both iOS 17 and 18. It is
the only known workaround for these issues on iOS 18.

{% /callout %}

## Problem #1: #images GIF search still not deletable

Well over a year ago, we reported that iOS 17 introduced a serious regression in parental
controls for iOS, namely the fact that parents lost the ability to disallow the `#images`
iMessage app built into the _Messages_ texting app. This app is filled with sexual and
innappropreate GIFs, and allows kids to search for and see thousands of animated GIFs from
pop culture, including many that are sexual or violent.

{% image src="images-gif-ios-18.png" caption="Apple <b>still</b> doesn't let parents block this mini-app..." alt="The #images GIF search cant be deleted in iOS 18" /%}

{% image src="bikini-gifs-ios18.png" caption="...where it's easy for kids to find explicit <b>animated</b> GIFs" alt="iOS 18 still hasn't given parents the ability to block the graphic animated GIFs in Messages" /%}

In iOS 17, there was one hacky workaround: by setting the device to essentially always be
in **Downtime** (by setting a schedule for Downtime to be on from 3:01am until 3:00am
every day), this GIF search stopped working. But in using this hack, parents also lose the
important ability to use Downtime for its intended purpose, and all apps must be set to
_Always Allowed_.

Sadly, our preliminary testing shows that this workaround **no longer works in iOS 18.**
Apart from switching to
[Supervised mode](https://www.techlockdown.com/blog/screen-time-alternative) which is much
more technically challenging than using Screen Time, there seems to be _no current
workaround_.

Apple has known about this issue for well over a year, so it's unclear why they haven't
yet fixed it.

## Problem #2: Kids can enable Spotlight internet searches

In iOS 18, Apple introduced a new top-level area in the _Settings_ app, called **Search**.
In that screen, users can toggle a setting labled _Show Related Content_, as shown here:

{% image src="show-related-content-ios18.png" caption="Screen Time does not protect this new Settings screen" alt="iOS 18 parental controls are getting worse: the 'Show Related Content' Settings area is always available to kids" /%}

When this setting is enabled, kids can see _image and text previews from the web when they
search from their phone._

{% image src="spotlight-internet-search-ios18.png" caption="Screen Time can not prevent these search results" alt="iOS 18 fails to protect kids, allowing internet searching" /%}

These search results are shown even if the parent has _removed Safari_ and set Web Content
to _Allowed Websites Only_. While it seems that Apple does not return search results for
obviously sexual or pornographic terms, it still represents a major hole in parental
controls. Hopefully this was just an oversight in the rush of many engineering teams
preparing for the new release, but time will tell.

## Problem 3#: Screen Time won't enforce VPN settings

Another problem Apple has known about for years is that Screen Time does not let parents
enforce VPN. While Gertrude does not employ a VPN, it is a common technique for parental
controls and accountability software, as it allows highly effective website blocking.
Apple devices allow parents to install VPNs on their kids devices, but they do
[nothing to stop kids or adults from disabling the VPN,](https://support.covenanteyes.com/hc/en-us/community/posts/13014220726043-Is-there-a-way-to-prevent-vpn-from-being-disabled-on-the-iPhone)
rendering them useless for parental controls.

Considering that Screen Time offers many explicit options for parents to restrict kids
from making changes to features like _max headphone volume_ or _driving focus_, the
omission of VPN settings restrictions is glaring and seems intentional.

{% callout title="<b class='text-2xl'>What should parents do?</b>" %}

1. Please take **2 minutes** to file a
   [bug report here](https://www.apple.com/feedback/messages-ios-ipados.html), letting
   Apple know that these are serious problems you care about. The more people who report
   the issues, the more likely they will fix it.
2. Help raise awareness and increase the pressure on Apple by **sharing this article** on
   social media.
3. If your kids' iOS devices aren't updated to iOS 18 yet **don't update, stay on iOS
   16/17** until Apple fixes the issue.
4. Keep an eye on this blog, we're hoping to release a free iOS app that patches these
   shortcomings in the near future!

{% /callout %}
