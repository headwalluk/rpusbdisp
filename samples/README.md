# rpusbdisp Framebuffer Samples

Sample programs that render "Hello World" on the rpusbdisp USB display
via the Linux framebuffer interface (`/dev/fbN`).

## Samples

| Language | File              | Dependencies                         |
|----------|-------------------|--------------------------------------|
| Bash     | `bash/hello.sh`   | ImageMagick (`convert`), optionally python3 for 16-bit fb |
| Bash     | `bash/show_image.sh` | ImageMagick (`convert`), optionally python3 for 16-bit fb |
| Python   | `python/hello.py` | Python 3, Pillow (`pip install Pillow`) |
| Node.js  | `node/hello.js`   | Node.js (no external packages)       |
| C        | `c/hello.c`       | GCC, Linux headers                   |

All samples auto-detect the display resolution and color depth at runtime.

## Finding your framebuffer device

The rpusbdisp kernel module registers a framebuffer named `rpusbdisp-fb`.
To find the device number:

```bash
cat /proc/fb
# Example output:
#   0 EFI VGA
#   1 rpusbdisp-fb

# The rpusbdisp display is /dev/fb1 in this example.
```

You can also check sysfs:

```bash
ls /sys/class/graphics/fb*/name
cat /sys/class/graphics/fb1/name    # should print "rpusbdisp-fb"
```

All samples will auto-detect the rpusbdisp framebuffer from `/proc/fb`.
If auto-detection fails, they fall back to `/dev/fb0` or accept the device
path as a command-line argument.

## Running the samples

### Bash

```bash
# Auto-detect rpusbdisp framebuffer:
sudo bash samples/bash/hello.sh

# Custom text:
sudo bash samples/bash/hello.sh "My message"

# Display an image:
sudo bash samples/bash/show_image.sh photo.jpg

# Or specify a device:
sudo FB_DEV=/dev/fb1 bash samples/bash/hello.sh
```

### Python

```bash
pip install Pillow    # or: pip install -r samples/python/requirements.txt

# Auto-detect:
sudo python3 samples/python/hello.py

# Or specify a device:
sudo python3 samples/python/hello.py /dev/fb1
```

### Node.js

```bash
# Auto-detect:
sudo node samples/node/hello.js

# Or specify a device:
sudo node samples/node/hello.js /dev/fb1
```

### C

```bash
cd samples/c
make
sudo ./hello            # auto-detect
sudo ./hello /dev/fb1   # explicit device
```

## Permissions

Writing to `/dev/fbN` typically requires root privileges.  You can either:

- Run with `sudo`, or
- Add a udev rule to grant your user access:

```
# /etc/udev/rules.d/99-rpusbdisp.rules
SUBSYSTEM=="graphics", KERNEL=="fb*", ATTRS{name}=="rpusbdisp-fb", MODE="0666"
```

Then reload udev rules:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```
