# Orange Pi Zero 3 port (Armbian prototype)

This is an Armbian bring-up layer for the upstream `aawgd` daemon. It keeps the original Bluetooth AA profile, Wi-Fi negotiation and byte-for-byte TCP/USB forwarder; it does not decode or transform Android Auto media.

## Current support boundary

The tested Orange Pi Zero 3 and Armbian image expose `musb-hdrc.4.auto` as a USB Device Controller, and a CDC ACM ConfigFS gadget enumerated on the development PC. The kernel also has the Android Accessory ConfigFS function. This confirms the basic data path for this board/image, but not the host-initiated AOA handshake or USB-C VBUS/power behavior in the vehicle. A regular USB host port cannot substitute for the USB-C OTG data port.

The tested kernel exposes `f_accessory`, and the AW859A/UWE5622 driver exposes BR/EDR Bluetooth and Wi-Fi AP mode. The project AP was visible to the development PC on 5 GHz channel 36. The daemon starts its Bluetooth profiles; a non-interactive BlueZ pairing agent is installed as a separate systemd service because the upstream Armbian setup did not launch the Buildroot image's `bt-agent`. The installer disables BlueZ's unrelated SAP plugin because it reserves RFCOMM channel 8, also used by the upstream Android Auto profile. On the physical board, excluding SAP removed the bind conflict and the Android Auto listener appeared on channel 8. Android Auto RFCOMM/Wi-Fi negotiation and AOA remain to be validated.

## Host development

On Linux/WSL2 with Docker available, initialize the pinned Buildroot submodule and run `scripts/build-arm64-docker.sh` for reproducible ARM64 cross compilation. It places `aawgd` and `umtprd` in the ignored `build/` directory. `aawgd` is a Linux C++ daemon; do not use a Windows-native build. These Buildroot binaries prove compilation, but are dynamically linked to Buildroot's own userspace and are **not assumed runnable on Armbian**. For the board, run `scripts/build-aawgd-on-armbian.sh` from this checkout on the Orange Pi; it builds against the target's installed ABI and places the resulting programs at `/usr/local/bin/aawgd` and `/usr/sbin/umtprd`.

The upstream Buildroot image is Raspberry Pi-specific. Do not use its boot image on the Orange Pi. The reusable package `aa_wireless_dongle/package/aawg` can be built in an Armbian userspace or later integrated into a board-specific Buildroot configuration.

## Board-side diagnostic

Copy `scripts/opi3-diagnose.sh` to the board and run it as root. It only reads system state and writes a report to stdout. Use the test sequence in [`TESTING.md`](TESTING.md). For USB, connect the board's USB-C port to a separate computer through a data cable while powering the board in a way that does not back-feed the host. The car head unit and its port must provide power while acting as USB host; verify electrical behavior on the real vehicle before prolonged installation. A self-powered hub or isolated power arrangement is safer for bench validation.

All setup scripts here are explicitly for the Orange Pi. `install-armbian.sh` installs runtime dependencies and enables services on the target board; do not run it on the development PC. Build the native ARM64 programs first. The installer checks prerequisites and does not force a USB role or load a guessed vendor driver.

See [`HARDWARE.md`](HARDWARE.md) and [`TESTING.md`](TESTING.md) for observed hardware evidence and the remaining validation gates.
