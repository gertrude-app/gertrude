---
title: Unblocking Guide
description: Help for unblocking websites and apps
---

{% .lead %} Getting the websites and apps you need unblocked is one of the main tasks
you'll need to perform when working with Gertrude. This guide aims to help you understand
how and why this works the way it does, and give you some helpful tools for making this
job easier.

## IMPORTANT: Isolate network activity

Your computer is constantly making network requests to a myriad of websites and services.
The vast majority of these don't cause you any noticable problem, and don't need to be
unblocked. But, all those requests can make it _hard to find out which request DOES need
to be unblocked._ For this reason, probably the number one thing you can do to make it
easier to find what to unblock is **isolate network activity:**

- **Close every other app** except the one you're working with. This will greatly reduce
  the number of network requests you'll have to consider.
- **Close other tabs** if you're working with a web browser, this also substantially
  eliminates noise and makes it easier to find the right request.
- **Be sure to clear and filter requests**. Enter a _search phrase_ into the filter field
  of Gertrude's network activity screen. Usually part of the name of a website, or the app
  you're using are helpful. Click the _clear requests_ button and then refresh the page,
  or retry the activity that is not working.

{% image src="isolating-requests.png" caption="Filter by a search phrase, and clear often" /%}

## Why multiple keys are needed

One of the core things you need to understand is that when you're trying to unblock a
specific website, it often takes _several keys to get the site fully working._ It seems
like if I'm trying to unblock `happyfish.com`, I should be able to just create a key for
`happyfish.com`, and everything should just work, right? Sadly, no. To explain why, I'll
need to get just a little bit technical for a moment.

### How websites work

Websites are made up of _computer code_ written in 3 different languages: _html_, _css_,
and _javascript_. When you try to visit `happyfish.com` in a web browser, what happens
under the hood is that your computer makes first makes a network request to
`happyfish.com` in order to get the _html code_ for that site. _Inside the html code_ are
more web addresses, containing the location of the _css_ and _javascript_ code. So once it
receives the html, the browser reads it, and then **makes more network requests** to get
the _rest of the code_ it needs to properly display the website.

Very often, the _css_ and _javascript_ code is located on a **different domain** from the
one you're requesting. So, in our example, the _html_ for `happyfish.com` will be located
at `happyfish.com`, but the _css_ might be located at `static.happycdn.com`, and the
_javascript_ might be at `code.javascript-libraries.com`.

{% callout type="note" title="Terminology: domain" %}

A **domain** is the _root part of a web address,_ before any forward slashes. For
instance, the web address `https://cupcakes.com/halloween-sale` has the domain
`cupcakes.com`.

{% /callout %}

When Gertrude is protecting a computer, it has to make a decision about whether to block
or allow every new request to a new domain. So, if you create a key for just
`happyfish.com`, Gertrude will allow the _first request_ which fetches the html code. But
when the browser reads that html and realizes it needs to go to `static.happycdn.com` to
get the _css_, that request will be blocked by Gertrude. Sadly, there's no way for
Gertrude's filter to know that the request for `static.happycdn.com` is being made because
it is needed by a website that you already unlocked.

### Fixing partially unblocked websites

So, for our example, imagine you created unblocking `happyfish.com`. If you tried to visit
the site after creating this key, you'd probably notice the site loads, but _doesn't look
right_. That's because web browsers try to do the best with what they've got. They don't
show you an error message if they can't load some of the code they need, they just show a
partially working, or funny looking website.

To make this more concrete, consider the website `how-to-type.com`, which we use as an
example in our [getting started tutorial](/). If we only create a key for the main
`how-to-type.com` domain, the website loads, but looks a little funny, as shown below:

{% image src="allowed.png" caption="The site is loading, but if you look closely, all is not right..." /%}

If we pull up the Gertrude network request window, we'll still see that multiple requests
are being blocked when we try to visit the page:

{% image src="how-to-type-blocks.png" caption="After unblocking the domain, we still see all these blocked requests" /%}

There is a bit of an art to figuring out which of these requests should be unlocked, but
you'll get the knack of it. If you look closesly at the image above, several of the
domains are repeated twice, so there are really fewer domains to think about than it
appears. Also, there are a couple things we can ignore. The blocked request from the
`www.facebook.com` domain can (and _should_) be ignored&mdash;it's just a little embedded
"like" button that won't prevent the site from working correctly. And the one from
`google-analytics.com` is just a tracking website, its not necessary to unlock.

{% image src="analyzing-blocks.png" caption="Ignoring facebook and google analytics, there are 3 domains to be unblocked" /%}

You can create an _unlock request_ for all three blocks at once:

{% image src="triple-unlock-request.png" caption="You can create an unlock request for all three requests at once" /%}

Once these three domains are unlocked, the website loads!

{% image src="how-to-type-unblocked.png" caption="Success! With all the keys created, the site loads fully" /%}

### This sounds hard!

This may seem daunting to you, and if that's the case, it's OK. The difficulty of
unblocking websites is one of the reasons that most other safety solutions throw their
hands up and only block parts of the internet, instead of blocking everything and
requiring you to unlock specific sites. That approach, while easy, is **inherently
unsafe**. By choosing to use Gertrude, you are signing up for more work than those
solutions, but the payoff is immense: real internet safety. Not only is it really worth
the effort, but **there are several things that make this process easier:**

1. We have a growing list of _publicly available_ keychains which have all the keys
   necessary for popular websites. Often, you'll be able to just select a public keychain
   and the site will immediately work correctly.
2. The ability to send _unlock requests_ from the macOS app makes this process much
   easier.
3. As long as you don't unlock domains like `google.com` or `facebook.com` accidentaly,
   there's usually very little danger in unlocking a few of the wrong domains while you're
   hunting for which domain or domains still needs to be unblocked for a site.
4. You and your user/s will get good at this with a _little practice._
5. Once you have a site fully unlocked, with Gertrudes _keychains_ feature, you can easily
   _share the full set of keys_ with all of the users you are protecting&mdash;you won't
   have to repeat the process again.
6. You can always [reach out to us](https://gertrude.app/support) if you're having trouble
   getting a site unlocked.
7. We're exploring some ways to in the future try to _automatically discover and unlock_
   some or all of these other domains, so it's very likely this process will keep getting
   easier over time.
