---
title: How to Block Web Content in iPhone and iPad Search
description:
  'Older Screen Time instructions for preventing device search from displaying images and
  other internet content.'
products: [blocker]
platforms: [ios, ipados]
---

{% callout type="warning" title="These instructions are outdated" %}

This article preserves instructions written in 2023 for an older version of iOS. Current
setting names, screenshots, and steps may differ. We’re working on an updated version.

{% /callout %}

To test if your child's phone is vulnerable to this commonly missed item, _**pull down**
from the middle of the home screen_ to access the iPhone's built-in _search prompt_.

{% image src="lockdown-iphone/spotlight-search.png" caption="Swipe down bring up search, then type a search phrase" alt="five things you forgot locking down your kids iPhone: spotlight searching on an iPhone can access internet images" /%}

After pressing the _search_ button, Siri is activated behind the scenes to search the
internet and return results, **including images**. Again, imagine a less innocent search
than `goats`:

{% image src="lockdown-iphone/spotlight-search-results.png" caption="Search can use Siri to pull images and content from the internet" alt="five things you forgot locking down your kids iPhone: spotlight searching on iOS by default can load and display images from the web" /%}

{% click-to-reveal title="Show me how to fix it" %}

{% callout type="warning" alt=true %}

The fix for this one is unintuitive because if you have Siri disabled via Screen Time, the
controls you need to fix this loophole are **not visible,** which is why Step 1 is
required.

{% /callout %}

**Step 1.** Temporarily _allow_ the use of Siri by going to: Settings > Screen Time >
Content & Privacy Restrictions > Allowed Apps.

{% image src="lockdown-iphone/allowed-apps.png" caption="Go to 'Allowed Apps'" alt="five things you forgot locking down your kids iPhone: Screen Time > Allowed Apps" /%}

Then, _temporarily allow_ Siri & Dictation (you'll disable it again once we get the
Spotlight searching features disabled).

{% image src="lockdown-iphone/enable-siri-dictation.png" caption="Temporarily <b>enable</b> Siri" alt="five things you forgot locking down your kids iPhone: temporarily enable Siri & Dictation" /%}

**Step 2.** Go back to the _main settings screen_, where you should now be able to see an
option for **Siri & Search**

{% image src="lockdown-iphone/siri-search-main.png" caption="Now you can find \"Siri & Search\" in the main Settings screen" alt="five things you forgot locking down your kids iPhone: now you can see \"Siri & Search\" in the main Settings app" /%}

Click to **disable "Show in Spotlight"**:

{% image src="lockdown-iphone/disable-show-in-spotlight.png" caption="DISABLE 'Show in Spotlight'" alt="five things you forgot locking down your kids iPhone: diable 'Show in Spotlight'" /%}

**Step 3.** Finally, now that Siri can no longer provide results to Spotlight (the name of
the built-in iOS search feature), you need to _reverse step 1_ by disabling Siri &
Dictation. Go to Settings > Screen Time > Content & Privacy Restrictions, and disallow
Siri & Dictation.

{% image src="lockdown-iphone/disable-siri-dictation.png" caption="<b>Disable</b> Siri again (same location as step 1)" alt="five things you forgot locking down your kids iPhone: re-disable Siri again in Screen Time" /%}

{% /click-to-reveal %}
