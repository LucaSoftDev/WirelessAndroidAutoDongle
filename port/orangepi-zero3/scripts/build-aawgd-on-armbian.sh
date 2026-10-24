#!/bin/sh
# Native ARM64 build for the target board; avoids Buildroot/glibc ABI assumptions.
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo 'Run this build script as root on the Orange Pi Zero 3.' >&2
    exit 1
fi
if ! grep -qi armbian /etc/os-release || ! tr '\0' ' ' </proc/device-tree/model 2>/dev/null | grep -qi 'Orange Pi Zero 3'; then
    echo 'This script is only for Armbian running on an Orange Pi Zero 3.' >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
AAWG_SRC=$REPO_DIR/aa_wireless_dongle/package/aawg/src
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake curl pkg-config libsigc++-3.0-dev libprotobuf-dev protobuf-compiler

curl -fsSL https://github.com/dbus-cxx/dbus-cxx/archive/refs/tags/2.5.2.tar.gz -o "$TMP_DIR/dbus-cxx.tar.gz"
mkdir "$TMP_DIR/dbus-cxx"
tar -xzf "$TMP_DIR/dbus-cxx.tar.gz" --strip-components=1 -C "$TMP_DIR/dbus-cxx"
cmake -S "$TMP_DIR/dbus-cxx" -B "$TMP_DIR/dbus-cxx-build" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_TESTING=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TOOLS=OFF \
    -DENABLE_GLIB_SUPPORT=OFF -DENABLE_QT_SUPPORT=OFF -DENABLE_UV_SUPPORT=OFF
cmake --build "$TMP_DIR/dbus-cxx-build" --parallel 2
cmake --install "$TMP_DIR/dbus-cxx-build"
ldconfig

curl -fsSL https://github.com/viveris/uMTP-Responder/archive/umtprd-1.6.8.tar.gz -o "$TMP_DIR/umtprd.tar.gz"
mkdir "$TMP_DIR/umtprd"
tar -xzf "$TMP_DIR/umtprd.tar.gz" --strip-components=1 -C "$TMP_DIR/umtprd"
make -C "$TMP_DIR/umtprd" -j2
install -D -m 0755 "$TMP_DIR/umtprd/umtprd" /usr/sbin/umtprd
install -D -m 0644 "$REPO_DIR/aa_wireless_dongle/board/common/rootfs_overlay/etc/umtprd/umtprd.conf" /etc/umtprd/umtprd.conf

make -C "$AAWG_SRC" clean
make -C "$AAWG_SRC" PROTOC=protoc -j2
install -D -m 0755 "$AAWG_SRC/aawgd" /usr/local/bin/aawgd
echo 'Native ARM64 build complete: /usr/local/bin/aawgd and /usr/sbin/umtprd'
