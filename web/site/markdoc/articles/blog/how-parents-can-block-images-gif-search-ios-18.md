---
title: 'SOLVED: How Parents Can Block #images GIF Search in iOS 18'
date: '2024-10-24T18:23:01.633Z'
image: /og-images/gif-images.jpg
description:
  'A new, free iOS app called “Gertrude Blocker” gives parents what Apple has refused for
  over a year: the ability block inappropriate GIFs searchable by kids in the Messages
  texting app for both iOS 17 and iOS 18.'
category: ios
---

Apple's built-in `#images` iMessage app for GIF search, built directly into the Messages
text-messaging app, has been a source of frustration to parents since iOS 17 was released
in September 2023. [Many](https://discussions.apple.com/thread/255165706)
[parents](https://discussions.apple.com/thread/254820669)
[have](https://discussions.apple.com/thread/254724878)
[pleaded](https://discussions.apple.com/thread/8117088)
[with](https://discussions.apple.com/thread/251774575)
[Apple](https://www.reddit.com/r/ios/comments/1c09fvp/how_to_block_images) to restore the
ability for them to disable this feature, which exposes their kids to thousands of
unwanted pop-culture animated GIFs including many with sexual or violent content.

When iOS 18 was released in September 2024 the situation was even worse: the one hacky
workaround which worked for iOS 17 (which required disabling another parental control
feature, Downtime) no longer worked. Plus,
[new holes in Screen Time](/blog/ios18-screentime-what-parents-should-know) were found,
including the inability for parents to restrict image searches through Spotlight. So we
ended up taking matters into our own hands and built
[a free iOS app called “Gertrude Blocker”](https://apps.apple.com/us/app/gertrude-blocker/id6736368820)
to solve this problem for parents.

## Introducing “Gertrude Blocker”

{% image src="lockdown-iphone/gertrude-blocker-ios-app.png" alt="Gertrude Blocker free iOS app allows parents to block unwanted GIFs in #images texting app" /%}

[Gertrude Blocker](https://apps.apple.com/us/app/gertrude-blocker/id6736368820) is a free
iOS app that allows parents to install a network content filter that plugs several glaring
holes in Apple's Screen Time parental controls, including: (at the time of this writing in
10/2024):

- **disabling #images GIF search** in Apple's Messages text-messaging app
- blocking animated GIFs in **WhatsApp, Skype,** and other messaging apps
- prevents **images searched via Spotlight** from loading (not currently possible to
  restrict by parents in iOS 18)
- **removing images from the App Store** iMessage mini-app in Apple Messages (not
  currently removable by parents)
- **blocking AI search results** embedded in iOS 18 Photos App

{% callout title="Who can use Gertrude Blocker?" %}

Because of rules put in place by Apple, Gertrude Blocker only works on devices signed in
to an iCloud account registered to a _minor (under 18)_ who is part of an _Apple Family
Sharing group_ with a parent or guardian.

If you haven't created a Family Sharing group,
[see here for instructions](https://support.apple.com/en-us/108380).

{% /callout %}

## TL;DR instructions:

1. Ensure you've got [Family Sharing](https://support.apple.com/en-us/108380) setup.
2. Search for and install
   [“Gertrude Blocker”](https://apps.apple.com/us/app/gertrude-blocker/id6736368820) from
   the app store _on your under 18 child's device._
3. Click the on-screen buttons, authorizing the installation with _your parent/guardian
   Apple ID_ and _your child's device passcode._
4. Test that it's working by _searching for a NEW phrase_ as previously loaded or searched
   GIFs will still be visible (including the default images that load first).
5. Reach out with any questions/comments via our [contact form](/contact)&mdash;we'd love
   to hear from you!

---

## Step-by-step instructions: {% id="step-by-step" %}

{% callout title="We're here to help!" %}

If you have trouble with any step of this process, or have any kind of question at all,
drop us a line at [our contact form](/contact). We'd love to hear from you, and we're
truly happy to help!

{% /callout %}

### Step 1. Ensure you have Family Sharing enabled

Your child needs to be a part of
[Apple Family Sharing](https://support.apple.com/en-us/108380) in order to have Gertrude
Blocker fully installed and protecting them. If you're not sure if you've done that, open
your own iOS device or Mac computer, and go to _Settings > Apple Account._ You should see
**Family**:

{% image src="lockdown-iphone/family-sharing.png" caption="If Family Sharing is enabled, you'll see this" alt="Setup Family Sharing to block #images GIFs" /%}

You'll need to be either an _Organizer_ or a _Parent/Guardian_ to authorize the
installation. Click on _Family_ to check:

{% image src="lockdown-iphone/parent-guardian-organizer.png" caption="You need to be an Organizer or Parent/Guardian" alt="Setup Family Sharing to block #images GIFs" /%}

Finally, make sure the Apple Account for the child you want to protect has a listed age
**less than 18.** Apple does not network allow content filters to be installed unless the
account is for a child under 18.

### Step 2. Install the app on your child's device

On your **child's iPhone** or iPad (not yours), open the App Store (you may have to
temporarily enable this with Screen Time, if you have that functionality restricted), and
search for **"Gertrude Blocker".**

{% image src="lockdown-iphone/search-gertrude-blocker.png" caption="On your child's device, search for 'Gertrude Blocker' and tap 'Get'" alt="Search for 'Gertrude Blocker' in the App store to block #images GIFs" /%}

### Step 3. Open the app and follow the onscreen instructions

After launching the app for the first time, and clicking past the welcome screen, click
the **Start authorization** button:

{% image src="lockdown-iphone/start-authorization.png" caption="<b>1)</b> After the welcome screen, click 'Start authorization'" alt="Start the authorization process to block GIFs on your childs iPhone" /%}

{% image src="lockdown-iphone/allow-access-screen-time.png" caption="<b>2)</b> Click 'Continue' to allow access to Screen Time" alt="Click 'Continue' to allow access to Screen Time" /%}

{% image src="lockdown-iphone/allow-with-icloud.png" caption="<b>3)</b> Click 'Allow with iCloud Sign-in'" alt="Click 'Continue' to allow access to Screen Time" /%}

At this point, you need to enter the Apple ID email and password for an _Organizer_ or
_Parent/Guardian_ of your Apple Family, which should be you.

{% image src="lockdown-iphone/install-filter.png" caption="<b>4)</b> Next, click 'Install filter'" alt="Almost there, click 'Install Filter'" /%}

{% image src="lockdown-iphone/filter-network-content.png" caption="<b>5)</b> Then click 'Allow'" alt="Click to allow Gertrude to filter network content" /%}

{% image src="lockdown-iphone/enter-passcode.png" caption="<b>6)</b> Enter the passcode for your <b>child's device</b>" alt="Enter the child's device passcode to block GIFs" /%}

{% image src="lockdown-iphone/gertrude-approved.png" caption="<b>7)</b> You should see a message like this&mdash;click 'Done'" /%}

{% image src="lockdown-iphone/filter-installed-success.png" caption="<b>8)</b> Then this screen&mdash;click 'OK &rarr;'" /%}

Once the authorization and installation are complete, you'll see the final screen shown
below, and you're welcome to quit the app&mdash;it doesn't need to be running to keep
blocking.

{% image src="lockdown-iphone/gertrude-blocker-running.png" caption="Success! GIFs and more are blocked" /%}

You can also see that Gertrude is correctly installed under **Settings -> Screen Time**,
where you should see a toggle showing that Gertrude has _access to Screen Time._

{% image src="lockdown-iphone/screen-time-access.png" caption="Don't worry, your child can't disable this" /%}

## Step 4. (Optional) Test out the blocker

If you'd like to verify that the blocker is working correctly, there is **one thing you
should know**: any images previously viewed or searched for (including the images that
load before any search is made) will **still be visible**.

{% image src="lockdown-iphone/cached-images.png" caption="Previously downloaded images will still be visible..." /%}

Therefore, to verify it's working **enter a completely new search phrase** and you should
see only **empty gray boxes**, which shows that the blocker is working correctly:

{% image src="lockdown-iphone/blocked-images.png" caption="Entering an unused search phrase shows only blocked images: it's working!" /%}

Or, you can check that **Spotlight image searching** now turns up only empty placeholders
by searching your phone. (Note: this feature can be disabled under Settings -> Search ->
Show Related Content &mdash; but parents have no way in iOS 18 to restrict children from
re-enabling it.)

{% image src="lockdown-iphone/blank-spotlight-images.png" caption="Spotlight image search should show empty images" /%}

Once again, if you have any **questions or comments,** we'd love to hear from you. Drop us
a message through our [contact form here](/contact).

{% callout title="Help keep more kids safe!" %}

If you appreciate Gertrude Blocker, we'd be so grateful if you took just a minute to leave
us a
[positive rating on the App store,](https://apps.apple.com/us/app/gertrude-blocker/id6736368820)
and it will help other parents find the app and keep their kids safe. Thanks!

{% /callout %}
