---
title: Five Things You Forgot When Locking Down your Kid's iPhone
description: TODO
---

{% .lead %} Thanks to Apple's Screen Time app, it's possible to control very precisely
what your child can access on their iPhone or iPad. But the controls and settings are
surprisingly hard to use and get right. Here are 5 things that almost every parent misses
when first trying to lock down their child's iPhone. Grab your child's phone right this
minute and check if you missed any of these.

Consider something like: I consider myself pretty tech-savvy: I've been a softward
developer for 15 years, and have apps in the App store. When I locked down my son's first
iPhone, I was fairly confident I had covered all my bases. But then my more experienced
older brother shocked me by grabbing my son's phone and showing me numerous huge
loopholes. ... etc... something along those lines.

## 1. `#images` iMessage App

Apple's built-in **Messages** app comes with a growing number of app-integrations (called
`iMessage apps`) that allow for sending non-text items in text messages.

{% image src="lockdown-iphone/messages-images.png" caption="this row of mini-apps is shown when composing a text message" /%}

{% image src="lockdown-iphone/messages-images-zoomed.png" caption="close of up the '#images' app" /%}

If your child clicks on the `#images` app (shown above), they are able to _search through
a huge intentory of animated gifs_. The image below shows a harmless search query, but
there are loads of sexually suggestive and otherwise innappropriate images your child
shouldn't be able to browse.

{% image src="lockdown-iphone/searching-images.png" caption="Imagine I searched for something other than 'GOATS'" /%}

### How to fix it

To eliminate this app:

**1.** Start by scrolling to the _far right_ tapping on the **More** icon:

{% image src="lockdown-iphone/messages-more.png" caption="Scroll to the right and click this icon" /%}

**2.** Next, swift left to _remove the app from "Favorites"_.

{% image src="lockdown-iphone/images-remove-from-favorites.png" caption="Swipe left to remove from Favorites" /%}

**3.** Then the app will appear in the section labeled **MORE APPS**. Swipe left again in
this section to fully delete the app:

{% image src="lockdown-iphone/images-delete-app.png" caption="Swipe left to delete the app once and for all" /%}

**4.** Repeat for any other iMessage Apps that may already be installed. The `#images` app
is the main offender that comes pre-installed, but it's possible your child has already
installed other iMessage apps that expose them to undesirable content.

**5.** Ensure that your child doesn't have the ability to _re-install_ this (or any other)
app by going to "Settings > Screen Time > content & Privacy Restrictions > iTunes & App
Store Purchases" and choose _Don't Allow_ for "Installing Apps":

{% image src="lockdown-iphone/dont-allow-installing-apps.png" caption="Remove authority to install apps, or they can re-install" /%}

## 2. Spotlight Internet Searching

To test if your child's phone is vulnerable to this commonly missed item, _pull down from
the middle of the home screen_ to access the iPhone's build in _search prompt_.

{% image src="lockdown-iphone/spotlight-search.png" caption="Swipe down bring up Spotlight search, then type a query" /%}

After pressing _Search_, _Spotlight_ leverages _Siri_ to search the internet and return
results, **including images**. Imagine a less innocent search query than `goats`:

{% image src="lockdown-iphone/spotlight-search-results.png" caption="Spotlight search can pull images and other content from the internet" /%}

## 3. "Look Up" Internet Searching

Most apps that deal with text (like ebook readers, Bible apps, Notes, etc.) allow the user
to _highlight a search term and **"Look Up"**_.

{% image src="lockdown-iphone/look-up.png" caption="Highlight a word, then tap 'Look Up'" /%}

By default, your child's iPhone can access Siri (and through it, the whole internet), when
"looking up" words, and Siri frequently displays **images** in the result set.

{% image src="lockdown-iphone/look-up-results.png" caption="An example of images pulled from the web in response to a 'Look Up'" /%}

## 4. Siri Internet Searching

If you don't carefully disable Siri completely (which is not straightforward to do!) it's
easy to allow your child to search the internet (including seeing images) through Siri. To
test if your child's device is vulnerable, activate Siri and ask her to show you pictures
of something.

## scratch below

- 'don't allow deleting apps
-

## siri searching

- spotlight talking to Siri
-
- turn Siri on, go to "siri & search", turn of "show in spotlight"
- turn off

## look up

- hold down on Look up, like in bible app

## more...

- gifs when texting
- maps app?

## dictionairies

apple.com always, was there.

## maps (both google and apple)

- allow deleting apps,
- power off, then power up, then delete,
- then re-disallow deleting
- use Waze instead
