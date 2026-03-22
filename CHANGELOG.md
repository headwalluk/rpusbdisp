# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] - 2026-03-22

### Added
- AMD64 / x86_64 platform support (tested on Debian with kernel 6.12.74+deb13+1-amd64 and 6.18.12+deb14-amd64)
- DKMS configuration for automatic module rebuild on kernel upgrades
- Installation and uninstallation scripts (`install.sh`, `uninstall.sh`)
- Udev rules for automatic module loading and framebuffer permissions
- Comprehensive documentation for Debian/AMD64, Raspberry Pi, and cross-compilation
- Sample programs (Bash, Python, Node.js, C) for framebuffer output
- GitHub Actions CI for build verification
- Contributing guidelines and issue templates

### Fixed
- `fb_deferred_io` pagelist API updated for kernel 6.1+: `struct page` + `pagelist`/`lru` replaced with `struct fb_deferred_io_pageref` + `pagereflist`/`list`, and `cur->index << PAGE_SHIFT` replaced with `cur->offset`
- Removed `FBINFO_DEFAULT` constant (removed from kernel, was always 0)
- `framebuffer_alloc()` device pointer now handles NULL for module-init-time registration before USB device probe
- `FBINFO_FLAG_DEFAULT` replaced with `FBINFO_VIRTFB`
- Format string warning in `usbhandlers.c`: `%d` changed to `%zu` for `size_t` argument

### Changed
- Modernised README with quick-start guide and documentation links
