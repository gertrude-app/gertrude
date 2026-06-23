---
name: device-images
description:
  Update local Apple device artwork for the Dashboard_v2 from ipsw.dev. Use when asked
  to add, refresh, audit, crop, or wire up Mac, iPhone, or iPad model images in
  web/dashboard-v2/public/devices, especially after new Apple model releases.
---

# Dashboard Device Images Skill

Use this when updating local device artwork for `web/dashboard-v2/`.

The dashboard stores device images here:

- `web/dashboard-v2/public/devices/macs/`
- `web/dashboard-v2/public/devices/iphones/`
- `web/dashboard-v2/public/devices/ipads/`

The UI expects `.png` files named exactly by model identifier, commas included, e.g.
`Mac14,2.png`, `iPhone14,7.png`, `iPad13,18.png`. Do not URL-encode commas in local
image paths.

## Source pages

Fetch product pages from ipsw.dev:

- Macs: `https://ipsw.dev/product/Mac`
- iPhones: `https://ipsw.dev/product/iPhone`
- iPads: `https://ipsw.dev/product/iPad`

Use `curl -L -A 'Mozilla/5.0'`; other clients may get `403 Forbidden`.

Use PNG source URLs, not WebP, because the dashboard image helper emits `.png` paths:

```text
https://ipsw.dev/img/devices/<MODEL_IDENTIFIER>.png
```

## Supported iPhone/iPad cutoff

Gertrude iOS apps currently only support iOS/iPadOS 17+. Unless the app minimum OS has
changed, include only devices compatible with iOS/iPadOS 17 or newer.

Current practical filters for ipsw.dev model identifiers:

- iPhone: include `iPhoneN,*` where `N >= 11`
  - oldest included devices are iPhone XS / XS Max / XR (`iPhone11,2`, `iPhone11,4`,
    `iPhone11,6`, `iPhone11,8`)
  - exclude iPhone X / iPhone 8 and older (`iPhone10,*` and below)
- iPad: include `iPadN,*` where `N >= 7`
  - oldest included devices are iPad Pro 12.9-inch 2nd gen and iPad Pro 10.5-inch
    (`iPad7,1`-`iPad7,4`), plus iPad 6th gen (`iPad7,5`, `iPad7,6`)
  - exclude first-gen iPad Pro and iPad 5th gen (`iPad6,*` and below)

If the app minimum OS changes, re-check Apple's supported device lists and update these
filters before downloading.

## Cropping transparent padding

ipsw.dev images often contain transparent padding. Crop to the alpha-channel bounding box
with ImageMagick:

```bash
bbox=$(magick "$src" -alpha extract -format '%@' info:)
magick "$src" -crop "$bbox" +repage "$dest"
```

This trims excess transparent space around the actual device art.

## Audit missing images

Run this from the repo root to list identifiers present on ipsw.dev but missing locally.
It does not delete extra local files. Do not delete old Mac images without asking; ipsw's
Mac page focuses on newer Macs, while existing local Intel Mac artwork may still be useful.

```bash
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
for product in Mac iPhone iPad; do
  curl -fL -A 'Mozilla/5.0' -sS "https://ipsw.dev/product/$product" -o "$work_dir/$product.html"
done
python3 - "$work_dir" <<'PY'
from pathlib import Path
import html
import re
import sys

work = Path(sys.argv[1])
root = Path('web/dashboard-v2/public/devices')

def items(product):
    text = (work / f'{product}.html').read_text(errors='replace')
    for match in re.finditer(r"<a class='product group' href='/product/version/([^']+)'>.*?</a>", text, flags=re.S):
        identifier = html.unescape(match.group(1))
        block = match.group(0)
        name_match = re.search(r"<div class='product-name[^']*'>(.*?)</div>", block, flags=re.S)
        year_match = re.findall(r"group-hover:-translate-y-full'>(.*?)</div>", block, flags=re.S)
        name = html.unescape(re.sub('<.*?>', '', name_match.group(1))).strip() if name_match else ''
        year = html.unescape(re.sub('<.*?>', '', year_match[0])).strip() if year_match else ''
        yield identifier, name, year

def include(product, identifier):
    if product == 'Mac':
        return True
    match = re.match(rf'{product}(\d+),', identifier)
    if not match:
        return False
    number = int(match.group(1))
    return number >= (11 if product == 'iPhone' else 7)

for product, folder in [('Mac', 'macs'), ('iPhone', 'iphones'), ('iPad', 'ipads')]:
    local = {path.stem for path in (root / folder).glob('*.png')}
    missing = [item for item in items(product) if include(product, item[0]) and item[0] not in local]
    print(f'\n{product}: {len(missing)} missing')
    for identifier, name, year in missing:
        print(f'{identifier}\t{name}\t{year}')
PY
```

## Download and crop missing images

Run this from the repo root to download only missing PNGs and crop transparent padding.
Set `FORCE=1` to overwrite and re-crop existing files.

```bash
set -euo pipefail
FORCE=${FORCE:-0}
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p \
  web/dashboard-v2/public/devices/macs \
  web/dashboard-v2/public/devices/iphones \
  web/dashboard-v2/public/devices/ipads

for product in Mac iPhone iPad; do
  curl -fL -A 'Mozilla/5.0' -sS "https://ipsw.dev/product/$product" -o "$work_dir/$product.html"
done

python3 - "$work_dir" > "$work_dir/devices.tsv" <<'PY'
from pathlib import Path
import html
import re
import sys

work = Path(sys.argv[1])

def items(product):
    text = (work / f'{product}.html').read_text(errors='replace')
    for match in re.finditer(r"<a class='product group' href='/product/version/([^']+)'>.*?</a>", text, flags=re.S):
        identifier = html.unescape(match.group(1))
        block = match.group(0)
        name_match = re.search(r"<div class='product-name[^']*'>(.*?)</div>", block, flags=re.S)
        year_match = re.findall(r"group-hover:-translate-y-full'>(.*?)</div>", block, flags=re.S)
        name = html.unescape(re.sub('<.*?>', '', name_match.group(1))).strip() if name_match else ''
        year = html.unescape(re.sub('<.*?>', '', year_match[0])).strip() if year_match else ''
        yield identifier, name, year

def include(product, identifier):
    if product == 'Mac':
        return True
    match = re.match(rf'{product}(\d+),', identifier)
    if not match:
        return False
    number = int(match.group(1))
    return number >= (11 if product == 'iPhone' else 7)

for product, folder in [('Mac', 'macs'), ('iPhone', 'iphones'), ('iPad', 'ipads')]:
    for identifier, name, year in items(product):
        if include(product, identifier):
            print('\t'.join([product, folder, identifier, name, year]))
PY

while IFS=$'\t' read -r product folder identifier name year; do
  dest="web/dashboard-v2/public/devices/$folder/$identifier.png"
  if [[ "$FORCE" != "1" && -f "$dest" ]]; then
    continue
  fi

  src="$work_dir/$identifier.png"
  curl -fL -A 'Mozilla/5.0' -sS "https://ipsw.dev/img/devices/$identifier.png" -o "$src"
  before=$(magick identify -format '%wx%h' "$src")
  bbox=$(magick "$src" -alpha extract -format '%@' info:)
  magick "$src" -crop "$bbox" +repage "$dest"
  after=$(magick identify -format '%wx%h' "$dest")
  echo "$identifier $before -> $after ($bbox)"
done < "$work_dir/devices.tsv"
```

## Verify after downloading

1. Re-run the audit command and confirm missing counts are expected.
2. Spot-check local URLs if the dev server is running, e.g.:

```bash
curl -s -o /dev/null -w '%{http_code} %{content_type} %{size_download}\n' \
  'http://localhost:3001/devices/iphones/iPhone14,7.png'
```

3. If wiring images into UI or mock data, run:

```bash
pnpm --filter dashboard-v2 exec tsc --noEmit
```

## UI/API wiring notes

The API stores canonical iOS model identifiers on `child.ios_devices.model_identifier`
(`IOSDevice.modelIdentifier`). `blocker_app.installs` and `podcast_app.installs` do not
store the identifier directly; they point to the `IOSDevice` row by `device_id`.

The iOS apps send the identifier from `DeviceClient.getModelIdentifier()` (`uname`) via
`ConnectDevice_v2` / `ConnectedRules_v2`; the API creates or updates `IOSDevice` with
that value. Legacy rows may contain `iPhone,unknown` / `iPad,unknown`, so UI should avoid
showing a broken image if the identifier is unknown or absent.

Before wiring real dashboard data, confirm the relevant dashboard PairQL output exposes
`modelIdentifier`. As of this writing, `GetChild`, `GetAllDevices`, and
`GetIOSDevice_v2` expose `modelName` / `deviceType` for iOS devices but not
`modelIdentifier`, so using exact iPhone/iPad images with real API data requires adding
that field to the PairQL outputs and regenerating TypeScript clients.

The shared helper should map device type to the matching public folder, e.g.:

```ts
const deviceImageBaseUrls = {
  mac: `/devices/macs`,
  iphone: `/devices/iphones`,
  ipad: `/devices/ipads`,
};

export const deviceImageUrl = (
  deviceType: keyof typeof deviceImageBaseUrls,
  modelIdentifier: string,
): string => `${deviceImageBaseUrls[deviceType]}/${modelIdentifier}.png`;
```

Mock iPhone/iPad devices need `modelIdentifier` values that match ipsw.dev filenames.
