# Cross-Compiling on AMD64 for Raspberry Pi

Build the kernel module on an AMD64 host and deploy it to a Raspberry Pi.

## 64-bit Raspberry Pi (aarch64)

### Install the Cross-Compiler

```bash
sudo apt install gcc-aarch64-linux-gnu
```

### Get RPi Kernel Headers

You need the kernel headers (or full kernel source) for the target Pi's running
kernel available on the host machine. Copy them from the Pi or download the
matching version from the Raspberry Pi kernel repository.

### Build

```bash
cd drivers/linux-driver
make CROSS_COMPILE=aarch64-linux-gnu- ARCH=arm64 KERNEL_SOURCE_DIR=/path/to/rpi-kernel-headers
```

## 32-bit Raspberry Pi (armhf)

### Install the Cross-Compiler

```bash
sudo apt install gcc-arm-linux-gnueabihf
```

### Build

```bash
cd drivers/linux-driver
make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm KERNEL_SOURCE_DIR=/path/to/rpi-kernel-headers
```

## Deploy to the Pi

Copy the built module to the Raspberry Pi:

```bash
scp rp_usbdisplay.ko pi@<pi-address>:/tmp/
```

Then SSH into the Pi and install it:

```bash
ssh pi@<pi-address>
sudo cp /tmp/rp_usbdisplay.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
sudo modprobe rp_usbdisplay
```

Verify with `dmesg | tail` and `ls /dev/fb*`.
