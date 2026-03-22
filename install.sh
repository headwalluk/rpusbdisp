#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NAME="rpusbdisp"
PACKAGE_VERSION="$(cat "${SCRIPT_DIR}/VERSION" | tr -d '[:space:]')"
MODULE_NAME="rp_usbdisplay"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

HAS_DKMS=0
if command -v dkms >/dev/null 2>&1; then
    HAS_DKMS=1
    echo "DKMS detected. Using DKMS installation method."
else
    echo "DKMS not found. Using manual installation method."
fi

if [ "$HAS_DKMS" -eq 1 ]; then
    DKMS_SRC="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"

    echo "Syncing source to ${DKMS_SRC} ..."
    mkdir -p "$DKMS_SRC"
    rsync -a --delete "$SCRIPT_DIR/" "$DKMS_SRC/"

    echo "Adding module to DKMS ..."
    dkms add -m "$PACKAGE_NAME" -v "$PACKAGE_VERSION" 2>/dev/null || \
        echo "Module already added to DKMS, continuing."

    echo "Building module with DKMS ..."
    dkms build -m "$PACKAGE_NAME" -v "$PACKAGE_VERSION"

    echo "Installing module with DKMS ..."
    dkms install -m "$PACKAGE_NAME" -v "$PACKAGE_VERSION"
else
    echo "Building module ..."
    make -C "${SCRIPT_DIR}/drivers/linux-driver" modules

    DEST="/lib/modules/$(uname -r)/extra"
    mkdir -p "$DEST"

    echo "Installing ${MODULE_NAME}.ko to ${DEST} ..."
    cp "${SCRIPT_DIR}/drivers/linux-driver/${MODULE_NAME}.ko" "$DEST/"

    echo "Running depmod ..."
    depmod -a
fi

# Install udev rules
UDEV_SRC="${SCRIPT_DIR}/etc/udev/rules.d/99-rpusbdisp.rules"
UDEV_DEST="/etc/udev/rules.d/99-rpusbdisp.rules"

if [ -f "$UDEV_SRC" ]; then
    echo "Installing udev rules ..."
    cp "$UDEV_SRC" "$UDEV_DEST"

    echo "Reloading udev rules ..."
    udevadm control --reload-rules && udevadm trigger
else
    echo "Warning: udev rules file not found at ${UDEV_SRC}, skipping." >&2
fi

# Load the module
echo "Loading module ..."
modprobe "$MODULE_NAME"

# Check for framebuffer device
echo "Checking for framebuffer device ..."
sleep 1
if ls /dev/fb* >/dev/null 2>&1; then
    echo "Framebuffer device(s) found:"
    ls -la /dev/fb*
else
    echo "No framebuffer device found. Make sure the USB display is plugged in (vendor FCCF, product A001)."
    echo "Check dmesg for details: dmesg | tail -20"
fi

echo "Installation complete."
