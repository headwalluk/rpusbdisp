# Building on Debian / AMD64

## Prerequisites

Install the required build tools and kernel headers:

```bash
sudo apt install build-essential linux-headers-$(uname -r)
```

## Building the Module

```bash
git clone https://github.com/nicedoc/rpusbdisp.git
cd rpusbdisp/drivers/linux-driver
make modules
```

This produces `rp_usbdisplay.ko` in the current directory.

## Installing the Module

The `modules_install` Makefile target has a known issue where `$(PWD)` resolves
incorrectly under sudo. Use the manual install method instead:

```bash
sudo cp rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

## Loading the Module

```bash
sudo modprobe rp_usbdisplay
```

You can optionally set the framebuffer refresh rate (default is 30):

```bash
sudo modprobe rp_usbdisplay fps=25
```

## Verifying It Works

Check kernel messages for the driver announcement:

```bash
dmesg | tail
```

Look for a line containing `RP USB Display found`.

Confirm a new framebuffer device appeared:

```bash
ls /dev/fb*
```

Send test data to the display (replace `fbN` with the actual device number):

```bash
cat /dev/urandom > /dev/fbN
```

You should see colored noise on the USB display.

## Tested Kernels

- 6.12.74+deb13+1-amd64
- 6.18.12+deb14-amd64
