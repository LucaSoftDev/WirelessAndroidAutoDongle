# Development progress

Date: 2026-10-24

## Investigated

- Cloned `nisargjhaveri/WirelessAndroidAutoDongle` (`main`, initial checkout `ef64522`) and initialized its pinned Buildroot submodule (`3815d578c5759fa824322ea3d95ad51b55ab888e`).
- Read the full upstream README and BUILDING guide; inspected the `aawg` package, USB accessory manager, BlueZ profile registration, TCP forwarder, original network and startup scripts, and Raspberry Pi-only Buildroot defconfigs.
- Confirmed upstream daemon's media/data path is a raw bidirectional TCP-to-`/dev/usb_accessory` byte forwarder. The daemon does not transcode audio/video. It depends on Linux AOA `f_accessory` and configfs rather than implementing AOA in userspace.
- Consulted Orange Pi build and Linux-sunxi board references plus aa-proxy-rs documentation. Those sources do not prove USB gadget/AOA or radio feature support on the specific Zero 3 plus Armbian image.

## Implemented

- Added `port/orangepi-zero3/` Armbian bring-up documentation, a read-only board diagnostic, target-only native ARM64 build and installer scripts, daemon preflight and systemd services.
- Added systemd preparation for the two original configfs gadgets (default/MTP and AOA accessory) and the upstream `umtprd` FunctionFS endpoint. These still require a kernel with `f_accessory` and should be tried only after the diagnostic and simple gadget test.
- Follow-up review found that the FunctionFS systemd unit assumed `/dev/ffs-mtp` existed. The unit now creates this volatile mountpoint on each start before mounting FunctionFS, so a clean boot does not fail solely because `/dev` was recreated.
- Left upstream daemon and Raspberry Pi Buildroot configuration unchanged. Armbian service refuses to start if UDC, configfs gadget prerequisites, `/dev/usb_accessory`, BlueZ, or `wlan0` are missing.

## Tested

- Repository clone and pinned Buildroot submodule checkout completed.
- Docker Compose image built. ARM64 `raspberrypi5_defconfig` Buildroot `aawg` and `umtprd` package builds completed. The ignored files in `port/orangepi-zero3/build/` are ELF64 AArch64 PIE binaries. `aawgd` depends on dbus-cxx, sigc++ 3, protobuf-lite 29, and Abseil shared libraries; this was a compiler check, not an Orange Pi image. Buildroot runtime ABI/library compatibility with Armbian is unverified, so use the native Armbian build script for installation.
- Ran POSIX shell syntax validation (`sh -n`) on every new script successfully. `readelf` confirmed ELF64, AArch64, PIE and listed the `aawgd` shared-library dependencies.
- Validated the FunctionFS pre-start directory-creation command syntax and reviewed the resulting unit; actual systemd startup and FunctionFS mount remain pending on Orange Pi hardware.
- Commit `7535138` added the initial Armbian port scaffolding. No remote push was made.
- No physical board, Android phone or vehicle head unit was available to this development environment; no hardware test is recorded as passed.

## Pending / blockers

- Native Armbian build script has not run on the board; its archive URLs/dependency availability must be confirmed on the selected Armbian image.
- Runtime service startup, gadget binding, AP setup and AOA behavior remain unverified.
- Confirm USB-C pin routing/role and VBUS behavior for the actual board revision; verify Armbian UDC, USB gadget and AOA `f_accessory` support on board.
- Verify UWE5622 Wi-Fi AP on 5 GHz, Bluetooth Classic (BR/EDR), coexistence and firmware initialization on the chosen Armbian image.
- Complete end-to-end Android Auto and power-cut/endurance testing on the Peugeot head unit.
- Installer stages runtime packages and systemd services, including ConfigFS/FunctionFS preparation; it does not configure hostapd/DHCP because NetworkManager and driver behavior must first be measured on the target.

## Next recommended task

Run `port/orangepi-zero3/scripts/opi3-diagnose.sh` on the Orange Pi with the exact intended Armbian image. Use the report to decide whether the selected kernel can support the upstream AOA gadget; only then finalize the Wi-Fi/network and configfs provisioning scripts.
