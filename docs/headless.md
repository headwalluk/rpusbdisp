# Running Headless (no framebuffer console)

When the RoboPeak display is the **only** framebuffer on a machine — for
example a Raspberry Pi with nothing plugged into HDMI — the kernel framebuffer
console (`fbcon`) binds to it at boot and draws the Linux text console on the
display. For a plug-and-play screen that is usually what you want.

If instead you want the display to stay clean and be driven purely by your own
software, you need to stop `fbcon` from using it. This is a job for the kernel's
standard console-control mechanisms, **not** a driver option — see
[why not a module parameter?](#why-not-a-module-parameter) at the end.

Two things worth knowing first:

- `fbcon` binding does **not** block you from writing to `/dev/fbN`. The console
  and your direct writes coexist; `fbcon` just *also* paints console text on the
  display. So "headless" here means "no console text on the screen", not "the
  framebuffer becomes usable" — it already is.
- On a headless box the RoboPeak display is typically the only framebuffer, so
  the methods below disable the framebuffer console **globally**. That is
  normally exactly what you want. If you sometimes attach a real monitor and
  want the console *there* but not on the USB display, see
  [Selective mapping](#selective-mapping).

## Method 1 — Disable fbcon at boot (recommended)

Tell `fbcon` to map the console to a framebuffer index that does not exist, so
it never takes over any real framebuffer. From the kernel documentation:

> One side effect that may be useful is using a map value that exceeds the
> number of loaded fb drivers. For example, if only one driver is available,
> fb0, adding `fbcon=map:1` tells fbcon not to take over the console.

On a Raspberry Pi, add `fbcon=map:1` to the kernel command line. On current
Raspberry Pi OS / Debian this file is `/boot/firmware/cmdline.txt` (older images
use `/boot/cmdline.txt`). It is a **single line** — append the option to the end
of the existing line, do not add a new line:

```
... rootwait fbcon=map:1
```

Then reboot. The RoboPeak display comes up blank (no console text),
`register_framebuffer()` succeeds normally, and `/dev/fb0` is ready for your
application.

> If the machine may also have a real display (so there could be more than one
> framebuffer), use a value safely beyond the count, e.g. `fbcon=map:10`. The
> value just has to exceed the number of framebuffers present.

## Method 2 — Unbind fbcon at runtime (no reboot)

Useful for testing, or if you cannot edit the kernel command line. The
framebuffer console is exposed under `/sys/class/vtconsole/`. Find the node
whose `name` is the framebuffer device, then unbind it:

```bash
# Identify the fbcon vtconsole node
grep -l "frame buffer device" /sys/class/vtconsole/vtcon*/name

# Detach it (replace vtcon1 with the node found above)
echo 0 | sudo tee /sys/class/vtconsole/vtcon1/bind
```

The console text disappears from the display immediately; `/dev/fb0` remains
available throughout. Re-attach at any time:

```bash
echo 1 | sudo tee /sys/class/vtconsole/vtcon1/bind
```

Per the kernel docs, unbinding `fbcon` from the console layer automatically
unbinds the framebuffer drivers from `fbcon`.

## Method 3 — Unbind fbcon automatically with a systemd service

To make the runtime unbind (Method 2) persistent without touching the kernel
command line, install a small one-shot service:

```ini
# /etc/systemd/system/rpusbdisp-headless.service
[Unit]
Description=Detach the framebuffer console (headless RoboPeak display)
After=systemd-udev-settle.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for v in /sys/class/vtconsole/vtcon*; do grep -q "frame buffer device" "$v/name" && echo 0 > "$v/bind"; done'

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now rpusbdisp-headless.service
```

Method 1 is simpler and runs earlier (before the console is ever drawn), so
prefer it unless you specifically need to keep `fbcon` available at boot.

## Selective mapping

`fbcon=map:` also accepts a per-VT digit string, so you can pin the console to a
specific framebuffer rather than disabling it. For example, with a real display
on `fb0` and the RoboPeak display on `fb1`, `fbcon=map:0` keeps the console on
`fb0` and away from the USB display. See the
[kernel fbcon documentation](https://www.kernel.org/doc/html/latest/fb/fbcon.html)
for the full syntax. Note that framebuffer numbering depends on probe order and
is not guaranteed stable across boots.

## Verify

After applying any method, confirm the framebuffer is present and writable:

```bash
cat /proc/fb                          # rpusbdisp-fb should be listed
sudo sh -c 'cat /dev/urandom > /dev/fb0'   # display fills with static
./samples/bash/hello.sh Hello         # or render text
```

## Why not a module parameter?

v1.0.0 briefly shipped a `console=0` module parameter that tried to keep
`fbcon` off by refusing in-kernel framebuffer opens (the approach the `udlfb`
DisplayLink driver uses). It was removed in v1.0.1 because it cannot work for
this driver: `udlfb` is never the boot primary console, but the RoboPeak driver
registers its framebuffer at module-init, and on a headless machine that is the
*only* framebuffer — so `fbcon` makes it the primary console. Refusing the open
then makes `register_framebuffer()` fail while the device is already partially
registered, causing a kernel oops. The kernel-level methods above achieve the
same goal safely. See [Module Parameters](module-parameters.md) for more.
