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
| Bluetooth | **Partial** | HCI `hci0` reports BR/EDR/RFCOMM. `aawg-bluetooth-agent.service` is active and BlueZ timeouts are disabled. Board reports the test S23 bonded/paired and connected over HSP HS (“calls”). The daemon was rebuilt with a fix for its 20-second HSP disconnect/reconnect loop; two retry intervals passed with the link stable. Still pending: Android Auto AA-profile RFCOMM channel 8 discovery/connection, Wi-Fi negotiation and DHCP. BlueZ reports RFCOMM bind `Address already in use` on daemon start; investigate. |
| Wi-Fi AP | **Partial** | The project AP service is active; Windows saw WPA2 SSID `AAWirelessDongle` on 5 GHz channel 36 / 5180 MHz at 92% signal. DHCP service is active for `10.0.0.2`–`10.0.0.20`; no phone lease, sustained throughput, or concurrent phone Bluetooth test yet. |
| FunctionFS / proxy | **Partial** | `umtprd` is active on FunctionFS `/dev/ffs-mtp`; `aawgd` is active, listening on TCP `5288`. No phone connection has reached the proxy. |
| AOA | **Pending** | ConfigFS `accessory.usb0` and `/dev/usb_accessory` exist, but the normal host-initiated AOA start request and transition from default MTP to accessory VID/PID have not been observed. The phone-first daemon leaves the UDC unbound while no phone is paired. |
| Vehicle / endurance | **Pending** | No Peugeot head-unit session, media/microphone/touch validation, reconnection, abrupt-power-cut, heat or endurance test. The short live run with no workqueue lockup does not resolve the historical `android_work [libcomposite]` stall. |

The CDC ACM smoke test is not an AOA test and does not establish USB-C electrical/power behavior or Peugeot compatibility. The PC network configuration was not changed. Next, pair a test Android phone and record Bluetooth/RFCOMM, DHCP lease, AOA transition, and proxy logs before attempting vehicle validation.
