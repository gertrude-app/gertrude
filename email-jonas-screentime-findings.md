Hey Jonas,

I spent some time this week trying to recreate what happened with your Screen Time setup
after supervision, and I wanted to share what I found — partly because I think it explains
a lot of what you ran into, and partly because I'm hoping you might remember a few more
details that could help us smooth this out for other users.

Here's what I did: I took a test iPhone and set it up to mirror what you had before
Gertrude — Screen Time on with a passcode, Content & Privacy Restrictions enabled, Safari
toggled off, and App Store toggled off. Everything else working normally. Then I went
through the Gertrude supervision process.

What I found was pretty surprising. Right after the device came back from the supervision
reboot — before I even installed the Gertrude profile — Safari and the App Store were both
back on the home screen and fully usable. When I went into Screen Time settings, the
toggles for Safari and iTunes Store still showed as OFF, but iOS just wasn't enforcing
them anymore. It's like supervision puts the device into a state where it expects an MDM
profile to handle app restrictions instead of Screen Time, so it silently stops honoring
those Screen Time settings.

The Gertrude profile itself (the part you download from the app) didn't make things any
worse — the Screen Time override had already happened just from supervision alone.

Here's the interesting part: when I toggled Content & Privacy Restrictions off and then
back on, it actually kicked Screen Time back into working. Safari and App Store
disappeared again, and all my other apps were still fine. So cycling that toggle seems to
be a workaround, though obviously not something anyone would think to try on their own.

I wasn't able to reproduce the "only have access to like 5 apps" situation you described
though, which is why I'm reaching out. On my test device, the only issue was Safari and
App Store coming back — I never lost access to other apps. So I'm curious:

Do you remember what steps you took when you were trying to fix things? Like, did you go
into the Allowed Apps list and change any toggles, or reset Content & Privacy
Restrictions, or anything like that? Any details you can remember about what you were
doing right before you ended up with only 5 apps would be really helpful for us to figure
out exactly what went wrong and make sure it doesn't happen to other people.

Thanks again for your patience with all of this — your input and feedback is really
helping us make Gertrude better for other users in the future.

Jared
