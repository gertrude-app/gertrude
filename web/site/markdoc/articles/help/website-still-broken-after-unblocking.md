---
title: Why a Website Still Looks Broken After You Unblock It
description:
  'Learn why one website may need several Gertrude keys and what to do when a page loads
  only partially.'
products: [mac]
platforms: [macos]
---

Most websites load content from several domains, not just the address shown in the
browser. A page’s images, styles, videos, sign-in system, or other features may come from
separate domains.

If you unblock only the main website, the browser may receive enough to display the page
but not enough to make everything work. The result can be missing images, broken buttons,
blank video players, incorrect formatting, or a sign-in that never finishes.

{% image src="nat-geo-partially-unblocked.png" caption="A website can load partially while supporting domains remain blocked" alt="A partially loaded National Geographic Kids page with missing images and video" /%}

## What to do

1. Check whether Gertrude has a **public keychain** for the website. Public keychains
   already contain the supporting keys needed by many popular services.
2. If you’re using your own keychain, open Gertrude’s **Blocked Requests** window on the
   child’s Mac.
3. Filter the list by browser, clear old requests, reload the broken page, and pause the
   new requests.
4. Send the necessary requests to the parent to review and add to the website’s keychain.
5. Reload the website after the parent approves the requests.

See
[how to diagnose blocked network requests](/help/mac/diagnose-blocked-network-requests)
for the complete process.

## If no new requests appear

Make sure the keychain is assigned to the correct child and click **Save settings** on the
parent website. Also check whether the keychain has a schedule or whether an
**Always-Blocked** rule applies. Always-Blocked rules take priority over keys.

For a deeper explanation of domains, keys, and keychains, read the
[guide to unblocking websites and apps on a Mac](/guides/unblocking-websites-and-apps-on-mac).
