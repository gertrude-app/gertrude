---
title: How to Block Explicit Images in Maps on iPhone and iPad
description:
  'Apple Maps and Google Maps both display photos uploaded by businesses, including nude
  photos posted by strip clubs. Gertrude blocks those images inside Apple Maps, and Google
  Maps can be deleted.'
products: [blocker]
platforms: [ios, ipados]
---

{% .lead .mb-12 %} **TL;DR:** both the built-in **Apple Maps** app and **Google Maps**
will show _any image_ that a business owner or a customer has uploaded, and plenty of
strip clubs post nude photos. No Screen Time setting stops this. Gertrude blocks those
images inside Apple Maps, but Google Maps isn't supported yet, so we recommend deleting
it.

{% image src="lockdown-iphone/maps-images-ios26.png" width=450 caption="The images from strip clubs and adult bookstores aren't so innocent" alt="five things you forgot locking down your kids iPhone: Apple Maps and Google Maps can show explicit photos to your child" /%}

## Why the map apps aren't safe

Every business listing in both apps has a photo section, and a good portion of what's in
it was uploaded by the public. Nobody is reviewing those photos with a child in mind, so
the listing for a strip club or an adult bookstore contains about what you'd expect. Your
child doesn't have to go looking for it, either. The photos are one tap away from an
ordinary map search.

Sadly, this loophole has become well-known enough that there are locations where users
deliberately upload pornographic images. Bark
[wrote about one](https://www.bark.us/blog/google-maps-safety/): a fake Google Maps place
called "Milk Island" that fills back up with explicit photos and video every time Google
clears it out.

Furthermore, "Street View" mode in both apps also can occasionally show inappropriate
content.

Screen Time has no restriction that covers this. Nor are there settings provided by Apple
or Google for parents to forbid access to these features. For a few years we recommended
that both apps be deleted, and recommended using Waze instead. Thankfully now, with our
own [free iOS app for iPhone and iPad](/iphone-and-ipad), we can completely block the
images and street view within Apple Maps.

We have not yet done the same with Google Maps, but are actively working on it.

## Apple Maps

[Gertrude Blocker](https://apps.apple.com/us/app/gertrude-blocker/id6736368820) is a free
app (iOS 17 and up) that blocks content _inside_ other apps, including all of the images
from Apple Maps business listings, and Street View. Install it on the device you're
protecting and Apple Maps is taken care of. For detailed setup instructions,
[see here](/help/iphone-ipad/block-gif-search-in-messages#step-by-step).

The block group is called **Apple Maps images**, and it's turned on by default when you
run through setup.

{% callout type="warning" title="If you'd rather not install Gertrude" %}

Then Apple Maps is still a problem, and we'd recommend deleting it along with Google Maps.
The **Waze** app doesn't allow viewing business photos, and works well as a replacement
for an older teen who needs turn-by-turn directions.

{% /callout %}

## How to delete a map app

**Step 1.** Temporarily _allow deleting apps_ by going to "Settings > Screen Time >
Content & Privacy Restrictions > iTunes & App Store Purchases":

{% image src="lockdown-iphone/itunes-app-store-purchases-ios26.png" width=450 caption="Go to \"Content & Privacy Restrictions > iTunes & App Store Purchases\"" alt="how to block explicit images in maps: Content & Privacy Restrictions > iTunes & App Store Purchases" /%}

Then tap **Deleting Apps** and set it to **Allow**:

{% image src="lockdown-iphone/allow-deleting-apps-ios26.png" width=450 caption="Temporarily ALLOW deleting apps" alt="how to block explicit images in maps: temporarily allow deleting apps" /%}

You may find that deleting apps is already allowed. If so, leave it as it is, but we do
recommend revoking that privilege once you're done.

**Step 2.** Delete the app.

Press and hold the app icon on the home screen and choose to delete it.

{% image src="lockdown-iphone/delete-google-maps-ios26.png" width=450 caption="Press and hold the icon, then choose <b>Remove App</b>" alt="how to block explicit images in maps: how to delete the Google Maps app with Screen Time" /%}

{% callout alt=true %}

If you're trying to delete Apple Maps, and for some reason it won't delete, try powering
the phone all the way off and back on again, then try once more. Older versions of iOS
required that before they would allow deleting of Apple Maps.

{% /callout %}

**Step 3.** Turn deleting apps back off.

Go back to "Settings > Screen Time > Content & Privacy Restrictions > iTunes & App Store
Purchases" and set **Deleting Apps** back to **Don't Allow**:

{% image src="lockdown-iphone/dont-allow-installing-deleting-apps-ios26.png" width=450 caption="Remove the ability to delete apps again" alt="how to block explicit images in maps: then re-disable deleting apps" /%}

**Step 4.** Disable automatic software updates. _(Apple Maps only)_

Every time iOS updates, which can happen on its own overnight while the phone is charging,
the Apple Maps app _may_ come back. We aren't 100% sure how often it does. It may only be
the large yearly versions that come out in the fall, or it may be more often, but it
_definitely_ has happened, at least in the iOS 17/18 era.

Go to the Settings app on your child's phone, then navigate to "General > Software
Update > Automatic Updates", and disable all three options shown below:

{% image src="lockdown-iphone/disable-automatic-updates-ios26.png" width=450 caption="In Settings > General > Software Update" alt="how to block explicit images in maps: disable automatic iOS software updates" /%}

{% callout alt=true type="warning" %}

Sadly, there is no way for you to prevent your child from turning automatic updates back
on. So we recommend that you **a)** don't show them this setting area, **b)** check it on
their phone from time to time, ideally when you notice your own phone has updated, and
**c)** update their phone manually on a regular basis, so that you can check for the
reappearance of Maps and other safety concerns, and remove any incentive for them to
change the setting.

{% /callout %}
