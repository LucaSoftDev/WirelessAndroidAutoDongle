#!/bin/sh
# Install runtime helpers on the Orange Pi Zero 3. Run explicitly as root there.
# Build natively first with build-aawgd-on-armbian.sh.
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this installer as root on the Orange Pi Zero 3.' >&2
    exit 1
fi
if ! grep -qi armbian /etc/os-release; then
    echo 'This installer targets Armbian on the Orange Pi, not the development host.' >&2
    exit 1
fi
if ! tr '\0' ' ' </proc/device-tree/model 2>/dev/null | grep -Eqi 'Orange.?Pi.?Zero.?3'; then
    echo 'Device-tree model is not Orange Pi Zero 3; refusing installation.' >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PORT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_DIR=$(CDPATH= cd -- "$PORT_DIR/../../" && pwd)

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bluez bluez-tools dbus hostapd dnsmasq iw rfkill
# The generic Debian services have no Android Auto AP configuration. Keep them
# stopped; the dedicated units below bind only wlan0 and serve its DHCP range.
systemctl disable --now hostapd.service dnsmasq.service 2>/dev/null || true
install -D -m 0755 "$SCRIPT_DIR/aawgd-preflight" /usr/local/sbin/aawgd-preflight
install -D -m 0755 "$SCRIPT_DIR/aawg-bluetooth-configure" /usr/local/sbin/aawg-bluetooth-configure
install -D -m 0755 "$SCRIPT_DIR/aawg-wifi-ap-configure" /usr/local/sbin/aawg-wifi-ap-configure
install -D -m 0644 "$PORT_DIR/systemd/aawgd.service" /etc/systemd/system/aawgd.service
install -D -m 0644 "$PORT_DIR/systemd/aawg-bluetooth-agent.service" /etc/systemd/system/aawg-bluetooth-agent.service
install -D -m 0644 "$PORT_DIR/systemd/bluetoothd-no-sap.conf" /etc/systemd/system/bluetooth.service.d/10-aawg-no-sap.conf
install -D -m 0644 "$PORT_DIR/systemd/aawg-usb-gadget.service" /etc/systemd/system/aawg-usb-gadget.service
install -D -m 0644 "$PORT_DIR/systemd/aawg-functionfs.service" /etc/systemd/system/aawg-functionfs.service
install -D -m 0644 "$PORT_DIR/systemd/aawg-wifi-ap.service" /etc/systemd/system/aawg-wifi-ap.service
install -D -m 0644 "$PORT_DIR/systemd/aawg-dnsmasq.service" /etc/systemd/system/aawg-dnsmasq.service
install -D -m 0644 "$PORT_DIR/config/dnsmasq.conf" /etc/aawg-dnsmasq.conf
install -D -m 0644 "$PORT_DIR/README.md" /usr/share/doc/aawg-orangepi/README.md
install -D -m 0755 "$SCRIPT_DIR/opi3-diagnose.sh" /usr/local/sbin/opi3-diagnose
install -D -m 0755 "$SCRIPT_DIR/usb-gadget-configfs" /usr/local/sbin/usb-gadget-configfs
install -D -m 0644 "$REPO_DIR/aa_wireless_dongle/board/common/rootfs_overlay/etc/aawgd.conf" /etc/aawgd.conf
install -D -m 0644 "$REPO_DIR/aa_wireless_dongle/board/common/rootfs_overlay/etc/umtprd/umtprd.conf" /etc/umtprd/umtprd.conf

/usr/local/sbin/aawg-bluetooth-configure

AAWGD_BINARY=${1:-}
UMTPRD_BINARY=${2:-}
if [ -n "$AAWGD_BINARY" ] && [ -x "$AAWGD_BINARY" ]; then
    [ "$AAWGD_BINARY" = /usr/local/bin/aawgd ] || install -D -m 0755 "$AAWGD_BINARY" /usr/local/bin/aawgd
elif [ ! -x /usr/local/bin/aawgd ]; then
    echo 'Missing /usr/local/bin/aawgd. Build natively with build-aawgd-on-armbian.sh first.' >&2
    exit 2
fi
if [ -n "$UMTPRD_BINARY" ] && [ -x "$UMTPRD_BINARY" ]; then
    [ "$UMTPRD_BINARY" = /usr/sbin/umtprd ] || install -D -m 0755 "$UMTPRD_BINARY" /usr/sbin/umtprd
elif [ ! -x /usr/sbin/umtprd ]; then
    echo 'Missing /usr/sbin/umtprd. Build natively with build-aawgd-on-armbian.sh first.' >&2
    exit 2
fi

systemctl daemon-reload
systemctl enable aawg-usb-gadget.service aawg-functionfs.service aawg-wifi-ap.service aawg-dnsmasq.service aawg-bluetooth-agent.service
systemctl enable aawgd.service
if ! systemctl show bluetooth.service --property=ExecStart --value | grep -Fq -- '--noplugin=sap'; then
    systemctl restart bluetooth.service
fi
systemctl start aawg-bluetooth-agent.service
echo 'Installed. Complete the phone AOA and vehicle checks in port/orangepi-zero3/TESTING.md before relying on the dongle.'
echo 'Run opi3-diagnose for a hardware report. Start the full stack with: systemctl start aawgd'
