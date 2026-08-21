---
title: How to Restart Gertrude’s Mac Filter
description:
  'Manually remove and restart Gertrude’s Mac internet filter when it cannot communicate
  with the menu bar app.'
products: [mac]
platforms: [macos]
---

The Gertrude macOS app is really two apps in one—the main _user-facing app_ with the menu
bar icon, and the _internet filter system extension_. The filter runs as a separate
process under a separate user so that it can filter network traffic. These two apps have
to communicate, and sometimes that communication breaks down. Usually the health-check
screen can both diagnose and fix this sort of problem, but sometimes you’ll need to
manually remove the filter in order to get things working correctly again.

## Manually remove the filter

Open the **Apple menu** and go to _System Settings → Network_. Next, click _Filters_. You
should see the Gertrude filter listed under “Filters & Proxies.” Select it and click the
_minus icon_ to remove the filter.

Once you’ve removed the filter, you should be able to restart it from the Gertrude app
menu bar dropdown, and it’s likely the connection and communication will be reestablished.

## Restart the computer

In some rare cases, especially when the app and the filter can’t seem to communicate, and
no other steps have fixed it, fully shutting down and restarting the computer often will
fix the problem.
