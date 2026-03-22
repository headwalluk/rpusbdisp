# RoboPeak Mini USB Display - Linux Driver

[![Build](https://github.com/headwalluk/rpusbdisp/actions/workflows/build.yml/badge.svg)](https://github.com/headwalluk/rpusbdisp/actions/workflows/build.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![Kernel 6.1+](https://img.shields.io/badge/kernel-6.1%2B-brightgreen.svg)]()

Linux kernel framebuffer driver for the RoboPeak Mini USB Display.

## What is this?

This is a fork of [robopeak/rpusbdisp](https://github.com/robopeak/rpusbdisp), the original Linux kernel driver for the RoboPeak Mini USB Display. The original repository is unmaintained and does not compile against modern kernels.

This fork modernises the kernel driver to build and run on current kernels (6.1+), adds AMD64/x86_64 platform support alongside the original ARM/Raspberry Pi target, and provides DKMS packaging for automatic module rebuilds on kernel upgrades.

## Quick Start

### Prerequisites

- Linux kernel 6.1 or later
- Kernel headers for your running kernel (`linux-headers-$(uname -r)`)
- Standard build tools (`build-essential` on Debian/Ubuntu)

### Build and Install

```bash
git clone https://github.com/headwalluk/rpusbdisp.git
cd rpusbdisp/drivers/linux-driver
make modules
sudo cp rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

### Load and Verify

```bash
sudo modprobe rp_usbdisplay
cat /proc/fb            # look for rpusbdisp-fb
ls /dev/fb*             # framebuffer device should appear
cat /dev/urandom > /dev/fbN   # test output (replace N)
```

For detailed build instructions, see the [documentation](#documentation).

## Hardware

This driver supports USB displays with vendor ID `FCCF` and product ID `A001`. These are commonly sold as the "RoboPeak Mini USB Display" or under various generic USB display product names.

Check whether your device is connected:

```bash
lsusb | grep -i fccf
```

The driver creates a framebuffer device (`/dev/fbN`) and a touchscreen input device when the display is plugged in.

## Documentation

Detailed guides are available in the [docs/](docs/) directory:

- [Building on Debian/AMD64](docs/building-debian-amd64.md)
- [Building on Raspberry Pi](docs/building-raspberry-pi.md)
- [Cross-compiling for Raspberry Pi](docs/cross-compiling-for-rpi.md)
- [DKMS Installation](docs/dkms-install.md)
- [Troubleshooting](docs/troubleshooting.md)

## Sample Programs

The [samples/](samples/) directory contains example programs demonstrating how to write to the framebuffer device from Bash, Python, Node.js, and C.

## DKMS

DKMS support is provided via `dkms.conf` and the `install.sh` / `uninstall.sh` scripts. DKMS automatically rebuilds the kernel module whenever a new kernel is installed.

See [docs/dkms-install.md](docs/dkms-install.md) for setup instructions.

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the GNU General Public License v2.0. See the [LICENSE](LICENSE) file or the [full license text](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html).

## Credits

This project is based on the original [RoboPeak USB Display driver](https://github.com/robopeak/rpusbdisp) by the RoboPeak Team. The original driver was created by Shikai Chen.
