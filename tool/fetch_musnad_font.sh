#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_DIR="$ROOT/assets/fonts"
FONT="$FONT_DIR/Musnad.ttf"
URL="https://raw.githubusercontent.com/google/fonts/main/ofl/notosansoldsoutharabian/NotoSansOldSouthArabian-Regular.ttf"

mkdir -p "$FONT_DIR"
if [[ -s "$FONT" ]]; then
  exit 0
fi

curl --fail --location --retry 3 --silent --show-error "$URL" -o "$FONT"
test -s "$FONT"
printf 'Installed Musnad font: %s bytes\n' "$(wc -c < "$FONT")"
