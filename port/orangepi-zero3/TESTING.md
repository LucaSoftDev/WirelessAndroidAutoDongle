# Orange Pi Zero 3 validation checklist

Record the exact Armbian image, kernel (`uname -a`), board revision and test date with every hardware run. Do not mark a step passed from static source inspection alone.

1. **Boot/hardware:** run `scripts/opi3-diagnose.sh`; confirm model, kernel, storage, thermal zone, radio interfaces and relevant kernel messages.
2. **Bluetooth Classic:** confirm an HCI controller is powered, discoverable, and supports BR/EDR. Pair a test phone; verify BlueZ D-Bus, SDP and RFCOMM.
3. **Wi-Fi AP:** inspect `iw list`; configure a temporary hostapd AP first on 2.4 GHz, then 5 GHz on a locally permitted channel. Verify DHCP and sustained traffic while Bluetooth is active.
4. **USB simple gadget:** verify configfs and an unbound UDC. Bind a harmless supported gadget (for example `g_serial` or `g_ether`) and confirm host-side enumeration, then unbind it. Do not test with the head unit yet.
5. **AOA gadget:** verify configfs `functions/accessory.*`, USB accessory kernel support and `/dev/usb_accessory`. Follow AOA default to accessory negotiation and confirm both IDs enumerate on a computer.
6. **Proxy:** build/install `aawgd`, enable the Armbian service, inspect journal logs, and validate reconnect after phone Wi-Fi/BT toggles.
7. **Vehicle:** only after bench checks, attach to the Continental head unit. Verify discovery, Android Auto startup, screen/touch, call audio and microphone, repeated reconnect and cold-power boot.
8. **Endurance:** exercise long sessions, heat and abrupt power cuts; inspect filesystem and logs after repeated cycles. Verify media streams remain byte-forwarded without daemon-side conversion.

No physical Orange Pi or Peugeot head unit was available during initial development, so all hardware steps are currently **pending**.
