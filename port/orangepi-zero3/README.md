# Orange Pi Zero 3 port (Armbian prototype)

This is an Armbian bring-up layer for the upstream `aawgd` daemon. It keeps the original Bluetooth AA profile, Wi-Fi negotiation and byte-for-byte TCP/USB forwarder; it does not decode or transform Android Auto media.

## Current status and support boundary

The Orange Pi Zero 3 works as a Wireless Android Auto dongle with Armbian. See [`TESTING.md`](TESTING.md) for hardware results and remaining validation.

The running board/image exposes `musb-hdrc.4.auto`; a CDC ACM ConfigFS gadget enumerated on a development PC, and the AOA accessory function is present in the kernel. The Orange Pi USB-C port has also been used successfully as the data and power connection to the car. The driver exposes BR/EDR Bluetooth and Wi-Fi AP mode; the generic AP default is `AAWirelessDongle` on 5 GHz channel 36. The test installation customized its SSID to `Android_Auto_Peugeot_208`.

The port reuses upstream Bluetooth AA negotiation and AOA forwarding. It uses `PHONE_FIRST`, so it waits for the phone to establish Bluetooth and Wi-Fi/TCP before exposing the USB gadget to the head unit. A separate BlueZ pairing agent is installed because the Armbian image does not launch the Buildroot image's `bt-agent`. The installer disables BlueZ's SAP plugin, which had reserved RFCOMM channel 8; after disabling it, the AA profile listener registered and the phone connected.

This is an Armbian port, not an Orange Pi Buildroot image. Repeated abrupt-power-cut recovery, filesystem checks, heat, and long-duration stability remain to be validated. A regular USB host port cannot substitute for the USB-C OTG data port.

## Host development

On Linux/WSL2 with Docker available, initialize the pinned Buildroot submodule and run `scripts/build-arm64-docker.sh` for reproducible ARM64 cross compilation. It places `aawgd` and `umtprd` in the ignored `build/` directory. `aawgd` is a Linux C++ daemon; do not use a Windows-native build. These Buildroot binaries prove compilation, but are dynamically linked to Buildroot's own userspace and are **not assumed runnable on Armbian**. For the board, run `scripts/build-aawgd-on-armbian.sh` from this checkout on the Orange Pi; it builds against the target's installed ABI and places the resulting programs at `/usr/local/bin/aawgd` and `/usr/sbin/umtprd`.

The upstream Buildroot image is Raspberry Pi-specific. Do not use its boot image on the Orange Pi. The reusable package `aa_wireless_dongle/package/aawg` can be built in an Armbian userspace or later integrated into a board-specific Buildroot configuration.

## Board-side diagnostic

Copy `scripts/opi3-diagnose.sh` to the board and run it as root. It only reads system state and writes a report to stdout. Use the test sequence in [`TESTING.md`](TESTING.md). For USB, connect the board's USB-C port to a separate computer through a data cable while powering the board in a way that does not back-feed the host. The car head unit and its port must provide power while acting as USB host; verify electrical behavior on the real vehicle before prolonged installation. A self-powered hub or isolated power arrangement is safer for bench validation.

All setup scripts here are explicitly for the Orange Pi. `install-armbian.sh` installs runtime dependencies and enables services on the target board; do not run it on the development PC. Build the native ARM64 programs first. The installer checks prerequisites and does not force a USB role or load a guessed vendor driver.

See [`HARDWARE.md`](HARDWARE.md) and [`TESTING.md`](TESTING.md) for observed hardware evidence and the remaining validation gates.
