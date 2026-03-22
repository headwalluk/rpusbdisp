#!/usr/bin/env bash
#
# hello.sh - Render text on the rpusbdisp framebuffer
#
# Usage: hello.sh [TEXT]
#
# Requires: ImageMagick (convert)
#
set -euo pipefail

MAX_LEN=32
TEXT="${1:-Hello World}"
TEXT="${TEXT:0:$MAX_LEN}"

log() { echo "$*" >&2; }

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
    # FB_DEV set via environment — already assigned
    log "Using FB_DEV from environment: $FB_DEV"
else
    FB_DEV="${FB_DEV:-/dev/fb0}"
    log "WARNING: rpusbdisp-fb not found in /proc/fb; defaulting to $FB_DEV"
fi

if [[ ! -e "$FB_DEV" ]]; then
    log "ERROR: $FB_DEV does not exist."
    exit 1
fi

# Extract fb number (e.g. /dev/fb1 -> fb1)
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
# virtual_size may use comma or 'x' as separator
WIDTH=$(echo "$VSIZE" | tr 'x,' ' ' | awk '{print $1}')
HEIGHT=$(echo "$VSIZE" | tr 'x,' ' ' | awk '{print $2}')
BPP=$(cat "$SYSFS/bits_per_pixel")

log "Resolution: ${WIDTH}x${HEIGHT}, depth: ${BPP} bpp"

# ---------------------------------------------------------------------------
# Determine pixel format for ImageMagick
# ---------------------------------------------------------------------------
case "$BPP" in
    32) DEPTH_FMT="BGRA" ;;
    24) DEPTH_FMT="BGR"  ;;
    16) DEPTH_FMT="BGR565" ;;  # 16-bit 5-6-5
    *)
        log "ERROR: unsupported bits_per_pixel=$BPP"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Pick a font
# ---------------------------------------------------------------------------
FONT=""
for candidate in \
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
    /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf \
    /usr/share/fonts/TTF/DejaVuSans.ttf; do
    if [[ -f "$candidate" ]]; then
        FONT="$candidate"
        break
    fi
done

FONT_ARGS=()
if [[ -n "$FONT" ]]; then
    FONT_ARGS=(-font "$FONT")
    log "Using font: $FONT"
else
    log "No TTF font found; using ImageMagick built-in font."
fi

# ---------------------------------------------------------------------------
# Render and write to framebuffer
# ---------------------------------------------------------------------------

# Choose a reasonable point size (~1/6 of the shorter dimension)
SHORTER=$((WIDTH < HEIGHT ? WIDTH : HEIGHT))
POINTSIZE=$((SHORTER / 6))
[[ "$POINTSIZE" -lt 12 ]] && POINTSIZE=12

log "Rendering \"${TEXT}\" at point size ${POINTSIZE}..."

if [[ "$BPP" -eq 16 ]]; then
    # ImageMagick cannot directly output BGR565; render as 24-bit RGB then
    # convert with a small pipeline.  For simplicity we write 32-bit BGRA
    # and convert to 16-bit 565 with dd/python if available.  However, the
    # rpusbdisp driver typically uses 16-bit RGB565.  We output raw RGB
    # then pack to 565 with a helper.
    convert -size "${WIDTH}x${HEIGHT}" xc:black \
        "${FONT_ARGS[@]}" -fill white -gravity center \
        -pointsize "$POINTSIZE" -annotate +0+0 "$TEXT" \
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
else
    convert -size "${WIDTH}x${HEIGHT}" xc:black \
        "${FONT_ARGS[@]}" -fill white -gravity center \
        -pointsize "$POINTSIZE" -annotate +0+0 "$TEXT" \
        -depth 8 "${DEPTH_FMT}:${FB_DEV}"
fi

log "Done. \"${TEXT}\" written to $FB_DEV."
