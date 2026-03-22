# RoboPeak USB Display - Linux Kernel Driver

## Project Status

Porting this driver (originally for Raspberry Pi / ARM) to work on AMD64 Debian with DKMS.

### Completed
- Driver compiles cleanly against kernel 6.12.74+deb13+1-amd64 (zero warnings) — also tested on 6.18.12+deb14-amd64
- Four kernel API fixes applied to `drivers/linux-driver/src/fbhandlers.c`:
  1. `fb_deferred_io` pagelist API: `struct page` + `pagelist`/`lru` → `struct fb_deferred_io_pageref` + `pagereflist`/`list`, and `cur->index << PAGE_SHIFT` → `cur->offset`
  2. `FBINFO_DEFAULT` removed (was always 0, just dropped it)
  3. `framebuffer_alloc()` device pointer: `dev ? rpusbdisp_usb_get_devicehandle(dev) : NULL` — must handle NULL because `register_fb_handlers()` calls `_on_create_new_fb(&_default_fb, NULL)` at module init before any USB device is probed
  4. `FBINFO_FLAG_DEFAULT` → `FBINFO_VIRTFB` (already present in code)
- One warning fix in `drivers/linux-driver/src/usbhandlers.c`: `%d` → `%zu` for `size_t`
- Module `.ko` built and ready to install

### Current State (2026-03-22)
- Development moved from primary desktop to QEMU VM (Q35/ICH9) with USB passthrough of the display device
- Module loads successfully on kernel 6.12.74+deb13+1-amd64 — USB display detected (FW 1.05, S/N 48FC60623436), 10 URB tickets allocated, touchscreen input registered

### Next Steps
1. Verify framebuffer device appears: `ls /dev/fb*`
2. Test display output: `cat /dev/urandom > /dev/fbN`
3. Set up DKMS configuration (not yet created)

## Build

```bash
cd drivers/linux-driver
make modules          # builds rp_usbdisplay.ko
make clean            # clean build artifacts
```

Manual install (no working `make modules_install` — PWD issue under sudo):
```bash
sudo cp drivers/linux-driver/rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
sudo modprobe rp_usbdisplay
```

## Important Notes
- User runs all sudo/privileged commands themselves in a separate terminal
- The `modules_install` Makefile target breaks under sudo because `$(PWD)` resolves incorrectly — use manual copy + depmod instead
