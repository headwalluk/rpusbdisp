# RoboPeak Mini USB Display - Linux Driver

[![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)](CHANGELOG.md)
[![Build](https://github.com/headwalluk/rpusbdisp/actions/workflows/build.yml/badge.svg)](https://github.com/headwalluk/rpusbdisp/actions/workflows/build.yml)
[![Last Commit](https://img.shields.io/github/last-commit/headwalluk/rpusbdisp.svg)](https://github.com/headwalluk/rpusbdisp/commits/master)
[![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![Kernel 6.1+](https://img.shields.io/badge/kernel-6.1%2B-brightgreen.svg)]()

Linux kernel framebuffer driver for the RoboPeak Mini USB Display.

## What is this?

This is a fork of [robopeak/rpusbdisp](https://github.com/robopeak/rpusbdisp),
the original Linux kernel driver for the RoboPeak Mini USB Display. The original
repository is unmaintained and does not compile against modern kernels.

This fork modernises the driver to build and run on current kernels (6.1+), adds
AMD64/x86_64 platform support alongside the original ARM/Raspberry Pi target, and
provides DKMS packaging for automatic module rebuilds on kernel upgrades.

It's aimed at anyone with a RoboPeak Mini USB Display (or a compatible generic
USB display with USB ID `FCCF:A001`) who wants to use it on a modern Linux
system — either as a plug-and-play console screen or as a programmatically
controlled display in a headless setup.

> **Note:** the driver uses `fb_deferred_io` and does not implement `fb_mmap`,
> so it is best suited for text and static image output. See
> [Getting Started](docs/getting-started.md#limitations) for details.

## Get started

```bash
git clone https://github.com/headwalluk/rpusbdisp.git
cd rpusbdisp
sudo ./install.sh
```

Full instructions are in [docs/getting-started.md](docs/getting-started.md).

## Documentation

- [Getting Started](docs/getting-started.md) — install, verify, and first output
- [Module Parameters](docs/module-parameters.md) — `fps`
- [Running Headless](docs/headless.md) — use the display without a framebuffer console
- [Building on Debian/AMD64](docs/building-debian-amd64.md)
- [Building on Raspberry Pi](docs/building-raspberry-pi.md)
- [Cross-compiling for Raspberry Pi](docs/cross-compiling-for-rpi.md)
- [DKMS Installation](docs/dkms-install.md)
- [Troubleshooting](docs/troubleshooting.md)

Sample programs for Bash, Python, Node.js, and C are in [samples/](samples/).

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the GNU General Public License v2.0. See the
[LICENSE](LICENSE) file or the
[full license text](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html).

## Credits

This project is based on the original
[RoboPeak USB Display driver](https://github.com/robopeak/rpusbdisp) by the
RoboPeak Team. The original driver was created by Shikai Chen.
