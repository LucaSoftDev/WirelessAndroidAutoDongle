# Hardware investigation: Orange Pi Zero 3

## USB-C / USB0 OTG

The USB-C power/data connector is the candidate USB0 dual-role path on the Zero 3. The USB-A host connectors are not gadget ports. The exact USB-C signal routing, role selection and power behavior still require board-revision schematic confirmation and bench verification. Linux may expose a controller without binding it in peripheral mode. Check the live device tree, UDC list, UDC state, configfs, and host-side enumeration; presence of a UDC alone is not proof that accessory mode works.

The upstream daemon expects the Android kernel `CONFIG_USB_CONFIGFS_F_ACC` function and `/dev/usb_accessory`. It does not implement AOA itself. Its two configfs gadgets use IDs `18d1:4ee1` and `18d1:2d00`, and switch on the AOA `ACCESSORY=START` uevent. On Armbian, test that the exact kernel provides this configfs function (built-in or loadable), then perform the simple USB gadget test before attempting `aawgd`. The helper must not create a fake success if the function/UDC is missing. The initial `raspberrypi5_defconfig` cross build is only a compilation check; its userspace kernel/device config and runtime libraries are unrelated to Orange Pi.

Power over the same USB-C receptacle used as peripheral is a hardware power-path question. The head unit generally supplies VBUS as host, but that does not prove the board accepts it in this role or that the car's current budget covers boot and radio peaks. Check for backfeed with an isolated bench arrangement and measure the rail/temperature in the intended vehicle.

## AW859A / UWE5622 Bluetooth

Armbian support depends on kernel branch, firmware and board setup. Check `dmesg`, `rfkill`, `hciconfig`/`btmgmt`, and `bluetoothctl show`. For Classic AA, HCI must support BR/EDR, RFCOMM and SDP, not only BLE. The daemon uses BlueZ D-Bus `ProfileManager1` to register its AA and HSP profiles; it does not use a separate RFCOMM daemon directly. `sprdbt_tty` and vendor `hciattach_opi` are image-specific pieces sometimes required to bring up the UART Bluetooth function. Do not run them blindly: check whether the image already attaches HCI, then inspect `dmesg`, modules, device tree and vendor scripts for duplicate initialization.

## AW859A / UWE5622 Wi-Fi

The upstream configuration uses `wlan0`, hostapd, WPA2-PSK and channel 6 (2.4 GHz); `aawgd` advertises the interface BSSID and default address `10.0.0.1:5288`. It does not itself configure hostapd/DHCP. Do not assume AP, 5 GHz, or AP+Bluetooth coexistence from client-mode support. Verify `iw list` AP interface combinations and supported bands/channels, then run a sustained 5 GHz AP test while Bluetooth BR/EDR is active and inspect throughput, retries, disconnects, temperature and kernel logs. Keep the regulatory country/channel legal for the installation location.

## Sources consulted

- Orange Pi build system lists Zero 3 in its supported board family: <https://github.com/orangepi-xunlong/orangepi-build>
- Linux-sunxi Zero 3 notes its H618 device tree and USB-C USB-OTG/FEL path: <https://linux-sunxi.org/Xunlong_Orange_Pi_Zero3>
- aa-proxy-rs lists Zero 2W and other tested boards, but not Zero 3; this does not establish Zero 3 compatibility: <https://github.com/aa-proxy/aa-proxy-rs>
- The WirelessAndroidAutoDongle kernel overlay enables configfs `f_accessory`; its daemon directly uses `/sys/class/udc`, configfs and `/dev/usb_accessory` (source in this checkout).

These references are investigation leads, not a substitute for board-level verification.
