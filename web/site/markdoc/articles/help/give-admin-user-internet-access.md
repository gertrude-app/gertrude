---
title: How to Give a Mac Admin User Internet Access
description:
  How to exempt a password-protected Mac administrator account from Gertrude’s internet
  filter.
products: [mac]
platforms: [macos]
---

_TL;DR_&mdash;Sign in as your child, open the "Health Check" screen, click the icon that
looks like three people on the left-side of the window, then click to allow unrestricted
access for the admin user account.

{% image src="exempt-users.png" caption="Exempt an admin user from filtering" /%}

If you share a computer with your kid, and the Gertrude app is installed on their macOS
user, the filter will by default block all the internet requests from every other user on
the computer. That's because the Gertrude filter system extension runs as `root` and has
to make a decision about every network request attempted by every user on the system. For
maximum safety, I built Gertrude to be _very defensive_, when in doubt, it always takes
the most safe option, which is to forbid network requests for users it has no instructions
about.

Therefore, you need to explicitly instruct the filter about macOS users who should be
_exempt from filtering_. To do this, sign in as the macOS user being protected by
Gertrude. Click the Gertrude menu bar icon, then click the **gear icon** and choose the
_Exempt Users_ option from the left sidebar, then click to exempt the user.

{% callout type="warning" title="Be careful with exemptions!" %}

It's critical that any user that is exempt from filtering be **protected by a password**
that is unknown to any of your kids. Otherwise, they would be able to sign in to the
exempt user and have unrestricted internet and no monitoring from the Gertrude app.

{% /callout %}
