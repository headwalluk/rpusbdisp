#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NAME="rpusbdisp"
PACKAGE_VERSION="$(cat "${SCRIPT_DIR}/VERSION" | tr -d '[:space:]')"
MODULE_NAME="rp_usbdisplay"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

# Unload the module (ignore errors if not loaded)
echo "Unloading module ..."
rmmod "$MODULE_NAME" 2>/dev/null || echo "Module not loaded, continuing."

HAS_DKMS=0
if command -v dkms >/dev/null 2>&1; then
    HAS_DKMS=1
fi

if [ "$HAS_DKMS" -eq 1 ]; then
    echo "Removing module from DKMS ..."
    dkms remove "${PACKAGE_NAME}/${PACKAGE_VERSION}" --all 2>/dev/null || \
        echo "Module not registered in DKMS, continuing."

    DKMS_SRC="/usr/src/${PACKAGE_NAME}-${PACKAGE_VERSION}"
    if [ -d "$DKMS_SRC" ]; then
        echo "Removing DKMS source directory ..."
        rm -rf "$DKMS_SRC"
    fi
else
    KO_PATH="/lib/modules/$(uname -r)/extra/${MODULE_NAME}.ko"
    if [ -f "$KO_PATH" ]; then
        echo "Removing ${KO_PATH} ..."
        rm -f "$KO_PATH"
        echo "Running depmod ..."
        depmod -a
    else
        echo "Module file not found at ${KO_PATH}, skipping."
    fi
fi

# Remove udev rules
UDEV_RULES="/etc/udev/rules.d/99-rpusbdisp.rules"
if [ -f "$UDEV_RULES" ]; then
    echo "Removing udev rules ..."
    rm -f "$UDEV_RULES"

    echo "Reloading udev rules ..."
    udevadm control --reload-rules && udevadm trigger
else
    echo "No udev rules to remove."
fi

echo "Uninstall complete."
