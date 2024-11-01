---
title: The Definitive Guide to Locking Down an iPhone (iOS 18)
date: '2024-11-01T17:49:26.487Z'
image: /og-images/lockdown.en.jpg
description:
  A step-by-step guide to completely locking down an iPhone or iPad for iOS 18, for
  parents who are serious about protecting their kids from the dangers of unrestricted
  online activity.
category: parental-controls
---

{% .lead %} With a little hard work, it's possible to entirely lock down an iPhone or iPad
so that it is _extremely safe_ for your child to use. Apple gives parents most of the
tools they need to control access, apps, and internet content. The bad news is that these
controls are scattered over an unintuitive hodge-podge of settings screens, there are
several important loopholes that are easy to miss, and a few gotchas that require extra
steps to patch. This tutorial will walk you step-by-step through the entire process.

{% callout title="Using an older iOS version?" %}

This guide is designed for _iOS 18_, which was released in September 2024. If your child
is still on an older version of iOS, the steps are similar, but not identical. We continue
to maintain guides for both
[iOS 16](/blog/ios-16-definitive-guide-to-locking-down-an-iphone) and
[iOS 17](/blog/ios-17-definitive-guide-to-locking-down-an-iphone).

{% /callout %}

## What do you mean by _safe?_

Many parents naively think that the primary danger posed by internet-connected devices is
that they could allow **predators to gain access to your child.** While this is a
legitimate danger and a horrific tragedy whenever it occurs, it is nevertheless
**relatively rare** and often distracts parents from dealing with the dangers which
**almost certainly will affect their kids.**

{% image src="lockdown-iphone/computer-fear.jpg" alt="" /%}

What is sadly **unbelievably common** is for adolescents of both sexes&mdash;because of
their own innate curiousity, surging hormones, and lack of impulse control&mdash;to
develop lifelong addictions to pornography or to be deeply scarred by engaging with other
types of socially and emotionally damaging content and behavior on the internet.

You wouldn't fill your child's closet with hard-core adult magazines and hope they would
have enough self-control to never look inside. Giving your child a phone that is not
thoroughly locked down is _exactly the same._

As unpleasant as it might be, it's worth familiarizing yourself with some of the
[heart-breaking statistics](https://www.guardchild.com/statistics/), like:

- 90% of children ages 8-16 have seen online pornography
- 70% of children ages 7-18 have _accidentally_ encountered porn searching the web while
  doing homework
- the largest group of internet porn consumers is children ages 12-17
- 22% of teenage girls say they have posted nude or semi-nude photos of themselves online
- 10% of all material on the internet is porn

## The Safest Phone is No Phone

Before you get to work locking down your child's iPhone with this tutorial, I'd be remiss
if I didn't advocate for what I think is the simplest and most effective way to protect
your child, and that is&mdash;**don't give them a phone**. It's become incredibly common
for almost all kids to have phones, but it truly doesn't have to be that way. I would
highly advise you to hold out as long as you possibly can before giving your kids a phone.
And if you already have given them one, think hard about taking it back.

I am the father of four children (currently 18, 17, 14, and 10), and only my oldest two
kids have phones. My oldest only got his phone a few weeks _after_ his 16th birthday, and
my second at a similar age. Many generations of kids have survived their pre-teen and
adolescent years without a phone, and yours can too. I realize it's going against an
extremely strong societal norm, but absolutely nothing beats the simplicity and safety of
them simply not having a phone. And there's a growing amount of
[research](https://www.frontiersin.org/articles/10.3389/fpsyt.2021.669042/full) showing
that you might be greatly helping their cognitive and emotional development.

{% callout title="iPhones, iPads &nbsp; . . . and Androids" %}

For brevity's sake, the rest of this tutorial only refers to **iPhones**, but these steps
work the same for **iPads.**

However, none of what you'll find below applies to **Android phones or tablets**. While
there certainly are some tools and apps for parental controls on an Android, in my
opinion, they are **far less powerful and safe** than the deeply integrated controls Apple
provides. It's enough of a difference to warrant spending the extra money on an Apple
device, or considering a phone designed for parental controls like
[Gabb](https://gabbwireless.com/) or [Bark](https://www.bark.us/bark-phone/) rather than
an Android.

{% /callout %}

## Screen Time plus Gertrude

{% image src="lockdown-iphone/gertrude-and-screentime.png" alt="Gertrude + Screen Time gives parents complete control of their kids' iOS devices" /%}

In previous versions of iOS (iOS 16 and below), it was possible to completely lock down an
iPhone using only the built in Apple Screen Time features. Sadly, in iOS 17, Apple
introduced a [serious loophole in Screen Time](/blog/ios-17-cant-delete-messages-images)
that has not been fixed in iOS 18, and iOS 18 introduced
[another loophole](/blog/ios18-screentime-what-parents-should-know). Apple has been made
aware of these issues many times, but seems to have no interest in fixing them.

So, in October 2024, we [released an iOS app](/blog/gertrude-ios-released) specifically to
close these loopholes. At the time of writing, we know of no other way to close these
loopholes, so we recommend following the below steps to first install the Gertrude app,
and then proceed with carefully locking down the rest of the device using the built-in
Screen Time controls.

## Step 1: Install Gertrude

In order to use the Gertrude iOS app, you'll need to have **Family Sharing** set up using
a parent's Apple Account. Because of limitations set by Apple, the Gertrude app can only
be installed on a child's device if they are _under 18 and part of a Family Sharing
group._ [See here](https://support.apple.com/en-us/108380) for instructions on how to set
up Family Sharing if you haven't done so already.

{% click-to-reveal title="What about people over 18?" %}

If you're trying to lock down a phone for yourself, or a child over 18, you've got a few
options:

- Log their device into the Apple Account of a younger sibling
- Alter the birthdate of their Apple Account if you feel comfortable with that
- Proceed with the rest of the steps in this tutorial, without using Gertrude Blocker. The
  device will still be much safer than it was before.

You might also explore
[supervised mode](https://www.techlockdown.com/blog/screen-time-alternative)&mdash; which
give extra controls and works for any age. We're hoping to eventually make Gertrude
Blocker compatible with supervised mode as well. For now it's not, but supervised mode
does allow you to block the #images feature in Messages.

{% /click-to-reveal %}

Next, on your child's device, open the **App Store** and search for
["Gertrude Blocker"](https://apps.apple.com/us/app/gertrude-blocker/id6736368820). Install
the app, launch it, and follow the authorization instructions to install the internet
filter. The parent will be prompted to authorize the app using their Apple ID/Account, as
well as the child's device passcode. For detailed, step-by-step instructions on installing
Gertrude Blocker,
[see here](/blog/how-parents-can-block-images-gif-search-ios-18#step-by-step).

Once you've got Gertrude Blocker running, you'll see this screen, and you can proceed to
the next steps.

{% image src="lockdown-iphone/gertrude-blocker-running.png" alt="Gertrude Blocker blocks #images GIFs and other Screen Time loopholes" /%}

## Step 2: Delete apps

The iPhone comes with many built-in apps, and before you started working to lock down your
child's phone, you or they may have installed more. Therefore, the first thing you should
do is _delete every single app_ that they don't need or you haven't thoroughly checked for
safety. A child's phone is a tool, not an entertainment device. It should definitely
**not** allow them to surf the web, play non-educational games, search for and install
apps, or access music, videos, or social media content from the internet.

To delete an app, tap and _hold_ it's icon, until you see the option to _remove_ it:

{% image src="lockdown-iphone/remove-app.png" alt="locking down an iPhone: how to delete an app" /%}

Then tap to _delete the app_:

{% image src="lockdown-iphone/delete-app.png" alt="locking down an iPhone: confirm deleting an app" /%}

{% callout %}

For some reason, a few of the apps provided by Apple **do not give you the option to
delete** them&mdash;they only allow you to remove them from the home screen. If you
encounter some of these, don't worry, we'll vanquish them with the techniques explained
below.

{% /callout %}

{% callout type="warning" %}

Both the **Apple Maps** and **Google Maps** apps can be used to view **nude photos,** and
should be deleted. For more details (including a recommendation for a replacement),
[see here](/blog/five-things-you-forgot-when-locking-down-your-kids-iphone#4-explicit-images-in-maps-apps).

{% /callout %}

## Step 3: Disable Siri Integrations

The next thing you need to do is take a moment to _disable Siri integration settings_.
It's important to do this _before_ disabling Siri entirely via Screen Time (explained
below) because once Siri is disabled, these options are no longer visible, but are still
in effect.

{% callout title="Why disable Siri?" %}

Siri is a useful tool, but many parents don't realize that Siri has privileged access to
the internet, and can present your child with images and information retrieved from the
internet in many contexts. For kids, the safe route is to disable Siri as much as
possible.

{% /callout %}

Start by going to the main **Settings App**.

{% image src="lockdown-iphone/main-settings-app.png" caption="Go to the main <b>Settings</b> app" alt="locking down an iPhone: the main Settings app" /%}

Scroll down, and tap **Siri**.

{% image src="lockdown-iphone/siri-settings-ios18.png" caption="Tap Siri" alt="locking down an iPhone: Siri settings" /%}

Then **disable** all the settings shown below:

{% image src="lockdown-iphone/disable-siri-1-ios18.png" caption="Turn these settings OFF..." alt="locking down an iPhone: disable all Siri system integrations for safety" /%}

{% image src="lockdown-iphone/disable-siri-2-ios18.png" caption="...and <b>all</b> of these settings OFF" alt="locking down an iPhone: disable all Siri system integrations for safety" /%}

## Step 4: Disable Search Settings

Next, take a moment to disable two search-related settings. These are often missed by
parents, but enable your childs device to present images and content from the internet
when searching their phone or looking up words from many apps. Sadly, these settings
cannot be restricted by Screen Time, which means that your child can re-enable them if
they know where to look. This is one of the loopholes closed by the
[Gertrude Blocker](/blog/how-parents-can-block-images-gif-search-ios-18) app. But if you
haven't installed it, it's still worth taking a moment to disable these, in hopes your
child does not know how to re-enable them.

Start by going to the main Settings app once again, and this time choose **Search**:

{% image src="lockdown-iphone/search-settings-ios18.png" caption="Tap Search" alt="locking down an iPhone: Search settings" /%}

Then disable these two settings:

{% image src="lockdown-iphone/disable-spotlight-ios18.png" caption="Disable both of these" alt="locking down an iPhone: Keep your child from looking up images and other internet content" /%}

## Step 5: Enable All Screen Time Features

Now that we've got apps deleted and Siri integrations turned off, we'll turn our attention
to **Screen Time**, which is the main tool Apple gives you to lock down an iOS device. You
may already be familiar with Screen Time, because many adults use it to track how much
time they spend on their phones, which is one of it's primary purposes. But it also has
some really powerful features to _completely control what your kid has access to._

To get started, go to **Settings &rarr; Screen Time**, as shown below:

{% image src="lockdown-iphone/settings-screentime-ios18.png" caption="Settings &rarr; Screen Time" alt="locking down an iPhone: start at 'Settings' -> 'Screen Time'" /%}

If you've never interacted with Screen Time on the device, you'll need to enable **App &
Website Activity** in order to see all of the controls we'll be referencing later on in
this tutorial. If your screen doesn't look like this, that's OK, it probably means you've
already done this step. Skip to the next section.

{% image src="lockdown-iphone/enable-app-website-activity-ios17.png" caption="If your screen looks like this, click 'App & Website Activity'" alt="locking down an iPhone: Turn on App & Website Activity" /%}

{% image src="lockdown-iphone/enable-app-website-activity-2-ios17.png" caption="Turning this on is required to access all the controls" alt="locking down an iPhone: Turn on App & Website Activity to access all of Screen Time's controls" /%}

## Step 6: Set a Screen Time Passcode

Next, scroll down and click **Lock Screen Time Settings.** You may not see this option if
you've already done this, which is fine.

{% image src="lockdown-iphone/lock-screentime-ios18.png" alt="locking down an iPhone: Lock Screen Time Settings" /%}

Which will bring up _this screen_ where you should enter and confirm a _4 digit passcode:_

{% image src="lockdown-iphone/set-screentime-passcode-ios18.png" caption="Set and confirm your UNIQUE passcode" alt="locking down an iPhone: when prompted, choose a unique passcode to protect Screen Time" /%}

{% callout type="warning" title="Choose a unique passcode!" %}

It's very important that you choose an **entirely new and random** 4 digit passcode.
Please do not use something easily guessable by your child, like a birthday, your street
address, your debit card pin, or any 4 digit number you may have ever used for a padlock
or alarm system, or anything like that. Most people re-use the same pins and combinations,
so if you don't choose something totally unique for this passcode, it's very likely your
child will be able to easily guess it.

{% /callout %}

{% callout type="warning" title="Careful with that passcode!" %}

**If your child is able to see you while you're entering this code,** it's extremely easy
for them to remember it. It's worth it to be _very paranoid_ about this. My friend's son
learned his parent's passwords by secretly watching them type, and ended up using their
devices to look at porn.

I make my kids look away whenever I'm entering a password, I frequently change my
passwords, and I'm especially careful with their Screen Time passcode&mdash;holding the
phone only inches from my chest when entering the numbers.

{% /callout %}

## Step 7: Downtime

The Screen Time controls have five main sections. We'll work through them one by one,
starting with **Downtime**, although we'll have the most to say about the fifth area,
which is the most important.

{% image src="lockdown-iphone/downtime-ios18.png" caption="Downtime" alt="locking down an iPhone: 'Downtime' controls, used to specify schedules for permitted activity" /%}

{% callout type="warning" title="I don't see these settings!" %}

If you don't see the **Downtime** and **App Limits** settings, you probably forgot to
enable **App & Website Activity** under 'Limit usage'. Enable that, and you should see
these options.

{% /callout %}

**Downtime** allows you to _enforce a scheduled period_ when your child has no access (or
limited access) to their device. While not strictly necessary to keep your kids safe,
enabling Downtime is almost always a good idea. Kids (especially teenagers) are often
awake for hours in the early part of the night, and if they have access to their phones
and are bored, bad things frequently happen. Restricting their device usage at night also
helps encourage good sleep habits.

Tap to enable a scheduled downtime, and set the schedule for a time that seems appropriate
for your child.

{% image src="lockdown-iphone/scheduled-downtime-ios18.png" caption="Enabled Scheduled Downtime" alt="locking down an iPhone: tap to enable scheduled Downtime" /%}

{% callout type="warning" %}

Be sure to select **Block at Downtime** as well (shown below). If you _don't_ enable it,
your child will be able to ignore the Downtime schedule, rendering it little more than a
suggestion.

{% /callout %}

{% image src="lockdown-iphone/block-at-downtime.png" caption="Turn on 'Block at Downtime'" alt="locking down an iPhone: be sure to turn on 'Block at Downtime', or else Downtime limits can be overridden by your child" /%}

## Step 8: App Limits

The next section in the main Screen Time settings area is for **App Limits**.

{% image src="lockdown-iphone/app-limits-ios18.png" caption="App Limits" alt="locking down an iPhone: App Limits settings" /%}

This tutorial won't cover App Limits in depth, because they're not central to protecting
your kids. Every app that could be dangerous should be completely blocked by techniques
shown later in this tutorial. If you have some apps that you only want grant limited time
for each day, then App Limits can be a useful tool for that end.

In my opinion, web-browsing (Safari) and all social media apps should be _entirely
eliminated_ from your child's iPhone, not regulated with time limits. Phones should
provide only tools for communication (email, phone, and texting), plus required safe apps
for school and work, as needed. Web browsing should only be done on a computer, ideally in
a public place, with a tool like [Gertrude for Mac](/) to restrict access and provide
supervision.

## Step 9: Communication Limits

Similar to Downtime, but a bit further down, are **Communication Limits**.

{% image src="lockdown-iphone/communication-limits-ios18.png" caption="Communication Limits" alt="locking down an iPhone: Communication Limits settings" /%}

The **Communication Limits** settings area (shown below) allows you to control who your
child can communicate with.

Depending on your particular situation, it might be wise and appropriate to limit
communication to specifically approved contacts, or prohibit communication during
Downtime. But as this area is not usually critical for safety and is highly dependent on
your child and unique context, we won't try to give any guidelines in this tutorial.

## Step 10: Always Allowed

The next main section in Screen Time settings is **Always Allowed**.

{% image src="lockdown-iphone/always-allowed-ios18.png" caption="Always Allowed" alt="locking down an iPhone: Always Allowed lets you specify apps not subject to Downtime" /%}

This section is a bit confusing. In my opinion it should be a screen within the Downtime
settings area. It's only normal purpose is to _bypass Downtime restrictions_ in certain
ways.

{% image src="lockdown-iphone/always-allowed-settings.png" caption="These settings allow you to <b>bypass</b> Downtime restrictions" alt="locking down an iPhone: Always Allowed settings let you pick apps that are not subject to Downtime schedule restrictions" /%}

A good example of a good _Allowed App_ would be the **Clock** app, if you wanted your
child to be able to use their iPhone as an alarm clock, and have access to set it after
their Downtime schedule kicks in.

You can also add exemptions for certain contacts that can always be contacted, no matter
what time it is. Used sparingly, these controls can provide a nice layer of needed
customization on top of the Downtime restrictions.

## Step 11: Content &amp; Privacy Restrictions

If your goal is to completely lock down your child's iPhone, making it a truly safe
device, most of the controls you're going to need to set are in the section labeled
**Content & Privacy Restrictions**:

{% image src="lockdown-iphone/content-privacy-restrictions-ios18.png" caption="Most of your work will happen in this section" alt="locking down an iPhone: The Screen Time > Content & Privacy Restrictions area is where most of the important controls and settings live" /%}

Start by tapping to _enable restrictions:_

{% image src="lockdown-iphone/enable-restrictions-ios18.png" caption="Toggle to enable Content & Privacy Restrictions" alt="locking down an iPhone: click to enable Content & Privacy Restrictions" /%}

### iTunes &amp; App Store Purchases

Then tap the section labeled _iTunes &amp; App Store Purchases_, shown below:

{% image src="lockdown-iphone/itunes-app-store-purchases-ios18.png" caption="Tap to go to iTunes & App Store next" alt="locking down an iPhone: Content & Privacy Restrictions > iTunes & App Store Purchases" /%}

For a safe iPhone, all three of these options should be set to **Don't allow**.

{% image src="lockdown-iphone/dont-allow-installing-deleting-apps.png" caption="<b>Don't allow</b> installing, deleting, or in-app purchases" alt="locking down an iPhone: don't allow installing apps, deleting apps, or in-app purchases" /%}

{% callout title="Managing Apps Over Time" %}

You can still add new apps you approve when you child needs them. You just temporarily
allow installing apps in this section, install the app, and then revoke the installation
privilege again.

Same with _deleting_ apps: just temporarily allow deleting, remove the app, and
re-disable.

{% /callout %}

### Allowed Apps &amp; Features

Next, tap the back button to get back to the _Content & Privacy Restrictions_ screen, and
then tap to select the second section, labeled **Allowed Apps**:

{% image src="lockdown-iphone/allowed-apps-features-ios18.png" caption="Go back one screen, then choose <b>Allowed Apps & Features</b>" alt="locking down an iPhone: Content & Privacy Restrictions > Allowed Apps & Features" /%}

This is another section that is a bit confusing at the outset, because there is another
screen at the main level called **Always Allowed** that looks very similar. That screen
let you exempt certain apps from Downtime. This screen lets you enable/disable apps
entirely, irrespective of Downtime.

This is an **extremely important area** because it's the only way you can disable/remove
certain apps, like **Safari**&mdash;the built-in app for surfing the web which is the
single most dangerous app on your child's iPhone.

{% image src="lockdown-iphone/disable-safari-siri-ios18.png" caption="Disable any apps you want to block. Be sure to disable <b class='underline'>Safari</b> and Siri" alt="locking down an iPhone: disable apps that Apple doesn't let you delete" /%}

Work through the list of apps, _leaving enabled **only the apps** that are truly
necessary, and you're **sure are safe**_. We encourage you to take a _very conservative_
approach: kids' phones should be very minimal. The more apps you allow, the more chance
you've accidentally opened up something that could allow them unrestricted access to the
internet.

{% callout title="How do I know if an app is safe?" %}

The only way to really know is to **thoroughly test** it. It's very important to
understand that apps with a very benign purpose can have **serious loopholes** you may not
have thought of.

**One story** might help drive this home. At one point I was considering allowing the
_Audible_ app (for listening to audiobooks) on an old phone we had lying around. I figured
as long as I controlled which books were downloaded (because my kids didn't have the
ability to purchase a new book), the app should be safe, right? I took a few minutes to
explore the app, and found that there was a feature where you could search for new
audiobooks. A few simple search terms filled the screen with **adult books with
semi-pornagraphic covers.** I deleted the app.

Whenever you're about to allow a new app, take 5 minutes exploring the app. Imagine
someone will give you $10,000 if you can find inappropriate content on it. You'd be
surprised how often you can.

{% /callout %}

{% callout title="What about web research?" %}

Kids shouldn't be doing homework research on a phone, period. For starters, a phone is not
the right tool for serious academic research. And further, researching on the web is
actually a very high-risk activity:
[70% of children](https://www.guardchild.com/statistics/) ages 7-18 have accidentally
encountered porn searching the web while doing homework.

In our household, research for homework is always done on a computer, either under direct
parental supervision, or with filtering and screen recording provided by the Gertrude app.

{% /callout %}

{% callout title="Do I need to disable Siri?" type="warning" %}

Parents often don't realize this, but having access to Siri puts the entire internet at
your child's fingertips. Even if you have Safari blocked, Siri offers an alternative
method of searching and browsing the internet. Your child can simply ask Siri to look
something up, and she will happily respond with snippets of content **including images**.

{% /callout %}

### Store, Web, Siri, Game Center

Next, tap the back button to get back to the _Content & Privacy Restrictions_ screen, and
then tap to move into the second section, labled **Store, Web, Siri & Game Center
Content**:

{% image src="lockdown-iphone/store-web-siri-gamecenter-ios18.png" caption="Go back one screen, then choose <b>Store, Web, etc...</b>" alt="locking down an iPhone: Store, Web, Siri & Game Center, where many of the most important settings live" /%}

Which brings you to this screen:

{% image src="lockdown-iphone/store-web-siri-gamecenter-settings-ios18.png" alt="locking down an iPhone: Screen Time > Content & Privacy Restrictions > Store, Web, Siri, Game Center" /%}

There's a lot to take in on this screen. Loads of different settings. Go through _each
setting_ one by one, _turning it to the **safest (or most disabled) option,**_ unless you
have a good reason to do otherwise. For example, anywhere it offers you the options of
"Clean" or "Explicit", choose "Clean", if it offers "Off" and "On" choose "Off", and if it
offers "Don't Allow" or "Allow" choose "Don't Allow".

{% image src="lockdown-iphone/clean-not-explicit.png" caption="choose CLEAN, OFF, or DON'T ALLOW for most options" alt="locking down an iPhone: choose 'clean', 'off', or 'don't allow' for most options in Store, Web, Siri & Game Center" /%}

Three of the sub-sections deserve particular attention, the first is **Apps**:

### Store, Web, Siri, Game Center &rarr; Apps

Within the same _Store, Web, Siri & Game Center_ section there is another section labled
**Apps**, as shown below:

{% image src="lockdown-iphone/store-web-siri-gamecenter-apps-ios18.png" alt="locking down an iPhone: the 'Apps' section has to do with app age ratings" /%}

In my opinion, this area should be renamed as well. It's confusing because this is the
third screen that seems to control access to apps, we've already seen _Always Allowed_
apps, and _Allowed Apps_, and now here we have just _Apps_.

The purpose of this area is really to control **what age rating** of apps may be
installed, which you can see from the drill-down screen:

{% image src="lockdown-iphone/app-age-rating.png" caption="This screen should be called <b>App Age Rating</b>" alt="locking down an iPhone: understanding the Store, Web, Siri & Game Center > Apps screen" /%}

Set this to `12+` or even `Allow All`&mdash;your child can't install apps anyway, and you
will be approving every app individually. Setting it too low can cause mysterious missing
apps (see below).

{% callout title="An app I installed for my child won't show up!" type="warning" %}

If you chose a very conservative value like `4+` for your app _age rating_, some apps you
want your kids to use may **dissappear**. To fix this, just make sure you have removed the
right to install apps, and then set the age limit to a higher level and the app should
reappear.

{% /callout %}

### Store, Web, Siri, Game Center &rarr; Web

The second area that requires some more detailed explanation is the **Web Content**
drill-down:

{% image src="lockdown-iphone/web-content-ios18.png" alt="locking down an iPhone: Web Content" /%}

It is critical that you choose **Only Approved Websites** for this section.

{% image src="lockdown-iphone/allowed-websites-only-ios18.png" caption="Make <b>sure</b> you select 'Only Approved Websites'" alt="locking down an iPhone: Store, Web, Siri & Game Center > Web Content should be set to 'Only Approved Websites'" /%}

Even if you have taken our recomendation to _entirely disable web-browsing by removing the
Safari app_, you still need to set this setting to _Only Approved Websites_. That's
because many apps have what amounts to a built-in web-browser, and reach out to the
internet to load content when your child is using them. Without this setting chosen,
otherwise safe apps can become alternative portals to the internet.

{% callout title="Why not 'Limit Adult Websites'?" type="warning" %}

It might be tempting to choose the second option: **Limit Adult Websites**, but we urge
you not to. If you do, you're trusting that someone has correctly identified and
categorized over 2 billion websites, and is staying on top of the nearly 250,000 new
websites being created every day. I've personally tested a filter that blocks **millions**
of known adult domains, and it still took only a few minutes to find explicit content that
was unblocked.

{% /callout %}

### Store, Web, Siri, Game Center &rarr; Siri

The third and final area that deserves special treatment is the **Siri &rarr; Web Search
Content:**

{% image src="lockdown-iphone/siri-web-search-content-ios18.png" alt="locking down an iPhone: be sure to disallow Siri > Web Search Content" /%}

Make sure you've got this set to **Don't Allow.**

## Step 12: Testing it Out

Once you've got all your settings dialed in, you'll need to spend a few minutes testing.
Exit out of the Settings app, and start kicking the tires. Check and make sure that no
apps are available that you did not intend to make available. Double-check that Siri is
not working. This would also be a good time to double-check all of your approved apps. Use
the thought experiment I proposed above: spend a few minutes with each app, imagining you
would immediately win $10,000 if you could find something inappropriate or dangerous.
Imagine you are a bored, impulsive, motivated teenager with a lot of persistence and time
on their hands.

## Step 13: Have the Right Mindset

I wish I could tell you that there's _"one simple trick"_ or some _silver-bullet
technology_ to easily and perfectly protect your kids in this new world we live in.
There's not. The reality is that **it's going to take time, effort, and diligence** to
keep your kids safe online. It will be _annoying, frustrating, and inconvenient_ at times,
and will interrupt your day frequently. There will be a _constant temptation to simplify
your life_ by disabling protections and telling yourself that "my kid will be OK."

But don't despair, this really is possible. An enormously important step is just to settle
it ahead of time that you're willing to put in the time and effort to actually keep them
safe. Your kids might moan and groan, but they'll survive&mdash;and thank you one day.
Stay the course, it's worth it.

Once you've got your kids iPhone locked down, I urge you to think carefully about their
**computer usage** as well. If your kid has a Mac, you might want to check out
[Gertrude](/), the app I built to keep my own kids safe while doing school online.

Finally, if you'd like some encouragement if you're feeling overwhelmed, plus general
techniques for working through this stuff with your kids while keeping your relationships
healthy, check out [this workshop I gave](https://youtu.be/syC94X5LBIc) at a Christian
Homeschool conference in 2024.

And please, let me know using the form below if you have any questions or difficulties
following this tutorial, I'd be happy to hear from you!

{% .border-b .border-slate-700 .mb-12 .mx-12 %}&nbsp;

{% callout %}

We also recommend you check the items in our article about
[things you probably forgot to lock down](/blog/five-things-you-forgot-when-locking-down-your-kids-iphone).

{% /callout %}

{% article-feedback-form name="lockdownGuide" lang="en" /%}
