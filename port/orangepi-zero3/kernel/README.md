# Armbian AOA kernel build

The selected Armbian kernel supports a generic USB gadget but does not include the Android Accessory (`f_accessory`) function required by upstream `aawgd`.

This integration reuses the two kernel patches already carried by the main project. It does not implement AOA in userspace. The patch series may need updates if Armbian's Linux 6.18 source has changed.

From the project root, stage the patches into an Armbian build checkout:

```sh
sh port/orangepi-zero3/kernel/prepare-armbian-kernel.sh /path/to/armbian-build
```

Then build only the kernel packages:

```sh
cd /path/to/armbian-build
./compile.sh kernel BOARD=orangepizero3 BRANCH=current RELEASE=trixie
```

The staging script copies Armbian's stock `linux-sunxi64-current.config` to the matching userpatches location and adds `CONFIG_USB_CONFIGFS_UEVENT=y` and `CONFIG_USB_CONFIGFS_F_ACC=y`. It stages AOA patches in `userpatches/kernel/archive/sunxi-6.18/`.

Install the resulting kernel packages only after confirming their versions and keeping a bootable SD backup. Validate USB serial gadget, AOA descriptors, `/dev/usb_accessory`, FunctionFS, Bluetooth, Wi-Fi, and boot recovery before enabling the Android Auto service.
