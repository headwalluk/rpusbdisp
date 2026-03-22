#!/usr/bin/env python3
"""
hello.py - Render "Hello World" on the rpusbdisp framebuffer using Pillow.

Usage:
    python3 hello.py [/dev/fbN]

If no argument is given, auto-detects the rpusbdisp framebuffer or defaults
to /dev/fb0.
"""

import os
import struct
import sys

from PIL import Image, ImageDraw, ImageFont


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def detect_rpusbdisp_fb() -> str | None:
    """Scan /proc/fb for the rpusbdisp-fb entry and return e.g. '/dev/fb1'."""
    try:
        with open("/proc/fb", "r") as f:
            for line in f:
                parts = line.strip().split(" ", 1)
                if len(parts) == 2:
                    num = parts[0].rstrip(":")
                    name = parts[1].strip()
                    if name == "rpusbdisp-fb":
                        return f"/dev/fb{num}"
    except FileNotFoundError:
        pass
    return None


def read_fb_params(fb_dev: str) -> tuple[int, int, int]:
    """Return (width, height, bits_per_pixel) from sysfs."""
    fb_name = os.path.basename(fb_dev)  # e.g. "fb1"
    sysfs = f"/sys/class/graphics/{fb_name}"

    vsize_path = os.path.join(sysfs, "virtual_size")
    bpp_path = os.path.join(sysfs, "bits_per_pixel")

    with open(vsize_path, "r") as f:
        raw = f.read().strip()
    # Format is "W,H" or "WxH"
    parts = raw.replace("x", ",").split(",")
    width, height = int(parts[0]), int(parts[1])

    with open(bpp_path, "r") as f:
        bpp = int(f.read().strip())

    return width, height, bpp


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Try to load DejaVu Sans; fall back to the default PIL bitmap font."""
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
    ]
    for path in candidates:
        if os.path.isfile(path):
            log(f"Using font: {path}")
            return ImageFont.truetype(path, size)
    log("No TTF font found; using default PIL font.")
    return ImageFont.load_default()


def rgb_to_565(img: Image.Image) -> bytes:
    """Convert an RGB PIL image to 16-bit RGB565 little-endian bytes."""
    pixels = img.tobytes()
    out = bytearray()
    for i in range(0, len(pixels), 3):
        r, g, b = pixels[i], pixels[i + 1], pixels[i + 2]
        val = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
        out += struct.pack("<H", val)
    return bytes(out)


def main() -> None:
    # Determine framebuffer device
    if len(sys.argv) > 1:
        fb_dev = sys.argv[1]
        log(f"Using framebuffer device from argument: {fb_dev}")
    else:
        fb_dev = detect_rpusbdisp_fb()
        if fb_dev:
            log(f"Auto-detected rpusbdisp framebuffer: {fb_dev}")
        else:
            fb_dev = "/dev/fb0"
            log(f"WARNING: rpusbdisp-fb not found in /proc/fb; defaulting to {fb_dev}")

    if not os.path.exists(fb_dev):
        log(f"ERROR: {fb_dev} does not exist.")
        sys.exit(1)

    # Read resolution and depth
    width, height, bpp = read_fb_params(fb_dev)
    log(f"Resolution: {width}x{height}, depth: {bpp} bpp")

    # Create image
    img = Image.new("RGB", (width, height), color=(0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Pick font size relative to display
    shorter = min(width, height)
    font_size = max(12, shorter // 6)
    font = load_font(font_size)

    # Center the text
    text = "Hello World"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (width - tw) // 2
    y = (height - th) // 2
    draw.text((x, y), text, fill=(255, 255, 255), font=font)

    log(f"Rendering \"{text}\" at font size {font_size}...")

    # Convert to the right pixel format and write
    if bpp == 16:
        raw = rgb_to_565(img)
    elif bpp == 24:
        # Framebuffer typically expects BGR
        b, g, r = img.split()
        img_bgr = Image.merge("RGB", (b, g, r))
        raw = img_bgr.tobytes()
    elif bpp == 32:
        # BGRA
        b, g, r = img.split()
        a = Image.new("L", (width, height), 255)
        img_bgra = Image.merge("RGBA", (b, g, r, a))
        raw = img_bgra.tobytes()
    else:
        log(f"ERROR: unsupported bits_per_pixel={bpp}")
        sys.exit(1)

    with open(fb_dev, "wb") as fb:
        fb.write(raw)

    log(f"Done. \"{text}\" written to {fb_dev}.")


if __name__ == "__main__":
    main()
