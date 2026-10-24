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
- Downloaded the Armbian community Debian 13 Trixie minimal image for `orangepizero3` (`26.11.0-trunk.108`, kernel `6.18.57`). The published compressed-image SHA-256 matched (`3d8ef4b125b8b1029a516be9d91e8decb544c3019334626ee22e39ab7ad45015`). Wrote it to the identified 16 GB microSD and verified the entire 1,619,001,344-byte raw image by reading the card back (`a6969da7fab2bb5fe818e4ab90aa2bd28ad3b5c4dbf3dd824abc9d451a899555`). This confirms the card contents only; the board has not booted this image yet.
- Commit `7535138` added the initial Armbian port scaffolding. No remote push was made.
- The flashed card booted successfully on the Orange Pi Zero 3. Confirmed remotely: Armbian Debian 13, ARM64, kernel `6.18.57-current-sunxi64`, correct device-tree model, Ethernet, `wlan0`, and active BlueZ/HCI UART controller (Spreadtrum, HCI 5.0). RFCOMM kernel support is loaded. This verifies basic boot/radio enumeration, not phone pairing, SDP, or AA profile operation.
- On-target ARM64 build completed for `umtprd` and `aawgd`; the daemon and runtime `dbus-cxx` library are installed on the board and `ldd` resolves all shared libraries. The first attempt exposed two build defects, fixed locally: the script omitted `PKG_CONFIG=pkg-config`, and the Makefile placed link libraries before objects. The source Makefile now separates compile flags from link libraries and puts `LDLIBS` after objects.
- On-target `iw list` advertises AP mode on both 2.4 GHz and 5 GHz. A temporary WPA2 hostapd test on channel 36 returned `AP-ENABLED` while Bluetooth remained active; the test was stopped and the regulatory setting reset. The development PC's Wi-Fi scan did not show the test SSID, so independent client discovery, DHCP, throughput and coexistence stability remain unverified.
- A temporary ConfigFS CDC ACM gadget bound to `musb-hdrc.4.auto`; Windows enumerated `USB Composite Device` (`VID_1D6B&PID_0104`) and `USB Serial Device (COM5)`. The test gadget was unbound and removed. This confirms the USB-C data path and generic peripheral gadget functionality with this setup.
- The kernel config does **not** enable `CONFIG_USB_MUSB_GADGET` and has no `CONFIG_USB_CONFIGFS_F_ACC`/`usb_f_accessory` module. `/dev/usb_accessory` is absent. Generic serial gadget success therefore does not establish AOA support; the upstream daemon cannot run end-to-end until an AOA-capable kernel is available. The UDC is registered but AOA remains blocked.
- Installed hostapd for the non-persistent radio test only. Installed the target daemon and `umtprd`; the systemd units have not been installed or enabled. Build dependencies and `dbus-cxx` are present on the board. No Android phone or vehicle head-unit Android Auto session has been tested.
- Commits `7535138` (Armbian port scaffolding) and `b0ce133` (native build and model detection fixes) are local. No remote push was made.

## Pending / blockers

- Build fixes are in the working tree and need a local commit. The corrected native ARM64 build script completed end-to-end on the Orange Pi; both target binaries were rebuilt and installed.
- Provision the persistent project services only after resolving kernel AOA support. Do not enable the current daemon service: its preflight correctly fails without `/dev/usb_accessory` and AOA configfs support.
- Obtain/build an Orange Pi Zero 3 kernel with MUSB peripheral support and Android `f_accessory`, or select an image/kernel that provides it; verify FunctionFS/MTP and configfs after that change.
- Verify AP discovery from a separate phone/client, DHCP, sustained throughput, and Wi-Fi/Bluetooth coexistence. Bluetooth Classic HCI is active, but phone pairing, SDP, and RFCOMM profile exchange have not been validated.
- Confirm the actual board revision's USB-C power/VBUS behavior and test generic gadget and AOA enumeration against a separate host without back-feeding power.
- Complete end-to-end Android Auto and power-cut/endurance testing on the Peugeot head unit.
- The installer and systemd units remain uninstalled/unenabled on the board pending AOA kernel validation; current hostapd test package was installed for the temporary AP test only. No host/PC network configuration was changed.

## Next recommended task

Resolve AOA support first: the current Armbian kernel supports a generic ACM gadget on the USB-C path but lacks the `f_accessory` function required by the upstream daemon. Investigate an available Armbian kernel package/image with AOA enabled or prepare a board-specific kernel build, then retest AOA enumeration before enabling the proxy service.
