# Orange Pi Zero 3 validation checklist

Record the exact Armbian image, kernel (`uname -a`), board revision and test date with every hardware run. Do not mark a step passed from static source inspection alone.

1. **Boot/hardware:** run `scripts/opi3-diagnose.sh`; confirm model, kernel, storage, thermal zone, radio interfaces and relevant kernel messages.
2. **Bluetooth Classic:** confirm an HCI controller is powered, discoverable, and supports BR/EDR. Pair a test phone; verify BlueZ D-Bus, SDP and RFCOMM.
3. **Wi-Fi AP:** inspect `iw list`; verify the project WPA2 AP on 5 GHz channel 36 (or another locally permitted channel), obtain a real phone DHCP lease, and measure sustained traffic while Bluetooth is active.
4. **USB simple gadget:** verify configfs and an unbound UDC. Bind a harmless supported gadget (for example `g_serial` or `g_ether`) and confirm host-side enumeration, then unbind it. Do not test with the head unit yet.
5. **AOA gadget:** verify configfs `functions/accessory.*`, USB accessory kernel support and `/dev/usb_accessory`. Follow AOA default to accessory negotiation and confirm both IDs enumerate on a computer.
6. **Proxy:** build/install `aawgd`, enable the Armbian service, inspect journal logs, and validate reconnect after phone Wi-Fi/BT toggles.
7. **Vehicle:** only after bench checks, attach to the Continental head unit. Verify discovery, Android Auto startup, screen/touch, call audio and microphone, repeated reconnect and cold-power boot.
8. **Endurance:** exercise long sessions, heat and abrupt power cuts; inspect filesystem and logs after repeated cycles. Verify media streams remain byte-forwarded without daemon-side conversion.

## Hardware run: 2026-10-25

Board access was restored by editing the SD root filesystem offline, then verified after the user reinserted and powered the card.

| Step | Result | Evidence / remaining work |
|---|---|---|
| Boot / SSH | **Pass** | Orange Pi Zero 3, Armbian ARM64, kernel `6.18.58-current-sunxi64`; SSH socket/service active and root key login succeeded at `192.168.15.73`. Read-only diagnostic script ran; board model, radios, thermal sensors and `musb-hdrc.4.auto` UDC were reported. |
| USB Gadget basic | **Pass** | ConfigFS CDC ACM gadget bound to `musb-hdrc.4.auto`, reached UDC state `configured`, then unbound and removed. UDC returned to `not attached`. Windows enumerated the test device. |
| Bluetooth | **Pass; repeatability reported** | HCI `hci0` supports BR/EDR/RFCOMM. BlueZ's SAP plugin had reserved channel 8; the board now runs BlueZ with `--noplugin=sap`, leaving channel 8 available to the upstream AA profile. The paired S23 has opened both HSP and AA Wireless RFCOMM profiles. The user reports that subsequent car connections start on the first try. |
| Wi-Fi AP | **Pass; reconnects reported** | On the live board, hostapd runs a 5 GHz AP on channel 36 with SSID `Android_Auto_Peugeot_208`. The S23 automatically joined and received DHCP lease `10.0.0.9`; the daemon's Bluetooth negotiation supplied the same SSID. The user reports the car now connects on the first try each time. |
| FunctionFS / proxy | **Pass to TCP; vehicle success reported** | `umtprd` is active on FunctionFS `/dev/ffs-mtp`; `aawgd` listens on TCP `5288`. The S23 reached the TCP proxy after Bluetooth and Wi-Fi setup. With `PHONE_FIRST`, logs show the USB default gadget becomes enabled only after TCP acceptance. The user reports repeated successful car sessions. |
| AOA | **Pass by user report; logs not independently reviewed** | The user reports repeated successful Android Auto sessions through the Peugeot head unit after the latest changes. The journal was cleared before those trials; inspect the fresh journal after the board is back on the PC network. |
| Vehicle / endurance | **Repeated projection reported; endurance pending** | The user says each subsequent connect/ignition cycle now works on the first try and that Android Auto is perfect. Waze, Spotify and excellent audio quality were reported. Touch, microphone, abrupt-power-cut, heat and endurance remain unconfirmed. The historical `android_work [libcomposite]` lockup still needs long-duration AOA monitoring. |

The CDC ACM smoke test is not an AOA test and does not establish USB-C electrical/power behavior or Peugeot compatibility. The PC network configuration was not changed. The user reports that the latest configuration now starts Android Auto on the first try across repeated connect/ignition cycles. Ethernet does not reach the garage, so the board cannot be observed over SSH during the vehicle run. Armbian's journal is stored persistently on the SD card; after returning the board to the PC network, the fresh car-run logs can be collected over SSH. Touch, microphone, long-duration lockup, abrupt power cut, heat and endurance remain to be validated.
