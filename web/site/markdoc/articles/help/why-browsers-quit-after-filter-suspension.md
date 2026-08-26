---
title: Why Browsers Quit After a Filter Suspension
description:
  Why Gertrude closes browsers after temporary unrestricted internet access ends.
products: [mac]
platforms: [macos]
---

For maximum safety. Modern web browsers use `http2`, allowing them to _re-use socket
connections_ to transmit data. In English, what that means is that any websites your child
has opened during a filter suspension _will remain partially unblocked after the filter
suspension expires,_ as the browser will keep using a connection opened during the
suspension. To prevent this, we terminate all browsers 60 seconds after a suspension
expires.
