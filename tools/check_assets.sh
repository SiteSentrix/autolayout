#!/usr/bin/env bash
# Fails if a tracked non-code asset (image, font, audio, archive, binary, board)
# has no row in ASSETS.md. The repo ships none today; keep it that way unless a row exists.
cd "$(dirname "$0")/.." || exit 1
bad=0
while IFS= read -r f; do
  grep -qF "\`$f\`" ASSETS.md || { echo "ASSET MISSING from ASSETS.md: $f"; bad=1; }
done < <(git ls-files | grep -iE '\.(png|jpe?g|gif|svg|ico|bmp|webp|ttf|otf|woff2?|pdf|zip|gz|7z|wav|mp3|mp4|bin|exe|dll|pyc|kicad_pcb|kicad_pro|dsn|ses)$')
[ "$bad" = 0 ] || { echo "FAIL: add the asset to ASSETS.md (source + licence) or remove it"; exit 1; }
echo "assets: ok"
