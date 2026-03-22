# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.2.1] - 2026-03-22

### Fixed
- C sample (`samples/c/hello.c`): replaced `mmap()` with `write()` — the rpusbdisp driver uses `fb_deferred_io` and does not support mmap

### Changed
- Bash sample (`samples/bash/hello.sh`): accepts optional text argument (defaults to "Hello World", capped at 32 characters)
- `install.sh`: DKMS source sync now excludes `.git`, `.github`, `docs`, `samples`, and `tools` directories

## [0.2.0] - 2026-03-22

### Fixed
- DKMS build failure caused by driver Makefile using `$(PWD)` for `M=` and include paths, which resolved incorrectly when invoked via the kernel build system
- Include paths in `EXTRA_CFLAGS` now use `$(src)` (set by kbuild to the out-of-tree module directory) instead of `$(PWD)`
- Outer make targets (`modules`, `modules_install`, `clean`) guarded with `ifeq ($(KBUILD_EXTMOD),)` to prevent double-invocation when re-entered by the kernel build system
- `KERNEL_SOURCE_DIR` default now uses `$(shell uname -r)` instead of backtick syntax

### Changed
- `install.sh` now unconditionally syncs source to `/usr/src/` on every run (via `rsync --delete`) so code changes are always picked up by subsequent DKMS builds

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
