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
- Downloaded the Armbian community Debian 13 Trixie minimal image for `orangepizero3` (`26.11.0-trunk.108`, kernel `6.18.57`). The published compressed-image SHA-256 matched (`3d8ef4b125b8b1029a516be9d91e8decb544c3019334626ee22e39ab7ad45015`). Wrote it to the identified 16 GB microSD and verified the entire 1,619,001,344-byte raw image by reading the card back (`a6969da7fab2bb5fe818e4ab90aa2bd28ad3b5c4dbf3dd824abc9d451a899555`). The board booted this image successfully, as confirmed below.
- Commit `7535138` added the initial Armbian port scaffolding. No remote push was made.
- The flashed card booted successfully on the Orange Pi Zero 3. Confirmed remotely: Armbian Debian 13, ARM64, kernel `6.18.57-current-sunxi64`, correct device-tree model, Ethernet, `wlan0`, and active BlueZ/HCI UART controller (Spreadtrum, HCI 5.0). RFCOMM kernel support is loaded. This verifies basic boot/radio enumeration, not phone pairing, SDP, or AA profile operation.
- On-target ARM64 build completed for `umtprd` and `aawgd`; the daemon and runtime `dbus-cxx` library are installed on the board and `ldd` resolves all shared libraries. The first attempt exposed two build defects, fixed locally: the script omitted `PKG_CONFIG=pkg-config`, and the Makefile placed link libraries before objects. The source Makefile now separates compile flags from link libraries and puts `LDLIBS` after objects.
- On-target `iw list` advertises AP mode on both 2.4 GHz and 5 GHz. A temporary WPA2 hostapd test on channel 36 returned `AP-ENABLED` while Bluetooth remained active; the test was stopped and the regulatory setting reset. The development PC's Wi-Fi scan did not show the test SSID, so independent client discovery, DHCP, throughput and coexistence stability remain unverified.
- A temporary ConfigFS CDC ACM gadget bound to `musb-hdrc.4.auto`; Windows enumerated `USB Composite Device` (`VID_1D6B&PID_0104`) and `USB Serial Device (COM5)`. The test gadget was unbound and removed. This confirms the USB-C data path and generic peripheral gadget functionality with this setup.
- The currently installed `6.18.57` kernel still lacks `CONFIG_USB_CONFIGFS_F_ACC`/`usb_f_accessory`, so `/dev/usb_accessory` is absent and the upstream daemon remains blocked on the board. The separate, verified `6.18.58` candidate enables AOA and MUSB gadget mode but has not yet been installed.
- Confirmed Armbian's `orangepizero3` framework selects Linux `6.18.58` for the current branch and the `uwe5622-allwinner` extension. Staged the upstream AOA patches and enabled `CONFIG_USB_CONFIGFS_UEVENT=y`, `CONFIG_USB_CONFIGFS_F_ACC=y`, and `CONFIG_USB_MUSB_GADGET=y`. Updated the first AOA patch for the 6.18 ConfigFS include layout and HID API. The patches apply and the ARM64 cross-build completes.
- Kernel cross-build attempts exposed case-colliding Linux file paths in the Windows-originated Armbian checkout (`xt_DSCP.h`/`xt_dscp.h`, similar netfilter headers and `.c` files). Restoring the tracked files in the Armbian pre-build step allowed the build past compile errors and through module compilation to `modpost`; `modpost` then reported duplicate exports from `xt_RATEEST`/`xt_rateest`, leading to a broader restore list for all colliding paths.
- After freeing space on `C:`, Docker still had damaged/unavailable containerd blobs. With authorization, Docker Desktop and its WSL backend were restarted to release the busy data disk; the persistent `opi3-armbian-build` volume was readable afterward. No volumes or images were removed. The separate PostgreSQL container restarted and is running again.
- The first recovered kernel build completed but inspection showed `CONFIG_USB_MUSB_GADGET` was off, so its AOA image was rejected as an install candidate. Enabled the MUSB peripheral mode in the Orange Pi kernel staging script and rebuilt. The second build completed successfully in 17:47, kernel `6.18.58-S2926-D68f5-Pc682-C5e8f-H0759-HK01ba-Vc222-Bd5c8-R448a`. Verified the packaged kernel config has `CONFIG_USB_MUSB_GADGET=y`, `CONFIG_USB_CONFIGFS_UEVENT=y`, and `CONFIG_USB_CONFIGFS_F_ACC=y`; the image package contains `usb_f_accessory.ko`, `musb_hdrc.ko`, and `sunxi.ko`. Copied the kernel image and DTB `.deb` files to ignored `port/orangepi-zero3/build/kernel-candidate/`; SHA-256: image `a00e1151d477b91a723561eff8b27d5fddda037dbdfa7ac1051cf66751bc55c3`, DTB `e428824bf66141053f4988c10fd6582136e3f4b5cc49bd40b0c83cf84baff594`. The Orange Pi still boots the original `6.18.57` kernel; no kernel package has been installed.
- Installed hostapd for the non-persistent radio test only. Installed the target daemon and `umtprd`; the systemd units have not been installed or enabled. Build dependencies and `dbus-cxx` are present on the board. No Android phone or vehicle head-unit Android Auto session has been tested.
- Changes remain local; no remote push was made.

## Pending / blockers

- The corrected native ARM64 build script completed end-to-end on the Orange Pi; both target binaries were rebuilt and installed.
- Provision the persistent project services only after resolving kernel AOA support. Do not enable the current daemon service: its preflight correctly fails without `/dev/usb_accessory` and AOA configfs support.
- Make a full backup or clone of the bootable microSD before installing the verified 6.18.58 AOA kernel candidate. Then install the matching image/DTB packages and verify boot recovery, `/sys/class/udc`, ConfigFS, FunctionFS and AOA enumeration. Do not enable the proxy service until those hardware checks pass.
- Verify AP discovery from a separate phone/client, DHCP, sustained throughput, and Wi-Fi/Bluetooth coexistence. Bluetooth Classic HCI is active, but phone pairing, SDP, and RFCOMM profile exchange have not been validated.
- Confirm the actual board revision's USB-C power/VBUS behavior and test generic gadget and AOA enumeration against a separate host without back-feeding power.
- Complete end-to-end Android Auto and power-cut/endurance testing on the Peugeot head unit.
- The installer and systemd units remain uninstalled/unenabled on the board pending AOA kernel validation; current hostapd test package was installed for the temporary AP test only. No host/PC network configuration was changed.

## Next recommended task

Back up the bootable microSD, install the verified 6.18.58 kernel image and DTB packages, then run the on-board gadget/AOA validation sequence. The built candidate is retained under ignored `port/orangepi-zero3/build/kernel-candidate/`; do not install it until the card backup is available.
