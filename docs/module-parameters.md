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

There is intentionally **no module parameter** to keep `fbcon` off the display.
The kernel already provides standard, robust ways to do this (and a driver-side
attempt at it caused a boot-time oops — see [Running Headless](headless.md) for
the full story).

In short: load the module with `fbcon=map:1` on the kernel command line, or
unbind the framebuffer console at runtime via `/sys/class/vtconsole`. The
[Running Headless](headless.md) guide covers both.
