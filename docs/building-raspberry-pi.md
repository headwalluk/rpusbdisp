# Building on Raspberry Pi

Covers Raspberry Pi 4 and 5, both of which use aarch64 on current Raspberry Pi OS.

## Prerequisites

Install build tools and kernel headers:

```bash
sudo apt install build-essential raspberrypi-kernel-headers
```

On some installations, the headers package may be named differently:

```bash
sudo apt install build-essential linux-headers-$(uname -r)
```

On older 32-bit Raspberry Pi OS releases, the kernel headers package name may
vary further. Check `apt search linux-headers` if neither of the above works.

## Building the Module

```bash
git clone https://github.com/nicedoc/rpusbdisp.git
cd rpusbdisp/drivers/linux-driver
make modules
```

This produces `rp_usbdisplay.ko` in the current directory.

## Installing the Module

```bash
sudo cp rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

## Loading the Module

```bash
sudo modprobe rp_usbdisplay
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

## Auto-Loading on Boot

To have the module load automatically at boot:

```bash
echo rp_usbdisplay | sudo tee /etc/modules-load.d/rpusbdisp.conf
```
