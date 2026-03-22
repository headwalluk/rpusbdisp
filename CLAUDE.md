# RoboPeak USB Display - Linux Kernel Driver

## Project Status

v0.2.1 — driver working on AMD64 Debian with DKMS. Install via `sudo ./install.sh`.

### Completed
- Driver compiles cleanly against kernel 6.12.74+deb13+1-amd64 (zero warnings) — also tested on 6.18.12+deb14-amd64
- Four kernel API fixes applied to `drivers/linux-driver/src/fbhandlers.c`:
  1. `fb_deferred_io` pagelist API: `struct page` + `pagelist`/`lru` → `struct fb_deferred_io_pageref` + `pagereflist`/`list`, and `cur->index << PAGE_SHIFT` → `cur->offset`
  2. `FBINFO_DEFAULT` removed (was always 0, just dropped it)
  3. `framebuffer_alloc()` device pointer: `dev ? rpusbdisp_usb_get_devicehandle(dev) : NULL` — must handle NULL because `register_fb_handlers()` calls `_on_create_new_fb(&_default_fb, NULL)` at module init before any USB device is probed
  4. `FBINFO_FLAG_DEFAULT` → `FBINFO_VIRTFB` (already present in code)
- One warning fix in `drivers/linux-driver/src/usbhandlers.c`: `%d` → `%zu` for `size_t`
- DKMS build fixed: Makefile now uses `KBUILD_EXTMOD` guard and `$(src)` for include paths
- DKMS install tested and working on laptop (Debian Trixie, kernel 6.12.74+deb13+1-amd64)
- Display output verified: bash sample rendered "Hello World" on the physical device

### Current State (2026-03-22)
- Primary development on laptop (Debian Trixie AMD64) with USB display connected directly
- Module loads successfully — USB display detected (FW 1.05, S/N 48FC60623436), 10 URB tickets allocated, touchscreen input registered
- Framebuffer device appears at `/dev/fb*`, display output confirmed working

## Build

```bash
cd drivers/linux-driver
make modules          # builds rp_usbdisplay.ko
make clean            # clean build artifacts
```

## Install

DKMS (recommended — rebuilds automatically on kernel upgrades):
```bash
sudo ./install.sh
```

Manual install:
```bash
sudo cp drivers/linux-driver/rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
sudo modprobe rp_usbdisplay
```

## Version Bump Checklist

When changing the version number, update all of these files:
1. `VERSION` — canonical source
2. `dkms.conf` — `PACKAGE_VERSION`
3. `CHANGELOG.md` — add new section
4. `README.md` — version badge
5. `docs/dkms-install.md` — version references in example commands
6. `CLAUDE.md` — project status line

## Important Notes
- User runs all sudo/privileged commands themselves in a separate terminal
- `make modules_install` is not used — install.sh handles installation
