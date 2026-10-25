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
| Bluetooth | **Pass once; repeatability pending** | HCI `hci0` supports BR/EDR/RFCOMM. BlueZ's SAP plugin had reserved channel 8; the board now runs BlueZ with `--noplugin=sap`, leaving channel 8 available to the upstream AA profile. The paired S23 has opened both HSP and AA Wireless RFCOMM profiles, including during the latest live check. |
| Wi-Fi AP | **Pass; reliability pending** | On the live board, hostapd runs a 5 GHz AP on channel 36 with SSID `Android_Auto_Peugeot_208`. The S23 automatically joined and received DHCP lease `10.0.0.9`; the daemon's Bluetooth negotiation supplied the same SSID. A complete in-car projection was also reported once. Repeated reconnects and sustained throughput remain to be verified. |
| FunctionFS / proxy | **Pass to TCP; repeatability pending** | `umtprd` is active on FunctionFS `/dev/ffs-mtp`; `aawgd` listens on TCP `5288`. The S23 reached the TCP proxy after Bluetooth and Wi-Fi setup. With `PHONE_FIRST`, logs show the USB default gadget becomes enabled only after TCP acceptance. AOA request and end-to-end recovery need another captured car run. |
| AOA | **Pass once reported; repeatability pending** | The user reports a complete Android Auto session through the Peugeot head unit. AOA start instrumentation was not captured in the retained journal; verify in a repeated run. |
| Vehicle / endurance | **Pass once for projection, video and audio; reliability pending** | The user opened Waze and Spotify and reports perfect audio quality in one complete session. Head-unit reconnect prompts occurred on later attempts. Touch, microphone, repeated reconnect, abrupt-power-cut, heat and endurance remain untested. The short run does not resolve the historical `android_work [libcomposite]` stall. |

The CDC ACM smoke test is not an AOA test and does not establish USB-C electrical/power behavior or Peugeot compatibility. The PC network configuration was not changed. The live bench observation validates phone discovery through TCP and delayed USB exposure, but it does not prove vehicle-side AOA or resolve the intermittent reconnect issue. Ethernet does not reach the garage, so the board cannot be observed over SSH during the vehicle run. Armbian's journal is stored persistently on the SD card; after returning the board to the PC network, collect the preceding boot's Bluetooth/RFCOMM, DHCP, AOA, proxy, and kernel logs over SSH. Test one cold start and repeated reconnects in the Peugeot.
