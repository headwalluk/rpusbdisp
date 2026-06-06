# Getting Started

This guide covers installing the driver, confirming your hardware is detected,
and writing your first output to the display.

## Prerequisites

- Linux kernel 6.1 or later
- Kernel headers for your running kernel (`linux-headers-$(uname -r)`)
- Standard build tools (`build-essential` on Debian/Ubuntu)
- DKMS (`dkms` package, recommended) — automatically rebuilds the module on kernel upgrades

## Install with DKMS (recommended)

```bash
git clone https://github.com/headwalluk/rpusbdisp.git
cd rpusbdisp
sudo ./install.sh
```

The script detects DKMS, builds and installs the module, installs udev rules,
and loads the module automatically. DKMS rebuilds the module automatically
whenever a new kernel is installed, so you never need to reinstall manually
after a kernel upgrade.

See [DKMS Installation](dkms-install.md) for the manual DKMS steps and upgrade
instructions.

## Manual build and install

```bash
git clone https://github.com/headwalluk/rpusbdisp.git
cd rpusbdisp/drivers/linux-driver
make modules
sudo cp rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
sudo modprobe rp_usbdisplay
```

For platform-specific build notes, see:

- [Building on Debian/AMD64](building-debian-amd64.md)
- [Building on Raspberry Pi](building-raspberry-pi.md)
- [Cross-compiling for Raspberry Pi](cross-compiling-for-rpi.md)

## Hardware

This driver supports USB displays with vendor ID `FCCF` and product ID `A001`.
These are commonly sold as the "RoboPeak Mini USB Display" or under various
generic USB display product names.

Check whether your device is connected:

```bash
lsusb | grep -i fccf
```

The driver creates a framebuffer device (`/dev/fbN`) and a touchscreen input
device when the display is plugged in.

## Verify

```bash
cat /proc/fb            # look for rpusbdisp-fb
ls /dev/fb*             # framebuffer device should appear
cat /dev/urandom > /dev/fbN   # test output (replace N with device number)
```

## Load-time options

The module accepts parameters such as `fps` and `console` (the latter for
headless operation). See [Module Parameters](module-parameters.md) for the full
reference.

## Limitations

The driver uses `fb_deferred_io` and does not implement `fb_mmap`. Tools that
require mmap on the framebuffer (e.g. mplayer, fbi) will not work. This device
is best suited for **text and static image output**.

## Sample programs

The [samples/](../samples/) directory contains example programs demonstrating
how to write to the framebuffer device from Bash, Python, Node.js, and C.
