#!/usr/bin/env bash
#
# Draw the branded purple highlight box on a screenshot.
#
#   place-box.sh <src> <out> <x> <y> <w> <h> [stroke] [radius]
#
# Defaults are tuned for 900px-wide (2x retina) screenshots. Leave roughly
# 60px of padding around the content you're highlighting.
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SRC="$1"; OUT="$2"; X="$3"; Y="$4"; W="$5"; H="$6"; SW="${7:-17}"; R="${8:-22}"
COLOR='#DC9BFF'
PAD=20
CW=$((W + PAD*2)); CH=$((H + PAD*2)); HALF=$((SW/2))

magick -size "${CW}x${CH}" xc:none -fill none -stroke "$COLOR" -strokewidth "$SW" \
  -draw "roundrectangle $((PAD+HALF)),$((PAD+HALF)) $((PAD+W-HALF)),$((PAD+H-HALF)) $R,$R" \
  "$TMP/core.png"

magick "$TMP/core.png" \( +clone -background black -shadow 35x3+2+3 \) \
  +swap -background none -layers merge +repage "$TMP/box.png"

magick "$SRC" "$TMP/box.png" -geometry "+$((X-PAD))+$((Y-PAD))" -composite "$OUT"
