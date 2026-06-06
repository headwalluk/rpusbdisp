# Module Parameters

The driver accepts the following parameters at load time (`modprobe
rp_usbdisplay <name>=<value>`).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fps`     | int  | kernel config, else `16` | Refresh rate (frames per second) used to flush dirty regions to the display. |
| `console` | bool | `1`     | Whether `fbcon` may bind to the display. Set `0` for headless operation. |

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

## `console`

Controls whether the in-kernel framebuffer console (`fbcon`) is allowed to bind
to the display.

By default (`console=1`) the display registers as a normal framebuffer, so on a
machine with no other display the kernel console binds to it — usually the
desired behaviour, and what makes the device usable as a plug-and-play screen.

If you instead want the device to stay headless and be driven purely
programmatically, load the module with `console=0`:

```bash
sudo modprobe rp_usbdisplay console=0
```

The framebuffer still appears at `/dev/fbN` and can be written to as usual, but
`fbcon` will not take it over. Internally this works by refusing in-kernel
framebuffer opens (`user == 0`) while leaving userspace opens (`user == 1`,
e.g. writes to `/dev/fbN`) unaffected. This is the same mechanism the `udlfb`
DisplayLink driver uses.

> **Note:** `console` is read when `fbcon` first opens the framebuffer (at bind
> time), and the parameter is exposed read-only in sysfs. Toggling it after the
> module is loaded will not retroactively unbind an already-attached console —
> set it at `modprobe` time.

### Making it persistent

To apply a parameter on every boot, add a modprobe config file:

```bash
echo 'options rp_usbdisplay console=0' | sudo tee /etc/modprobe.d/rp_usbdisplay.conf
```

Multiple options can be combined on one line:

```bash
echo 'options rp_usbdisplay console=0 fps=30' | sudo tee /etc/modprobe.d/rp_usbdisplay.conf
```
