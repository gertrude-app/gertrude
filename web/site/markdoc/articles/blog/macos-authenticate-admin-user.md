---
title: 'Authenticate an Admin User in a MacOS App'
date: '2021-04-19T11:28:05.000Z'
slug: macos-authenticate-admin-user
description:
  I needed to challenge for an admin _user/password_ to protect an area of a MacOS app I'm
  developing. After much pain and sorrow navigating the incredibly lacking and confusing
  Apple documentation, I got the basic challenge working.
category: engineering
---

I needed to challenge for an _admin user/password_ to protect an area of a MacOS app I'm
developing. After much pain and sorrow navigating the incredibly lacking and confusing
Apple documentation, I got the basic challenge working with the below code:

```swift
func authenticateAsAdmin() -> Bool {
  guard
    let authorization = SFAuthorization.authorization() as? SFAuthorization,
    let right = NSString(string: kAuthorizationRuleAuthenticateAsAdmin).utf8String
  else {
    /* or maybe throw an error */
    return false
  }

  do {
    try authorization.obtain(
      withRight: right,
      flags: [.extendRights, .interactionAllowed, .destroyRights]
    )
  } catch {
    return false
  }

  return true
}
```

Note I'm using the default `kAuthorizationRuleAuthenticateAsAdmin` _right_, which means
that I'm prompting for the generic system _admin_ right. This means that with the above
code I'm not able to customize the `"Acme App wants to make changes"` message that appears
in the dialogue. Creating a _custom right_ apparently is
[the more recommended way to do this](https://developer.apple.com/forums/thread/675712),
but for my use case, this worked and I can accept the lack of ability to change the
dialogue message.

The `.destroyRights` flag means (I think) that the system doesn't hang on to the
authentication for any length of time, ergo every time I call this function the user must
enter an admin user/pass _even if they just succeeded in doing so a few moments before_.
This is what I wanted for my app, but you can experiment with removing this flag.

In the thread where I was hashing this out on the Apple dev forum, Quinn helpfully posted
some sample code for the lower-level (and extremely scantily documented, at least in
Swift) `AuthorizationCreate()` function, here's
[the link](https://developer.apple.com/forums/thread/675712).

**Important Note:** This will _not work_ if your _app is sandboxed_, because of
privilege-escalation concerns. And if you forget to disable app-sandbox, you'll just get
cryptic non-helpful permission denied errors that don't mention anything about app
sandbox.
