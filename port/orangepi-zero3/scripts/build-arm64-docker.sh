#!/bin/sh
# Reuse upstream Buildroot dependencies to cross-compile the daemon (not an SD image).
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
docker compose -f "$ROOT/docker-compose.yml" run --rm --entrypoint /bin/bash bash -lc '
    git config --global --add safe.directory /app/.git/modules/buildroot
    git clone --shared /app/buildroot /tmp/buildroot
    make -C /tmp/buildroot BR2_EXTERNAL=/app/aa_wireless_dongle O=/app/buildroot/output/rpi5 raspberrypi5_defconfig
    make -C /tmp/buildroot O=/app/buildroot/output/rpi5 aawg umtprd
    mkdir -p /app/port/orangepi-zero3/build
    cp /app/buildroot/output/rpi5/target/usr/bin/aawgd /app/port/orangepi-zero3/build/aawgd
    cp /app/buildroot/output/rpi5/target/usr/sbin/umtprd /app/port/orangepi-zero3/build/umtprd
    file /app/port/orangepi-zero3/build/aawgd /app/port/orangepi-zero3/build/umtprd
'
