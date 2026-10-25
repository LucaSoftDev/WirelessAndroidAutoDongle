# Wireless Android Auto Dongle

DIY Wireless Android Auto adapter for cars that support wired Android Auto. The upstream project targets Raspberry Pi boards; see the experimental Orange Pi Zero 3 port below.

This repository consists of the buildroot setup to generate an sd card image to create your own Wireless Android Auto adapter.

## Features
- Native Wireless Android Auto connection to the phone, no extra app needed on the phone.
- Passes through all Android Auto traffic without any modifications to ensure seamless and safe experience.
- Fast bootup, connection under 30 seconds.
- Supports multiple boards (the upstream image targets Raspberry Pi; an experimental Armbian port is available for Orange Pi Zero 3).

## Supported Hardware
This is currently tested and built for the following Raspberry Pi boards supporting USB OTG.
- **Raspberry Pi Zero W**
- **Raspberry Pi Zero 2 W**
- **Raspberry Pi 3 A+** _(Raspberry Pi 3 B+ is not supported due to lack of USB OTG support.)_
- **Raspberry Pi 4**

### Orange Pi Zero 3 port (Armbian prototype)

An Armbian port reuses the upstream `aawgd` Bluetooth/Wi-Fi negotiation and USB/TCP forwarder. The tested board is an Orange Pi Zero 3 (Allwinner H618) running Armbian with kernel `6.18.58-current-sunxi64`. Its USB-C port operates as the peripheral connection to the car; the port uses the MUSB UDC and the AW859A/UWE5622 radio.

The port uses `PHONE_FIRST`: it waits for the phone's Bluetooth and Wi-Fi/TCP connection before exposing the USB gadget to the head unit. Its default AP name is `Android_Auto_Peugeot_208`.

**User-reported vehicle results:** on a Peugeot 208 with a Continental head unit, Android Auto connected on the first try across subsequent ignition cycles. Waze, Spotify, and an incoming phone call worked; audio quality was reported as excellent, with one or two very brief music stutters over a drive. The proxy forwards the stream without decoding or transcoding it.

This is a board-specific Armbian port, not an Orange Pi Buildroot image. Follow the [Orange Pi Zero 3 guide](port/orangepi-zero3/README.md), [hardware notes](port/orangepi-zero3/HARDWARE.md), and [test record](port/orangepi-zero3/TESTING.md); do not flash the upstream Raspberry Pi image onto the Orange Pi. Repeated power-cut recovery, heat, and long-duration endurance are still open validation items.

In theory, this can be extended to more hardware in future with these basic requirements.

- The board should support USB OTG or Gadget mode.
- Has Wifi and Bluetooth. External should also work if not in-built.
- Should be able to operate on power provided by the car.

## Install and run
[Download a pre-built sd card image](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/releases) for your board. You can also [build one yourself](BUILDING.md). Install the image on the SD card using your favorite tool.

You may want to update the country code and other settings that works best for you. See [Configurations](#Configurations)

### First-time connection
- Connect the phone to headunit via USB cable, make sure Android Auto starts. Disconnect phone.
- Connect the board to the car. Make sure to use a data cable, with the USB OTG enabled port on the board.
    - On **Raspberry Pi Zero W** and **Raspberry Pi Zero 2 W**: Use the second micro-usb port marked "USB" and not "PWR".
    - On **Raspberry Pi 3 A+**: Use the only USB-A port with an USB-A to USB-A cable.
    - On **Raspberry Pi 4**, use the USB-C port used for normally powering the board.
- Open Bluetooth settings and pair the new device called `AndroidAuto-Dongle-*` or `WirelessAADongle-*` on your phone.
- After this phone should automatically connect via Wifi and the dongle will connect to the headunit via USB and start Android Auto on the car screen.

### Subsequent connections
From the next time, it should automatically connect to the phone and start Android Auto.

Make sure your Bluetooth and Wifi are enabled on the phone.

## Configurations

Once the image is installed on the SD card, you can see the SD card as `WirelessAA` drive.

Edit the `aawgd.conf` file inside the `WirelessAA` drive using a text editor to update the configurations. The file contains the possible configuration options with their explanations.


## Troubleshoot

### Common issues

#### Bluetooth and Wifi seems connected, but the phone stuck at "Looking for Android Auto"
The most common issue behind this is either bad USB cable or use of wrong USB port on the device. Make sure:
1. The cable is good quality data cable and not power-only cable
2. You're using the OTG enabled usb port on the board, and not the power-only port.

#### "Device not responding" error on headunit
Make sure that "Wireless Android Auto" is enabled in your phone's Andriod Auto settings. This option is only available and required on some older phones.

### Getting logs
Once you've already tried multiple times and it still does not work, you can ssh into the device and try to get some logs.

- Set a static password by setting the `AAWG_WIFI_PASSWORD` config, and enable SSH by setting the `AAWG_ENABLE_SSH` config. See [the instructions to update the configurations](#Configurations).
- Connect the device to the headunit, let it boot and try to connect once. Buildroot image logs are not persisted across reboots; the Armbian Orange Pi port keeps its journal on the SD card.
- Connect to the device using the SSID configured in `aawgd.conf` (the Orange Pi port defaults to `Android_Auto_Peugeot_208`; password: as set in the first step).
- SSH into the device (username: root, password: password, see relevant defconfigs e.g. [raspberrypi0w_defconfig](aa_wireless_dongle/configs/raspberrypi0w_defconfig)).
- For the Buildroot image, look at `/var/log/messages`; its logs are not persisted across reboots. The Armbian Orange Pi port stores the system journal on the SD card; reconnect the board to the development LAN, then use `journalctl` over SSH to inspect the car run.

## Contribute
[Find or create a new issue](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/issues) for any bugs or improvements.

Feel free to [Create a PR](https://github.com/nisargjhaveri/WirelessAndroidAutoDongle/pulls) to fix any issues. Refer [BUILDING.md](BUILDING.md) for instructions on how to build locally.

## Support 
Please [consider sponsoring](https://github.com/sponsors/nisargjhaveri) if you find the project useful. Even a small donation helps. This will help continuing fixing issues and getting support for more devices and headunit in future.

In any case, don't forget to star on github and spread the word if you think this project might be useful to someone else as well.

## Limitations
This is currently tested with very limited set of headunits and cars. Let me know if it does not work with your headunit.
