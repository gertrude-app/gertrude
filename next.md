Okay, so I'm just like a little bit paralyzed on where to start here. I think I want to
tackle the supervision use case first, and it's just such a big sweeping change to my
system that I'm a little paralyzed.

I'd like to think and work towards an MVP for walking someone through onboarding and
supervising their device with our new tool. What would be like the easiest way to kind of
get this into the code base and start seeing real people interact with it?

Now, part of what makes this so complicated and why I want help brainstorming is that I
have to think through how the supervision tool will even work. At its core, it's a little
app that supervises and unsupervises a phone. It's a desktop app. I already have that part
working, but I can integrate it into Gertrude in any way I want.

For instance, I can require that if you download the supervision app, then you have to
enter a six-digit token to basically connect it to a Gertrude account. The little desktop
app can make calls to our API, and it can do all kinds of back-and-forth stuff, reading
and writing things to our API via HTTP calls. The sky's the limit.

For the supervision process to work, or to be effective, basically what has to happen is
they need to download our tool to supervise their phone, and then they need to download a
mobile config profile. The iOS app needs to catch them at a state of like, "Oh, I'm not
under 18. What do I do?" and sort of say, "Hey, you need to set up a Gertrude account, and
you need to download this supervision tool."

They need a Mac or Windows computer because that supervision tool works on Windows as
well. I have to guide them through this process of, "Hey, go get an account going, and
then you can download the supervision tool, and we can get this special payload that's
going to allow Gertrude to work properly on your phone."

There's just a lot of moving parts and lots of ways. I just want to reduce as much
friction as possible. So, I was even thinking we could do something like when we get to
the point in onboarding where they say, "Oh, I'm 18 or older; I'm going to have to
supervise," we go and send an API request to our API to kind of pre—not create them an
account, but create a record.

Then, I could text them a link to kind of fast-mode their account creation so that if they
click this link, then when they create the account, we've already basically associated
some data about that iOS app so that it can all get hooked up for them. Then they can
download our tool, stuff like that.

But anyway, in order for you to help me think this through, it's important that you know
that kind of the workflow for getting this working with supervision is: they need to
download a little app from us. It takes about five minutes to run on their computer.

They need a computer, and they run through this process. It reboots their phone, and it
comes back up supervised. The reason that's necessary is that there's a second step where
we have to deploy a mobile config with a special payload that allows the content filter to
run.

So, there's like this two-step process. I've already explored and prototyped the fact that
we can pop up a Safari web view inside Gertrude and prompt them to download that mobile
config and install it, or they can just go to a regular Safari link potentially. But they
need to get that mobile config installed.

The reason why it's going to require a Gertrude account is that we want to make it so that
that profile can't be removed. I haven't fully figured that piece out yet, but I know it's
possible. Since we're going to prevent it from being removed, we need kind of this account
place where either an accountability partner, a parent of an adult child, or a spouse can
restrict them from removing this profile.

So, supervision is just a means to an end, but it's necessary. You cannot put a profile on
that allows these content filters unless it's supervised or the child's under 18. We're
already doing fine for everybody under 18; we're just trying to make this use case of over
18 much easier. It's not going to be as easy.

But anyway, that's kind of all the context. What I'd like you to do is think creatively
about all the dimensions of this problem, including the flow inside the app, the flow of
how a supervision tool would work and interact with an account, the possibility of doing
things like sending links to the device, universal links, app opening links, using QR
codes, just kind of all the different ways we could smooth the multi-step process, explain
it, and guide the most people through it.

I have some ideas, but I want to deeply brainstorm. For the time being, let's limit our
conceptual paradigm to assuming that these are parents trying to help adult children or
accountability partners and spouses. Let's kind of ignore the self-management use case
where somebody's trying to lock down their own phone and keep themselves out of it.

I'm interested in that in the future, but for now, let's just kind of focus on this idea
that like somebody else is going to have the Gertrude account and then the phone or device
owned by the person who's over 18 is going to be—that's going to be a different person.

Think about all that and explore parts of the code base as needed. If you need to, you can
poke around in the supervision tool code base; it's at `~/gertie/supervise`. You can read
the Claude.md file there to understand kind of how that works.

I'm going to give you one more URL that I want you to read from Tech Lab Lockdown because
they use basically a version of the same supervision tool and kind of walk people through
the same mobile config download process that we're going to have to do. But if possible,
I'd like to think outside of the box and do an even better job or innovate a little bit
beyond what they're doing. I think it would help if you understood what they were doing.

here it is:

https://www.techlockdown.com/guides/enable-supervised-mode-iphone
