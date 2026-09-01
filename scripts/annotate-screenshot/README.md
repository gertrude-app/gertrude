# Screenshot annotation

Tooling for the purple arrows and highlight boxes used in the marketing site's
step-by-step guides (`web/site/markdoc/articles/`). Everything is ImageMagick, so it's
scriptable and repeatable — no design app in the loop.

Requires `magick` (ImageMagick 7, with librsvg) and `pngquant`, both via Homebrew.

## Arrows

```bash
./place-arrow.sh <src> <out> <width> <angle> <l|r> <tipX> <tipY>
```

Aims by **arrow tip** — give it the coordinate you want the point to land on and it works
out the placement, including under rotation. Negative angle rotates counter-clockwise. Run
it repeatedly, feeding each output back in as the next input, to stack several arrows on
one screenshot.

The arrow itself is `arrow.svg`, traced from the pre-existing guide screenshots, so new
images match the ones drawn by hand years ago. It's vector, so it stays crisp at any size
or angle.

## Highlight boxes

```bash
./place-box.sh <src> <out> <x> <y> <w> <h> [stroke] [radius]
```

Used to ring a column of related settings (e.g. a stack of toggles). Leave roughly 60px of
padding around the content — tight boxes read as cramped.

## House style

- Arrow fill `#D29EF9`, box stroke `#DC9BFF` — deliberately different, matching the
  originals.
- Both carry a soft drop shadow so they read over light and dark UI alike.
- Point at the row or control, not over its label. If an arrow buries text, shift the tip
  along the row or flatten the angle rather than shrinking the arrow.

## Sizing and file size

Source screenshots at **~900px wide** and render them at 450 CSS px via the `width`
attribute on the markdoc `image` tag:

```
{% image src="lockdown-iphone/foo-ios26.png" width=450 caption="..." /%}
```

Without `width`, an `<img>` renders at its intrinsic size, so a 2x image displays twice as
large as its neighbors. See `web/site/components/articles/ArticleImage.tsx`.

Then compress — this routinely cuts 80-90% with no visible banding:

```bash
magick in.png -alpha off -strip tmp.png
pngquant --quality=80-95 --speed 1 --strip --force --output out.png tmp.png
```

`-alpha off` matters on its own: iOS screenshots often carry a fully-opaque alpha channel,
and dropping it alone can halve the file.

## Sourcing screenshots

Prefer the **iOS Simulator** for Settings screens — blank slate, no personal data, and you
can reach fresh "never configured" states a real device can't return to. Use a **real
device** for Communication Limits, Allowed Contacts, the home screen, and anything App
Store-related; those are missing or fake in the simulator.

AirDropped files keep their original capture timestamp, so `ls -lt` won't surface them.
Find them by when they landed:

```bash
mdls -name kMDItemDateAdded -raw ~/Downloads/IMG_1234.PNG
```

Crop full-width where possible and let the resize to 900px do the downscaling; cropping
horizontally first throws away resolution you'll want.
