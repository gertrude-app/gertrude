---
title: How to Block Explicit Images in Maps on iPhone and iPad
description:
  'Older Screen Time instructions for removing Maps apps that can expose children to
  explicit business photos.'
products: [blocker]
platforms: [ios, ipados]
---

{% callout type="warning" title="These instructions are outdated" %}

This article preserves instructions written in 2023 for an older version of iOS. Current
settings and best practices may differ. We’re working on an updated version.

{% /callout %}

The built-in Apple Maps app and Google Maps are (surprisingly) not safe for kids, and
should be deleted. They are unsafe because both apps will show _any images_ that may have
been uploaded by business owners or patrons. For instance, _many strip clubs post nude
photos_ which can be accessed through these apps. No Screen Time setting can prevent these
images from being viewed, the only way to secure your child's phone is to delete the apps.
(In the "how to fix" section below we recommend an alternate map/navigation app.)

{% image src="lockdown-iphone/maps-images.png" caption="The images from strip clubs and adult bookstores aren't so innocent" alt="five things you forgot locking down your kids iPhone: Apple Maps and Google Maps can show explicit photos to your child" /%}

{% click-to-reveal title="Show me how to fix it" %}

**Step 1.** Temporarily _allow deleting apps_ in Screen Time by going to "Settings >
Screen Time > Content & Privacy Restrictions > iTunes & App Store Purchases", as shown
below:

{% image src="lockdown-iphone/screentime-content-privacy-restrictions.png" caption="Go to \"Settings > Screen Time > Content & Privacy Restrictions\"" alt="five things you forgot locking down your kids iPhone: go to Settings > Screen Time > Content & Privacy Restrictions" /%}

{% image src="lockdown-iphone/itunes-app-store-purchases.png" caption="Then to \"iTunes & App Store Purchases\"" alt="five things you forgot locking down your kids iPhone: iTunes and App Store Purchases" /%}

{% image src="lockdown-iphone/allow-deleting-apps.png" caption="Temporarily ALLOW deleting apps" alt="five things you forgot locking down your kids iPhone: temporarily allow deleting apps" /%}

You may find that you are already allowing Deleting apps. If so, just leave the setting as
is, but we do recommend you revoke that privilege after deleting the map apps.

**Step 2.** Power off and restart the phone.

{% callout alt=true %}

If you've already deleted Apple Maps and are **only deleting Google Maps**, you can skip
this step.

{% /callout %}

Once you've allowed deleting apps, you won't actually be able to delete _Apple Maps_ until
you fully power off the phone and restart. To power off the phone, hold down the "side"
button and the "volume down" button at the same time.

{% image src="lockdown-iphone/slide-to-power-off.png" caption="Strangely, you have to power off before you can delete Apple maps" alt="five things you forgot locking down your kids iPhone: hold down side and volume down buttons to power off" /%}

After the phone has powered off, turn it on again by holding the right side button until
the Apple logo appears.

**Step 3.** Delete the app/s.

Once you've allowed deleting apps and restarted the phone after a full power-off, you can
_now_ click and hold the icon of the Apple maps (and/or the Google Maps app) and choose to
delete it.

{% image src="lockdown-iphone/delete-apple-maps.png" caption="Press and hold the icon to delete Apple Maps" alt="five things you forgot locking down your kids iPhone: how to delete Apple Maps with Screen Time" /%}

**Step 4.** Now that the app is deleted, _forbid again the ability to delete apps_ by
going back to "Settings > Screen Time > Content & Privacy Restrictions > iTunes & App
Store Purchases":

{% image src="lockdown-iphone/disallow-deleting-apps.png" caption="Remove the ability to delete apps again" alt="five things you forgot locking down your kids iPhone: then re-disable deleting apps" /%}

**Step 5.** Disable automatic software updates.

Every time iOS updates (which can happen automatically, without any intervention, during
the night when the phone is charging), the Apple Maps app _may_ come back. We aren't 100%
sure how often it does, it may only be for the large, yearly major iOS versions that
usually happen in the fall, or it may be more often&mdash;but it _definitely_ happens.

Go to the Settings app on your child's phone, then navigate to "General > Software
Update > Automatic Update", and disable all three options shown below:

{% image src="lockdown-iphone/disable-automatic-updates.png" caption="In Settings > General > Software Updates" alt="five things you forgot locking down your kids iPhone: disable automatic iOS software updates" /%}

{% callout alt=true type="warning" %}

Sadly, there is no way for you to prevent your child from turning automatic updates back
on. Therefore, we recommend that you **a)** don't show them this setting area, and **b)**
check this setting on their phone frequently, ideally when you notice your own phone has
updated, and **c)** proactively update their phones manually on a regular basis, so you
can check for the reappearance of Maps and other safety concerns, and also remove any
incentive for them to change this setting.

{% /callout %}

{% callout alt=true %}

If your child needs a map/navigation app, at the time of this writing (2/8/2023) the
**Waze** app does not allow viewing of business images, and should be a safe alternative
for older teens who need a turn-by-turn direction app.

{% /callout %}

{% /click-to-reveal %}
