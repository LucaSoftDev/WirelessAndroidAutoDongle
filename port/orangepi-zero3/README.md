# Orange Pi Zero 3 port (Armbian prototype)

This is an Armbian bring-up layer for the upstream `aawgd` daemon. It keeps the original Bluetooth AA profile, Wi-Fi negotiation and byte-for-byte TCP/USB forwarder; it does not decode or transform Android Auto media.

## Current support boundary

This checkout does **not** prove that every Orange Pi Zero 3 image exposes the USB peripheral controller or the Android Accessory function. The USB-C connector is the candidate USB0/OTG data port and supplies board power, but it must be confirmed against the exact board revision, image, device tree, and actual host enumeration. A regular USB host port cannot substitute for it.

Armbian kernel support may expose a UDC while still omitting `f_accessory`. The AW859A/UWE5622 radio is also image/kernel dependent. Verify Bluetooth BR/EDR and Wi-Fi AP operation on the actual image before attempting the full proxy. Reports of AP/5 GHz operation are not proof for the selected Armbian kernel/firmware or concurrent Bluetooth coexistence.

## Host development

On Linux/WSL2 with Docker available, initialize the pinned Buildroot submodule and run `scripts/build-arm64-docker.sh` for reproducible ARM64 cross compilation. It places `aawgd` and `umtprd` in the ignored `build/` directory. `aawgd` is a Linux C++ daemon; do not use a Windows-native build. These Buildroot binaries prove compilation, but are dynamically linked to Buildroot's own userspace and are **not assumed runnable on Armbian**. For the board, run `scripts/build-aawgd-on-armbian.sh` from this checkout on the Orange Pi; it builds against the target's installed ABI and places the resulting programs at `/usr/local/bin/aawgd` and `/usr/sbin/umtprd`.

The upstream Buildroot image is Raspberry Pi-specific. Do not use its boot image on the Orange Pi. The reusable package `aa_wireless_dongle/package/aawg` can be built in an Armbian userspace or later integrated into a board-specific Buildroot configuration.

## Board-side diagnostic

Copy `scripts/opi3-diagnose.sh` to the board and run it as root. It only reads system state and writes a report to stdout. Use the test sequence in [`TESTING.md`](TESTING.md). For USB, connect the board's USB-C port to a separate computer through a data cable while powering the board in a way that does not back-feed the host. The car head unit and its port must provide power while acting as USB host; verify electrical behavior on the real vehicle before prolonged installation. A self-powered hub or isolated power arrangement is safer for bench validation.

All setup scripts here are explicitly for the Orange Pi. `install-armbian.sh` installs runtime dependencies and enables services on the target board; do not run it on the development PC. Build the native ARM64 programs first. The installer checks prerequisites and does not force a USB role or load a guessed vendor driver.

See [`HARDWARE.md`](HARDWARE.md) and [`TESTING.md`](TESTING.md) for evidence and validation gates. Hardware results remain pending until run on the board.
