# Installing with DKMS

DKMS (Dynamic Kernel Module Support) automatically rebuilds out-of-tree kernel
modules whenever you install a new kernel, so you never have to rebuild manually
after a kernel upgrade.

## Prerequisites

```bash
sudo apt install dkms
```

## Manual DKMS Setup

Copy the source tree into the DKMS source directory:

```bash
sudo cp -r . /usr/src/rpusbdisp-0.2.1/
```

Register, build, and install the module:

```bash
sudo dkms add rpusbdisp/0.2.1
sudo dkms build rpusbdisp/0.2.1
sudo dkms install rpusbdisp/0.2.1
```

The module is now installed and will be rebuilt automatically on kernel upgrades.

## Using install.sh

If the repository includes an `install.sh` script, it handles the DKMS setup
automatically:

```bash
sudo ./install.sh
```

## Loading the Module

```bash
sudo modprobe rp_usbdisplay
```

## Upgrading

When upgrading to a new version, the old DKMS registration is not automatically removed. To clean up:

```bash
# Check for existing registrations
sudo dkms status | grep rpusbdisp

# Remove old version(s) before installing the new one
sudo dkms remove rpusbdisp/<old-version> --all
```

Then run `sudo ./install.sh` as normal.

## Uninstalling

```bash
sudo dkms remove rpusbdisp/0.2.1 --all
```

This removes the module for all kernel versions and deletes the DKMS registration.
