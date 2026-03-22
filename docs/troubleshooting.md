# Troubleshooting

## "module verification failed" / Tainted Kernel

When loading the module you may see a message like:

```
module verification failed: signature and/or required key missing - tainting kernel
```

This is expected for any out-of-tree kernel module and is harmless. The module
will still function normally.

## No /dev/fbN Appears

1. **Check that the USB display is connected.** The device should show up with
   vendor ID `FCCF` and product ID `A001`:

   ```bash
   lsusb | grep -i fccf
   ```

   If nothing appears, try a different USB port or cable.

2. **Check that the module is loaded:**

   ```bash
   lsmod | grep rp_usbdisplay
   ```

   If it is not listed, load it with `sudo modprobe rp_usbdisplay`.

3. **Check dmesg for errors:**

   ```bash
   dmesg | tail -30
   ```

   Look for any error messages related to `rp_usbdisplay` or USB subsystem
   errors.

## Permission Denied on /dev/fbN

The framebuffer device is typically owned by `root:video`. Check with:

```bash
ls -l /dev/fb*
```

The recommended fix is to add your user to the `video` group:

```bash
sudo usermod -aG video $USER
```

You will need to log out and back in (or reboot) for the group change to take
effect. Verify with:

```bash
groups    # should include "video"
```

Other options:

- Run your application with `sudo`.
- Use `install.sh`, which sets up udev rules that set mode `0666` on the
  rpusbdisp framebuffer device.

## Display Shows White Noise or "Waiting for Signal"

The driver is not communicating with the display properly.

1. Check `dmesg` for URB (USB Request Block) errors.
2. Try unloading and reloading the module:

   ```bash
   sudo rmmod rp_usbdisplay
   sudo modprobe rp_usbdisplay
   ```

3. Disconnect and reconnect the USB display, then reload the module.

## Build Fails

- **Kernel headers must match your running kernel.** Verify with:

  ```bash
  ls /lib/modules/$(uname -r)/build
  ```

  If this directory does not exist, install the headers:

  ```bash
  sudo apt install linux-headers-$(uname -r)
  ```

- **Required kernel config options.** The kernel must have framebuffer support
  enabled. Check that the following config options are set (as built-in or
  module):

  ```
  CONFIG_FB=y
  CONFIG_FB_DEFERRED_IO=y
  CONFIG_FB_SYS_FILLRECT=m
  CONFIG_FB_SYS_COPYAREA=m
  CONFIG_FB_SYS_IMAGEBLIT=m
  CONFIG_FB_SYS_FOPS=m
  ```

  You can check your running kernel's config with:

  ```bash
  grep CONFIG_FB /boot/config-$(uname -r)
  ```

## modprobe Fails with "not found"

If `modprobe rp_usbdisplay` reports that the module was not found, you likely
skipped the `depmod` step after copying the `.ko` file:

```bash
sudo depmod -a
sudo modprobe rp_usbdisplay
```

`depmod` rebuilds the module dependency index. Without it, `modprobe` does not
know about newly added modules.
