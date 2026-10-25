# Development progress

Date: 2026-10-25

## Latest hardware validation (2026-10-25)

- Installed the verified Armbian `6.18.58` image and matching DTB packages on the Orange Pi after the user explicitly declined a microSD backup. The board rebooted successfully and is reachable on the network. Running kernel: `6.18.58-current-sunxi64`.
- On the board, confirmed `/sys/class/udc/musb-hdrc.4.auto`, ConfigFS, `CONFIG_USB_MUSB_GADGET=y`, `CONFIG_USB_CONFIGFS_UEVENT=y`, and `CONFIG_USB_CONFIGFS_F_ACC=y`. `modprobe usb_f_accessory` succeeds and `/dev/usb_accessory` is created by the project's configfs setup.
- Real USB data path validated: a temporary CDC ACM configfs gadget reached UDC state `configured`; Windows enumerated `USB Composite Device` (`VID_1D6B:0104`) and `USB Serial Device (COM5)`. The temporary CDC gadget was removed.
- A direct bind of the AOA accessory gadget (`VID_18D1:2D00`) did **not** enumerate on Windows. This is not yet a valid Android Accessory handshake test: upstream `aawgd` normally binds the default MTP gadget first and switches to the AOA gadget only after the host sends the AOA start request. No compatible Android Auto head unit or phone session has been tested.
- Tried bringing up the default MTP gadget for a Windows-side enumeration check, but the matching systemd units are not installed and subsequent SSH command sessions stopped returning command output (SSH authentication/TCP still succeed). Target state may therefore contain a temporary configfs binding; recover SSH/serial or reboot the board, then inspect both gadget `UDC` attributes and unbind them before continuing. Do not claim AOA enumeration passed.
- After the user rebooted the board, ICMP and TCP/22 remained reachable and SSH public-key authentication succeeded, but new SSH command sessions and SFTP still did not return output. The board-side inspection therefore remains blocked; use the already-open root console to run the read-only diagnostic below before further gadget changes.
- No project services were installed or enabled on the board. No Wi-Fi AP, phone pairing, Wireless Android Auto, or head-unit tests have been run.

### Kernel lockup investigation (in progress)

- The board's `dmesg` after booting the AOA-capable 6.18.58 kernel repeatedly reports `BUG: workqueue lockup` on the `events` pool, with an in-flight `android_work [libcomposite]` callback. This is a confirmed kernel stall, but the captured output did not include a stack trace, so the precise cause remains unproven.
- Added a follow-up kernel patch to stop scheduling configfs's generic `USB_STATE` uevent worker from Android control requests and disconnect. The project's AOA setup request dispatch, `acc_ctrlrequest_composite()`, and accessory `ACCESSORY=START` handling remain in place. This is a mitigation hypothesis and requires board validation.
- Rebuilt candidate `26.11.0-trunk.110` with the first version of that patch; the source patch applied and kernel compilation started. That build has not completed yet. The local patch was then cleaned to remove an empty post-configuration block; the in-flight build has the behaviorally equivalent version with the empty block.
- Do not treat the candidate as stable or claim that it fixes the lockup until the package is built, installed, and the board is observed under USB/AOA activity for an extended period.
- The candidate build completed successfully in 17:50. The image package reports `26.11.0-trunk.110` / ARM64 and contains `usb_f_accessory.ko` and `musb_hdrc.ko`; its config has `CONFIG_USB_MUSB_GADGET=y`, `CONFIG_USB_CONFIGFS_UEVENT=y`, and `CONFIG_USB_CONFIGFS_F_ACC=y`. Package artifacts are in ignored `port/orangepi-zero3/build/kernel-candidate-lockup-mitigation/`. SHA-256 DTB: `05508d4f26a4a23152e435fbe2af4f7b3bd787b3bf494fbff2d712afdf188a6f`; image: `ea7186309ab2f006a11addd6231093eeb34b1a7acb5740408fa04b6290b99cc1`.

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
- The previously installed `6.18.57` kernel lacked `CONFIG_USB_CONFIGFS_F_ACC`; it has been replaced by the verified `6.18.58` kernel described above.
- Confirmed Armbian's `orangepizero3` framework selects Linux `6.18.58` for the current branch and the `uwe5622-allwinner` extension. Staged the upstream AOA patches and enabled `CONFIG_USB_CONFIGFS_UEVENT=y`, `CONFIG_USB_CONFIGFS_F_ACC=y`, and `CONFIG_USB_MUSB_GADGET=y`. Updated the first AOA patch for the 6.18 ConfigFS include layout and HID API. The patches apply and the ARM64 cross-build completes.
- Kernel cross-build attempts exposed case-colliding Linux file paths in the Windows-originated Armbian checkout (`xt_DSCP.h`/`xt_dscp.h`, similar netfilter headers and `.c` files). Restoring the tracked files in the Armbian pre-build step allowed the build past compile errors and through module compilation to `modpost`; `modpost` then reported duplicate exports from `xt_RATEEST`/`xt_rateest`, leading to a broader restore list for all colliding paths.
- After freeing space on `C:`, Docker still had damaged/unavailable containerd blobs. With authorization, Docker Desktop and its WSL backend were restarted to release the busy data disk; the persistent `opi3-armbian-build` volume was readable afterward. No volumes or images were removed. The separate PostgreSQL container restarted and is running again.
- The first recovered kernel build completed but inspection showed `CONFIG_USB_MUSB_GADGET` was off, so its AOA image was rejected as an install candidate. Enabled the MUSB peripheral mode in the Orange Pi kernel staging script and rebuilt. The second build completed successfully in 17:47, kernel `6.18.58-S2926-D68f5-Pc682-C5e8f-H0759-HK01ba-Vc222-Bd5c8-R448a`. Verified the packaged kernel config has `CONFIG_USB_MUSB_GADGET=y`, `CONFIG_USB_CONFIGFS_UEVENT=y`, and `CONFIG_USB_CONFIGFS_F_ACC=y`; the image package contains `usb_f_accessory.ko`, `musb_hdrc.ko`, and `sunxi.ko`. Copied the kernel image and DTB `.deb` files to ignored `port/orangepi-zero3/build/kernel-candidate/`; SHA-256: image `a00e1151d477b91a723561eff8b27d5fddda037dbdfa7ac1051cf66751bc55c3`, DTB `e428824bf66141053f4988c10fd6582136e3f4b5cc49bd40b0c83cf84baff594`. The Orange Pi still boots the original `6.18.57` kernel; no kernel package has been installed.
- Installed hostapd for the non-persistent radio test only. Installed the target daemon and `umtprd`; the systemd units have not been installed or enabled. Build dependencies and `dbus-cxx` are present on the board. No Android phone or vehicle head-unit Android Auto session has been tested.
- Changes remain local; no remote push was made.

## Pending / blockers

- The corrected native ARM64 build script completed end-to-end on the Orange Pi; both target binaries were rebuilt and installed.
- Recover target command access and clean up any temporarily bound gadget before proceeding. Kernel/UDC/AOA function prerequisites are now present; normal AOA host-initiated handshake and MTP/FunctionFS behavior still need validation. Do not enable the proxy service until these checks pass.
- Verify AP discovery from a separate phone/client, DHCP, sustained throughput, and Wi-Fi/Bluetooth coexistence. Bluetooth Classic HCI is active, but phone pairing, SDP, and RFCOMM profile exchange have not been validated.
- Confirm the actual board revision's USB-C power/VBUS behavior and test the normal AOA host-initiated handshake against the car head unit or a suitable test host without back-feeding power.
- Complete end-to-end Android Auto and power-cut/endurance testing on the Peugeot head unit.
- The installer and systemd units remain uninstalled/unenabled on the board pending USB handshake validation; current hostapd test package was installed for the temporary AP test only. No host/PC network configuration was changed.
- The lockup mitigation kernel candidate has not been installed. Current running kernel continues to show the workqueue lockup; keep USB gadget/proxy activity paused until installing the candidate and checking boot, AOA behavior, and sustained kernel logs. The SSH command channel issue may require using the user's interactive `lucas` session or root key path.
- After the user power-cycled the board, ping and TCP/22 respond and SSH key exchange succeeds. The root key is accepted and authentication completes, but the remote session never returns a shell or command output; `lucas` batch authentication with available keys is denied. No remote install was attempted. Restore an interactive board shell or working SSH command channel before installing anything.
- User-provided post-reboot logs confirm the same workqueue lockup persists 54 minutes after boot: `android_work [libcomposite]` is in-flight, with reported stuck duration increasing from 2826 to 2979 seconds and load average around 6. The candidate kernel therefore remains uninstalled. A further root interactive SSH attempt and package transfer both timed out after authentication/connection setup; no remote files were changed.
- A follow-up attempted to inspect the latest `android_work` worker PID (`7941`) via `/proc`, but it no longer existed by the time `ps` and `cat` ran. No worker stack was captured; the latest `in-flight` line is only a time-specific snapshot. Installing the candidate remains blocked by the root SSH session/transfer failure.

## Next recommended task

Run the read-only board diagnostic from the user's root console and restore SSH command execution. Inspect/unbind any temporary gadget, then validate default MTP/FunctionFS and the host-initiated AOA handshake. The installed kernel is the verified AOA-capable `6.18.58`; proceed with proxy services and real head-unit/phone validation only after USB gadget state is clean.

## Offline SSH recovery (2026-10-25)

- After another board reboot, `192.168.15.73` still answered ping but actively refused TCP/22. A scan of the local `/24` found no SSH endpoint matching the Orange Pi; other SSH hosts were unrelated.
- The user inserted the microSD into the PC's USB reader. Windows sees a 15.93 GB removable disk with one Linux partition beginning at 4 MiB. WSL cannot attach this USB reader directly, so a temporary sparse image was made by reading the partition; the card itself was not modified during inspection.
- The persistent filesystem journal was pending recovery. `e2fsck -fy` on the temporary image replayed it and repaired the image; a follow-up `e2fsck -fn` passed.
- Inspection found `ssh.service` enabled and `sshd` installed, with `PermitRootLogin yes`, `PubkeyAuthentication yes`, no `sshd_not_to_be_run` marker, and the current PC's root public key present in `/root/.ssh/authorized_keys`.
- The captured current-boot journal shows DHCP obtaining `192.168.15.73`, reaching `sockets.target`, and starting AW859A Wi-Fi/Bluetooth and `wpa_supplicant`; it contains no `ssh.service` start or `multi-user.target` record. This suggests startup is stalling before the normal SSH service starts; the exact blocker is not yet proven.
- Prepared a recovery on the temporary filesystem image: enabled Debian's packaged `ssh.socket` under `sockets.target.wants` and added `/etc/systemd/system/ssh.service.d/early-ssh.conf` to remove the `network.target` ordering dependency. `e2fsck -fn` passed after these changes.
- Compared the repaired image against the physical card and wrote only seven differing 1 MiB chunks (7 MiB total). Each written chunk was read back and verified; the full 15.77 GB partition scan completed. The image is at `F:\opi3-recovery\rootfs.ext4.img` and should be retained until SSH is verified.
- Not yet tested: booting the card after this offline recovery, SSH socket activation, or any Android Auto behavior. The board must have this microSD reinserted and powered before SSH can be tested again.
