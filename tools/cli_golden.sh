#!/usr/bin/env bash
# Behaviour fingerprint of the CLI on corpus boards: runs the commands that need
# no netlist and prints a sha256 of every stdout and written file. Run before and
# after a refactor; the two outputs must be identical. Needs AUTOLAYOUT_CORPUS.
#   tools/cli_golden.sh OUT_DIR > before.txt     (OUT_DIR must not exist)
set -uo pipefail
cd "$(dirname "$0")/.."
[[ -n "${AUTOLAYOUT_CORPUS:-}" ]] || { echo "SKIPPED: AUTOLAYOUT_CORPUS not set" >&2; exit 0; }
BIN="${AUTOLAYOUT:-./target/release/autolayout}"
W="${1:?usage: cli_golden.sh OUT_DIR}"
mkdir "$W" || exit 1
fp() { # label, then command; stdout hashed with timing text removed
  local label="$1"; shift
  "$@" 2>&1 | sed "s|$W|OUT|g" | sed -E 's/[0-9]+(\.[0-9]+)? ?s\b/Ns/g' | sha256sum | sed "s|-|$label stdout|"
}
fh() { sha256sum "$1" | sed "s|$W/||"; }
FP="$AUTOLAYOUT_CORPUS/quilter/freeplace/m1/m1.kicad_pcb"
RT="$AUTOLAYOUT_CORPUS/quilter/returned/m1/candidate4/m1.kicad_pcb"
cp "$AUTOLAYOUT_CORPUS/quilter/returned/m1/candidate4/m1.kicad_pro" "$W/c4.kicad_pro"
fp roundtrip "$BIN" roundtrip "$FP"
fp info "$BIN" info "$FP"
fp pads "$BIN" pads "$FP"
fp grade "$BIN" grade "$FP"
fp move "$BIN" move "$FP" "$W/moved.kicad_pcb" R8 50 40 135 U1 54 35 45; fh "$W/moved.kicad_pcb"
fp flip "$BIN" flip "$FP" "$W/flipped.kicad_pcb" ALL; fh "$W/flipped.kicad_pcb"
fp flipcaps "$BIN" flip "$FP" "$W/flipcaps.kicad_pcb" --small-caps --count 5; fh "$W/flipcaps.kicad_pcb"
fp unlock "$BIN" unlock "$FP" "$W/unlocked.kicad_pcb" U1; fh "$W/unlocked.kicad_pcb"
fp escape "$BIN" escape "$FP"
fp strip "$BIN" strip "$RT" "$W/c4.kicad_pcb"; fh "$W/c4.kicad_pcb"
fp planes "$BIN" planes "$W/c4.kicad_pcb"
fp rules "$BIN" rules "$W/c4.kicad_pcb"
fp model "$BIN" model "$W/c4.kicad_pcb"
fp route "$BIN" route "$W/c4.kicad_pcb" --plane In1.Cu=GND --plane In2.Cu=+3V3 --out "$W/c4_routed.kicad_pcb"; fh "$W/c4_routed.kicad_pcb"
fp verify "$BIN" verify "$W/c4_routed.kicad_pcb" --plane In1.Cu=GND --plane In2.Cu=+3V3
fp usage "$BIN" bogus
