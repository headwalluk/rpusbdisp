#!/usr/bin/env bash
#
# show_image.sh - Display an image on the rpusbdisp framebuffer
#
# Usage: show_image.sh <image-file>
#
# Scales the image to fit the display, letterboxing with black if the
# aspect ratio doesn't match.
#
# Requires: ImageMagick (convert), python3 (for 16-bit displays only)
#
set -euo pipefail

log() { echo "$*" >&2; }

# ---------------------------------------------------------------------------
# Check dependencies
# ---------------------------------------------------------------------------
if ! command -v convert >/dev/null 2>&1; then
    log "ERROR: ImageMagick is required but not installed."
    log "Install it with:  sudo apt install imagemagick"
    exit 1
fi

# ---------------------------------------------------------------------------
# Validate input
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    log "Usage: show_image.sh <image-file>"
    exit 1
fi

IMAGE="$1"

if [[ ! -f "$IMAGE" ]]; then
    log "ERROR: File not found: $IMAGE"
    exit 1
fi

# ---------------------------------------------------------------------------
# Locate the rpusbdisp framebuffer
# ---------------------------------------------------------------------------
detect_fb() {
    if [[ -r /proc/fb ]]; then
        while IFS=': ' read -r num name rest; do
            if [[ "$name" == "rpusbdisp-fb" ]]; then
                echo "/dev/fb${num}"
                return 0
            fi
        done < /proc/fb
    fi
    return 1
}

FB_DEV=""
if FB_DEV=$(detect_fb); then
    log "Auto-detected rpusbdisp framebuffer: $FB_DEV"
elif [[ -n "${FB_DEV_ENV:=${FB_DEV:-}}" && -n "${FB_DEV:=$FB_DEV_ENV}" ]]; then
    log "Using FB_DEV from environment: $FB_DEV"
else
    FB_DEV="${FB_DEV:-/dev/fb0}"
    log "WARNING: rpusbdisp-fb not found in /proc/fb; defaulting to $FB_DEV"
fi

if [[ ! -e "$FB_DEV" ]]; then
    log "ERROR: $FB_DEV does not exist."
    exit 1
fi

FB_NAME=$(basename "$FB_DEV")

# ---------------------------------------------------------------------------
# Read resolution and depth from sysfs
# ---------------------------------------------------------------------------
SYSFS="/sys/class/graphics/${FB_NAME}"

if [[ ! -d "$SYSFS" ]]; then
    log "ERROR: sysfs path $SYSFS not found."
    exit 1
fi

VSIZE=$(cat "$SYSFS/virtual_size")
WIDTH=$(echo "$VSIZE" | tr 'x,' ' ' | awk '{print $1}')
HEIGHT=$(echo "$VSIZE" | tr 'x,' ' ' | awk '{print $2}')
BPP=$(cat "$SYSFS/bits_per_pixel")

log "Display: ${WIDTH}x${HEIGHT}, ${BPP} bpp"
log "Image: $IMAGE"

# ---------------------------------------------------------------------------
# Validate depth
# ---------------------------------------------------------------------------
case "$BPP" in
    16|24|32) ;;
    *)
        log "ERROR: unsupported bits_per_pixel=$BPP"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Scale image and write to framebuffer
# ---------------------------------------------------------------------------
if [[ "$BPP" -eq 16 ]]; then
    if ! command -v python3 >/dev/null 2>&1; then
        log "ERROR: python3 is required for 16-bit framebuffer output."
        log "Install it with:  sudo apt install python3"
        exit 1
    fi

    convert "$IMAGE" \
        -resize "${WIDTH}x${HEIGHT}" \
        -background black -gravity center -extent "${WIDTH}x${HEIGHT}" \
        -depth 8 rgb:- | \
    python3 -c "
import sys
data = sys.stdin.buffer.read()
out = bytearray()
for i in range(0, len(data), 3):
    r, g, b = data[i], data[i+1], data[i+2]
    val = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
    out.append(val & 0xFF)
    out.append((val >> 8) & 0xFF)
sys.stdout.buffer.write(out)
" > "$FB_DEV"
elif [[ "$BPP" -eq 24 ]]; then
    convert "$IMAGE" \
        -resize "${WIDTH}x${HEIGHT}" \
        -background black -gravity center -extent "${WIDTH}x${HEIGHT}" \
        -depth 8 "BGR:${FB_DEV}"
else
    convert "$IMAGE" \
        -resize "${WIDTH}x${HEIGHT}" \
        -background black -gravity center -extent "${WIDTH}x${HEIGHT}" \
        -depth 8 "BGRA:${FB_DEV}"
fi

log "Done. Image written to $FB_DEV."
