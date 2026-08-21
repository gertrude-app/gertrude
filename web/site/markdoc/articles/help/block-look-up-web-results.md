---
title: How to Block Look Up Web Results on iPhone and iPad
description:
  'Older Screen Time instructions for preventing Look Up in reading and notes apps from
  displaying web results.'
products: [blocker]
platforms: [ios, ipados]
---

{% callout type="warning" title="These instructions are outdated" %}

This article preserves instructions written in 2023 for an older version of iOS. Current
setting names, screenshots, and steps may differ. We’re working on an updated version.

{% /callout %}

Most apps that deal with text (like ebook readers, Bible apps, Notes, and **many more**)
allow the user to _highlight a search term and **"Look Up"**_.

{% image src="lockdown-iphone/lookup-books.png" caption="Most apps let you highlight a word, then tap 'Look Up'" alt="five things you forgot locking down your kids iPhone: highlight a word and tap 'Look Up'" /%}

Which brings up this:

{% image src="lockdown-iphone/look-up-results.png" caption="An example of images pulled from the web in response to a 'Look Up'" alt="five things you forgot locking down your kids iPhone: Look Up on iOS can access and display to your child images from the web" /%}

{% click-to-reveal title="Show me how to fix it" %}

{% callout alt=true %}

These steps are nearly identical to the fix for _Internet Content in Searches_, except for
what setting to disable in step 2.

{% /callout %}

**Step 1.** Temporarily _allow_ the use of Siri by going to: Settings > Screen Time >
Content & Privacy Restrictions > Allowed Apps. (We need Siri enabled to get to the
settings shown below.)

{% image src="lockdown-iphone/allowed-apps.png" caption="Go to 'Allowed Apps'" alt="five things you forgot locking down your kids iPhone: Screen Time -> Content & Privacy Restrictions > Allowed Apps" /%}

Tap to **temporarily enable** Siri & Dictation.

{% image src="lockdown-iphone/enable-siri-dictation.png" caption="Temporarily <b>enable</b> Siri" alt="five things you forgot locking down your kids iPhone: temporarily enable Siri to fix the other settings" /%}

**Step 2.** Go back to the _main settings screen_, where you should now be able to see an
option for **Siri & Search**

{% image src="lockdown-iphone/siri-search-main.png" caption="Now you can go back to 'Settings > Siri & Search'" alt="five things you forgot locking down your kids iPhone: now you can find 'Siri & Search' under the main Settings screen" /%}

Click to **disable "Show in Look Up"**:

{% image src="lockdown-iphone/disable-show-in-lookup.png" caption="DISABLE 'Show in Look Up'" alt="five things you forgot locking down your kids iPhone: disable 'Show in Look Up' to prevent showing your child images and content from the internet" /%}

**Step 3.** Finally, now that Siri can no longer provide results to "Look Up", you need to
_reverse step 1_ by disabling Siri & Dictation. Go to Settings > Screen Time > Content &
Privacy Restrictions, and disallow Siri & Dictation.

{% image src="lockdown-iphone/disable-siri-dictation.png" caption="<b>Disable</b> Siri again (same location as step 1)" alt="five things you forgot locking down your kids iPhone: re-disable Siri in Screen Time after fixing the other settings" /%}

{% /click-to-reveal %}
