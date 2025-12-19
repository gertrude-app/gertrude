---
title: Troubleshooting Problems
description: Some basic tips and tricks for troubleshooting Gertrude
---

{% .lead %} Try these troubleshooting tips and tricks if something isn't working quite
right with Gertrude.

## 1. Run the health-check

The Gertrude app has a built-in _health-check_ feature that tries to diagnose and alert
you of common issues with the app. To access it, click the **gear icon** ⚙️ from the
Gertrude menu bar icon dropdown, as shown below:

{% image src="administrate.png" caption="Click the gear icon ⚙️ to reach the health check" /%}

The health check screen runs a series of tests on your Gertrude installation, and reports
the results. You should have all _green check marks_, unless you're intentionally not
using the filter.

{% image src="health-check.png" caption="The health check screen" /%}

Try to resolve any issues it points out&mdash;for most issues it is able to suggest a
solution, or provide an action for you to take to remedy the issue. If you have any
questions about warnings or errors you don't understand or don't know how to fix, please
[contact us](https://gertrude.app/contact) for help.

## 2. Isolate network activity

If your problem involves _not being able to figure out what needs to be unblocked_ or _why
something you think should be unblocked is not,_ try these tips:

- **Close every other app** except the one you're working with. Almost all apps are
  constantly making network requests, most of which Gertrude will be blocking, which makes
  it hard to figure out which block is actually causing you a problem. Quitting all other
  apps greatly reduces the number of network requests you'll have to consider.
- **Close other tabs** if you're working with a web browser, this also greatly eliminates
  noise and makes it easier to find the right request.
- **Be sure to clear and filter requests**. Enter a _search phrase_ into the filter field
  of Gertrude's network activity screen. Usually part of the name of a website, or the app
  you're using are helpful. Click the _clear requests_ button, then refresh the page, then
  _pause_ the requests&mdash;you should see only the important blocked requests at that
  point.

{% image src="filter-requests.png" caption="<b>Filter</b> by a search phrase, </b>clear</b> often, and <b>pause</b> after refreshing" /%}

- For more detailed information on unblocking websites and apps, see our article on
  [unblocking](/docs/unblocking-guide)
- Still struggling? [Contact us](https://gertrude.app/contact) for help.

## 3. Manually remove the filter

The Gertrude macOS app is really two apps in one&mdash;the main _user-facing app_ with the
menu bar icon, and the _internet filter system extension_. The filter runs as a separate
process under a separate user so that it can filter network traffic. These two apps have
to communicate, and sometimes that communication breaks down. Usually the health-check
screen can both diagnose and fix this sort of problem, but sometimes you'll need to
manually remove the filter in order to get things working correctly again.

To do this, go to  -> _System Settings &rarr; Network_. Next, click _Filters_. You should
see the Gertrude filter listed under "Filters &amp; Proxies." Select it and click the
_minus icon_ to remove the filter.

Once you've removed the filter, you should be able to restart it from the Gertrude app
menu bar dropdown, and it's likely the connection and communication will be reestablished.

## 4. Restart the computer

In some rare cases, especially when the app and the filter can't seem to communicate, and
no other steps have fixed it, fully shutting down and restarting the computer often will
fix the problem.
