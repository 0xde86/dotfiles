# My Linux setup :rocket:

Installation script is expected to be executed on CachyOS with Cosmic DE installed. Probably works on other flavors of Arch.

note: during installation of cachyos uncheck insallation of fish shell

## Install

```bash
git clone git@github.com:x-dvr/dotfiles.git
cd dotfiles
bash ./install.sh
```

## Generate SSH Keys

Generate Key:
```bash
ssh-keygen -t ed25519 -C "denis.rodin@proton.me"
```
Start SSH Agent & add key:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github
```

## Generate GPG key & Setup GIT to sign commits

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
gpg --armor --export <KEY_ID>

git config --global commit.gpgsign true
git config --global user.signingkey <KEY_ID>
```

## Secure DNS

Update `/etc/dnscrypt-proxy/dnscrypt-proxy.toml`:
```
server_names = ['cloudflare']
```

ensure resolv.conf can be edited without it being overwritten. This can vary depending on your networking software, but for NetworkManager (default in most common Desktop Environments) it is as simple as adding the following to `/etc/NetworkManager/conf.d/dns.conf`:
```
[main]
dns=none
```

Afterwards, edit `/etc/resolv.conf` to include the following:
```
nameserver ::1
nameserver 127.0.0.1
options edns0
```
And after a reboot it should be working perfectly. Test your connection with 1.1.1.1/help (easy to remember) or dnsleaktest.com (thorough)

## Download android SDK

Download from: https://developer.android.com/studio#command-line-tools-only
```bash
mkdir -p ~/Android/Sdk/cmdline-tools
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
sdkmanager "platforms;android-36" "build-tools;36.0.0" "build-tools;28.0.3"
sdkmanager --install "system-images;android-33;google_apis;x86_64"
avdmanager create avd -n Pixel_6 -k "system-images;android-33;google_apis;x86_64"
flutter doctor -v
```

## Raspberry Pi dev

1. Install "Raspberry Pi Pico" extention for VSCode
2. ```sudo pacman -S minicom```
3. create `/etc/udev/rules.d/60-openocd.rules`
```
# SPDX-License-Identifier: GPL-2.0-or-later

# Copy this file to /etc/udev/rules.d/
# If rules fail to reload automatically, you can refresh udev rules
# with the command "udevadm control --reload"

ACTION!="add|change", GOTO="openocd_rules_end"

SUBSYSTEM=="gpio", MODE="0660", TAG+="uaccess"

SUBSYSTEM!="usb|tty|hidraw", GOTO="openocd_rules_end"

# Please keep this list sorted by VID:PID

# opendous and estick
ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="204f", MODE="666", TAG+="uaccess"

# Original FT232/FT245 VID:PID
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="666", TAG+="uaccess"

# Original FT2232 VID:PID
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="666", TAG+="uaccess"

# Original FT4232 VID:PID
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="666", TAG+="uaccess"

# Original FT232H VID:PID
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="666", TAG+="uaccess"
# Original FT231XQ VID:PID
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="666", TAG+="uaccess"

# DISTORTEC JTAG-lock-pick Tiny 2
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8220", MODE="666", TAG+="uaccess"

# TUMPA, TUMPA Lite
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8a98", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="8a99", MODE="666", TAG+="uaccess"

# Marvell OpenRD JTAGKey FT2232D B
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="9e90", MODE="666", TAG+="uaccess"

# XDS100v2
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a6d0", MODE="666", TAG+="uaccess"
# XDS100v3
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="a6d1", MODE="666", TAG+="uaccess"

# OOCDLink
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="baf8", MODE="666", TAG+="uaccess"

# Kristech KT-Link
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bbe2", MODE="666", TAG+="uaccess"

# Xverve Signalyzer Tool (DT-USB-ST), Signalyzer LITE (DT-USB-SLITE)
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bca0", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bca1", MODE="666", TAG+="uaccess"

# TI/Luminary Stellaris Evaluation Board FTDI (several)
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bcd9", MODE="666", TAG+="uaccess"

# TI/Luminary Stellaris In-Circuit Debug Interface FTDI (ICDI) Board
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bcda", MODE="666", TAG+="uaccess"

# egnite Turtelizer 2
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="bdc8", MODE="666", TAG+="uaccess"

# Section5 ICEbear
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="c140", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="c141", MODE="666", TAG+="uaccess"

# Amontec JTAGkey and JTAGkey-tiny
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="cff8", MODE="666", TAG+="uaccess"

# ASIX Presto programmer
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="f1a0", MODE="666", TAG+="uaccess"

# Nuvoton NuLink
ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511b", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511c", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0416", ATTRS{idProduct}=="511d", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5200", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5201", MODE="666", TAG+="uaccess"

# TI ICDI
ATTRS{idVendor}=="0451", ATTRS{idProduct}=="c32a", MODE="666", TAG+="uaccess"

# STMicroelectronics ST-LINK V1
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3744", MODE="666", TAG+="uaccess"

# STMicroelectronics ST-LINK/V2
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="666", TAG+="uaccess"

# STMicroelectronics ST-LINK/V2.1
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="666", TAG+="uaccess"

# STMicroelectronics STLINK-V3
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374d", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374e", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374f", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3753", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3755", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3757", MODE="666", TAG+="uaccess"

# Cypress SuperSpeed Explorer Kit
ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="0007", MODE="666", TAG+="uaccess"

# Cypress KitProg in KitProg mode
ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="f139", MODE="666", TAG+="uaccess"

# Cypress KitProg in CMSIS-DAP mode
ATTRS{idVendor}=="04b4", ATTRS{idProduct}=="f138", MODE="666", TAG+="uaccess"

# Infineon DAP miniWiggler v3
ATTRS{idVendor}=="058b", ATTRS{idProduct}=="0043", MODE="666", TAG+="uaccess"

# Hitex LPC1768-Stick
ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0026", MODE="666", TAG+="uaccess"

# Hilscher NXHX Boards
ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0028", MODE="666", TAG+="uaccess"

# Hitex STR9-comStick
ATTRS{idVendor}=="0640", ATTRS{idProduct}=="002c", MODE="666", TAG+="uaccess"

# Hitex STM32-PerformanceStick
ATTRS{idVendor}=="0640", ATTRS{idProduct}=="002d", MODE="666", TAG+="uaccess"

# Hitex Cortino
ATTRS{idVendor}=="0640", ATTRS{idProduct}=="0032", MODE="666", TAG+="uaccess"

# Altera USB Blaster
ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="666", TAG+="uaccess"
# Altera USB Blaster2
ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="666", TAG+="uaccess"

# Ashling Opella-LD
ATTRS{idVendor}=="0B6B", ATTRS{idProduct}=="0040", MODE="666", TAG+="uaccess"

# Amontec JTAGkey-HiSpeed
ATTRS{idVendor}=="0fbb", ATTRS{idProduct}=="1000", MODE="666", TAG+="uaccess"

# SEGGER J-Link
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0101", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0102", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0103", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0104", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0105", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0107", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0108", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1010", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1011", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1012", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1013", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1014", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1015", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1016", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1017", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1018", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1020", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1051", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1055", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1366", ATTRS{idProduct}=="1061", MODE="666", TAG+="uaccess"

# Raisonance RLink
ATTRS{idVendor}=="138e", ATTRS{idProduct}=="9000", MODE="666", TAG+="uaccess"

# Debug Board for Neo1973
ATTRS{idVendor}=="1457", ATTRS{idProduct}=="5118", MODE="666", TAG+="uaccess"

# OSBDM
ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0042", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="0058", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="15a2", ATTRS{idProduct}=="005e", MODE="666", TAG+="uaccess"

# Olimex ARM-USB-OCD
ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="0003", MODE="666", TAG+="uaccess"

# Olimex ARM-USB-OCD-TINY
ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="0004", MODE="666", TAG+="uaccess"

# Olimex ARM-JTAG-EW
ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="001e", MODE="666", TAG+="uaccess"

# Olimex ARM-USB-OCD-TINY-H
ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002a", MODE="666", TAG+="uaccess"

# Olimex ARM-USB-OCD-H
ATTRS{idVendor}=="15ba", ATTRS{idProduct}=="002b", MODE="666", TAG+="uaccess"

# ixo-usb-jtag - Emulation of a Altera Bus Blaster I on a Cypress FX2 IC
ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="06ad", MODE="666", TAG+="uaccess"

# USBprog with OpenOCD firmware
ATTRS{idVendor}=="1781", ATTRS{idProduct}=="0c63", MODE="666", TAG+="uaccess"

# TI/Luminary Stellaris In-Circuit Debug Interface (ICDI) Board
ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="00fd", MODE="666", TAG+="uaccess"

# TI XDS110 Debug Probe (Launchpads and Standalone)
ATTRS{idVendor}=="0451", ATTRS{idProduct}=="bef3", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="0451", ATTRS{idProduct}=="bef4", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="02a5", MODE="666", TAG+="uaccess"

# TI Tiva-based ICDI and XDS110 probes in DFU mode
ATTRS{idVendor}=="1cbe", ATTRS{idProduct}=="00ff", MODE="666", TAG+="uaccess"

# isodebug v1
ATTRS{idVendor}=="22b7", ATTRS{idProduct}=="150d", MODE="666", TAG+="uaccess"

# PLS USB/JTAG Adapter for SPC5xxx
ATTRS{idVendor}=="263d", ATTRS{idProduct}=="4001", MODE="666", TAG+="uaccess"

# Numato Mimas A7 - Artix 7 FPGA Board
ATTRS{idVendor}=="2a19", ATTRS{idProduct}=="1009", MODE="666", TAG+="uaccess"

# Ambiq Micro EVK and Debug boards.
ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="6010", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="6011", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="2aec", ATTRS{idProduct}=="1106", MODE="666", TAG+="uaccess"

# Espressif USB JTAG/serial debug units
ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1002", MODE="666", TAG+="uaccess"

# ANGIE USB-JTAG Adapter
ATTRS{idVendor}=="584e", ATTRS{idProduct}=="414f", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="584e", ATTRS{idProduct}=="424e", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4255", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4355", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="584e", ATTRS{idProduct}=="4a55", MODE="666", TAG+="uaccess"

# Marvell Sheevaplug
ATTRS{idVendor}=="9e88", ATTRS{idProduct}=="9e8f", MODE="666", TAG+="uaccess"

# Keil Software, Inc. ULink
ATTRS{idVendor}=="c251", ATTRS{idProduct}=="2710", MODE="666", TAG+="uaccess"
ATTRS{idVendor}=="c251", ATTRS{idProduct}=="2750", MODE="666", TAG+="uaccess"

# CMSIS-DAP compatible adapters
ATTRS{product}=="*CMSIS-DAP*", MODE="666", TAG+="uaccess"

LABEL="openocd_rules_end"
```
5. create `/etc/udev/rules.d/60-picotool.rules`:
```
# Copy this file to /etc/udev/rules.d/
# You can reload the udev rules with "udevadm control --reload"

SUBSYSTEM=="usb", \
    ATTRS{idVendor}=="2e8a", \
    ATTRS{idProduct}=="0003", \
    TAG+="uaccess", \
    MODE="660"
SUBSYSTEM=="usb", \
    ATTRS{idVendor}=="2e8a", \
    ATTRS{idProduct}=="0009", \
    TAG+="uaccess", \
    MODE="660"
SUBSYSTEM=="usb", \
    ATTRS{idVendor}=="2e8a", \
    ATTRS{idProduct}=="000a", \
    TAG+="uaccess", \
    MODE="660"
SUBSYSTEM=="usb", \
    ATTRS{idVendor}=="2e8a", \
    ATTRS{idProduct}=="000f", \
    TAG+="uaccess", \
    MODE="660"
```
6. reload rules: `sudo udevadm control --reload-rules && sudo udevadm trigger`
7. run: `sudo usermod -aG uucp $USER`