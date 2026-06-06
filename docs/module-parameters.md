# Module Parameters

The driver accepts the following parameters at load time (`modprobe
rp_usbdisplay <name>=<value>`).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fps`     | int  | kernel config, else `16` | Refresh rate (frames per second) used to flush dirty regions to the display. |

You can inspect the parameters of the built module with:

```bash
modinfo -p rp_usbdisplay.ko
```

## `fps`

Controls how often the deferred-IO worker flushes pending changes to the
display. Higher values give smoother updates at the cost of more USB traffic.

If left unset (`0`), the driver falls back to the value compiled in via
`CONFIG_RPUSBDISP_FPS`, or `16` if that config option is unavailable.

```bash
sudo modprobe rp_usbdisplay fps=30
```

To apply it on every boot, add a modprobe config file:

```bash
echo 'options rp_usbdisplay fps=30' | sudo tee /etc/modprobe.d/rp_usbdisplay.conf
```

## Headless operation (running without a framebuffer console)

When the RoboPeak display is the only framebuffer on a machine — for example a
Raspberry Pi with nothing connected to HDMI — the kernel framebuffer console
(`fbcon`) binds to it and draws the text console on it. This is usually the
desired plug-and-play behaviour.

If you want the display to stay "clean" and be driven purely programmatically,
note first that `fbcon` binding does **not** stop you writing to `/dev/fbN`
yourself — the console and direct writes coexist. `fbcon` only matters if you
don't want console text on the display.

To detach `fbcon` from the framebuffer, use the standard kernel mechanisms
rather than a driver option:

**At runtime** — unbind the framebuffer console from the VT layer:

```bash
# Find the fbcon vtconsole node (its 'name' reads "frame buffer device")
grep -l "frame buffer device" /sys/class/vtconsole/vtcon*/name
# Unbind it (replace vtcon1 with the node found above)
echo 0 | sudo tee /sys/class/vtconsole/vtcon1/bind
```

The framebuffer remains at `/dev/fbN` for your application; the console is
simply no longer drawn on it. Re-bind with `echo 1` to the same file.

**At boot** — disable the framebuffer console globally via the kernel command
line (on a Raspberry Pi, append to `/boot/firmware/cmdline.txt`):

```
fbcon=map:2
```

> **Earlier versions:** v1.0.0 shipped a `console=0` module parameter that tried
> to achieve this by refusing in-kernel framebuffer opens. It caused a kernel
> oops at boot when the display was the only framebuffer (refusing the open
> makes `register_framebuffer()` fail while the device is being made the primary
> console), and was removed in v1.0.1. Use the mechanisms above instead.
