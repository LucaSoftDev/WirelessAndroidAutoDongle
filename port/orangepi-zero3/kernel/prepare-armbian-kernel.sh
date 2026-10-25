#!/bin/sh
# Stage the upstream project's AOA kernel patches into an Armbian build tree.
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/armbian-build" >&2
    exit 2
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
ARMBIAN_DIR=$(CDPATH= cd -- "$1" && pwd)
STOCK_CONFIG=$ARMBIAN_DIR/config/kernel/linux-sunxi64-current.config
PATCH_DIR=$ARMBIAN_DIR/userpatches/kernel/archive/sunxi-6.18
USER_CONFIG=$ARMBIAN_DIR/userpatches/config/kernel/linux-sunxi64-current.config

[ -f "$ARMBIAN_DIR/compile.sh" ] || { echo 'Not an Armbian build checkout.' >&2; exit 1; }
[ -f "$STOCK_CONFIG" ] || { echo "Missing stock kernel config: $STOCK_CONFIG" >&2; exit 1; }

mkdir -p "$PATCH_DIR" "$(dirname -- "$USER_CONFIG")"
cp "$REPO_DIR/aa_wireless_dongle/patches/linux/0001-Backport-and-apply-patches-for-Android-Accessory-mod.patch" "$PATCH_DIR/"
cp "$REPO_DIR/aa_wireless_dongle/patches/linux/0002-Remove-cyclic-dependency-between-f_accessory-and-lib.patch" "$PATCH_DIR/"
cp "$REPO_DIR/aa_wireless_dongle/patches/linux/0003-Avoid-configfs-state-workqueue-uevents.patch" "$PATCH_DIR/"
cp "$STOCK_CONFIG" "$USER_CONFIG"

for symbol in CONFIG_USB_CONFIGFS_UEVENT CONFIG_USB_CONFIGFS_F_ACC CONFIG_USB_MUSB_GADGET; do
    if ! grep -q "^$symbol=" "$USER_CONFIG"; then
        printf '%s=y\n' "$symbol" >>"$USER_CONFIG"
    fi
done

echo "Staged upstream AOA patches in $PATCH_DIR"
echo "Staged kernel config in $USER_CONFIG"
