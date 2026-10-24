#!/bin/sh
# Read-only hardware report. Run as root on the Orange Pi Zero 3.
set -u

section() { printf '\n== %s ==\n' "$1"; }
read_file() { [ -r "$1" ] && { printf '%s: ' "$1"; tr '\0' ' ' < "$1"; printf '\n'; }; }

section 'Board and kernel'
read_file /proc/device-tree/model
uname -a
printf 'cmdline: '; cat /proc/cmdline

section 'USB device-controller support'
printf 'UDCs: '; ls -1 /sys/class/udc 2>/dev/null || true
for udc in /sys/class/udc/*; do
    [ -e "$udc" ] || continue
    printf '%s state=' "${udc##*/}"
    cat "$udc/state" 2>/dev/null || true
    printf '  driver='; readlink -f "$udc/device/driver" 2>/dev/null || true
done
printf 'configfs: '; mount | awk '$3 == "/sys/kernel/config" { print; found=1 } END { if (!found) print "not mounted" }'
printf 'gadget functions: '; ls -1 /sys/kernel/config/usb_gadget 2>/dev/null || true
printf 'accessory function: '
if [ -d /sys/kernel/config/usb_gadget/g1/functions/accessory.0 ] || [ -d /sys/kernel/config/usb_gadget/accessory/functions/accessory.usb0 ]; then
    echo present
else
    echo 'not currently instantiated (kernel support still needs checking)'
fi
grep -E 'CONFIG_USB_(CONFIGFS|CONFIGFS_F_ACC|DWC2|DWC3|MUSB|GADGET)' "/boot/config-$(uname -r)" /proc/config.gz 2>/dev/null | head -40 || true
ls -l /dev/usb_accessory 2>/dev/null || true

section 'Wi-Fi capabilities'
ip -brief link 2>/dev/null || true
iw dev 2>/dev/null || true
iw list 2>/dev/null | sed -n '/Supported interface modes:/,/Band [0-9]/p' | head -80

section 'Bluetooth'
rfkill list 2>/dev/null || true
bluetoothctl show 2>/dev/null || true
btmgmt info 2>/dev/null || hciconfig -a 2>/dev/null || true

section 'Relevant modules and kernel messages'
lsmod 2>/dev/null | grep -Ei 'uwe|sprd|bluetooth|btusb|dwc|musb|udc|gadget|accessory' || true
dmesg 2>/dev/null | grep -Ei 'uwe|sprd|bluetooth|hci|usb0|udc|gadget|accessory|dwc|musb' | tail -100 || true

section 'Thermal sensors'
for f in /sys/class/thermal/thermal_zone*/temp; do [ -r "$f" ] && { printf '%s: ' "$f"; cat "$f"; }; done
