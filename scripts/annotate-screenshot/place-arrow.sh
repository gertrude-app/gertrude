#!/usr/bin/env bash
#
# Composite the branded purple arrow onto a screenshot, aimed by ARROW TIP.
#
#   place-arrow.sh <src> <out> <width> <angle> <l|r> <tipX> <tipY>
#
#   width   arrow length in px, before rotation
#   angle   degrees; NEGATIVE = counter-clockwise
#   l|r     direction the arrow points
#   tipX/Y  where the arrow's POINT should land in the source image
#
# Run repeatedly to stack multiple arrows (feed each output back in as <src>).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SRC="$1"; OUT="$2"; W="$3"; ANGLE="$4"; DIR_="$5"; TIPX="$6"; TIPY="$7"
PAD=16
FLOP=""; [ "$DIR_" = "l" ] && FLOP="-flop"

magick -background none -density 600 "$DIR/arrow.svg" $FLOP -resize "${W}x" \
  -background none -rotate "$ANGLE" -trim +repage \
  -bordercolor none -border $PAD "$TMP/core.png"

# locate the tip: extreme opaque pixel in the pointing direction
read -r TX TY < <(magick "$TMP/core.png" -alpha extract -threshold 50% txt:- \
  | awk -F'[,:]' -v dir="$DIR_" '
      /white/ { if (n++ == 0 || (dir=="r" ? $1>bx : $1<bx)) { bx=$1; by=$2 } }
      END { print bx, by }')

magick "$TMP/core.png" \( +clone -background black -shadow 40x3+2+3 \) \
  +swap -background none -layers merge +repage "$TMP/arrow.png"

magick "$SRC" "$TMP/arrow.png" -geometry "+$((TIPX - TX))+$((TIPY - TY))" -composite "$OUT"
