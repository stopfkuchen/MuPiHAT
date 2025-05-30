<p align="center">
  <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/MuPiHAT_Logo.png" width="200" alt="MuPiHAT Logo">
</p>

<h1 align="center">MuPiHAT</h1>
<p align="center">
  A Raspberry Pi HAT for the <a href="https://mupibox.de">MuPiBox</a> – a fun, child-friendly music player system.
</p>

<p align="center">
  🌐 Visit <a href="https://mupihat.de">https://mupihat.de</a> for more information.
</p>

---

## 📦 Overview

**MuPiHAT** is a custom-designed expansion board (HAT) for the Raspberry Pi. It adds buttons, LEDs, and optional components to create a robust and playful audio experience using the [MuPiBox](https://mupibox.de) platform.

---

## 🔧 Features

- Compatible with Raspberry Pi 3 and 4
- GPIO-based interface for:
  - Playback buttons (Play, Pause, Next, Previous)
  - Status LEDs
- Optional components:
  - Power button
  - RFID reader (e.g., MFRC522)

---

## 🚀 Quick Start

### 1. Connect the MuPiHAT
Attach the MuPiHAT to your Raspberry Pi’s GPIO header. Check out user manual <a href="https://mupihat.de">https://mupihat.de</a> for more information.

### 2. Install Required Software

#### Option 1
Use the provided `install.sh` script to set up the required software:

```bash
git clone https://github.com/stopfkuchen/MuPiHAT.git
cd MuPiHAT
chmod +x install.sh
./install.sh
```

#### Option 2 
Use single line command:

```bash
cd; curl -sSL https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/refs/heads/main/install.sh -o install.sh; sudo bash install.sh
```

### 3. Useful debugging checks

```bash
sudo systemctl status mupi_hat
```

### 4. Raspberry PI 5
Damit dein Raspberry Pi 5 automatisch bootet, sobald über den GPIO 5V Strom anliegt (ohne dass du den Power-Button drücken musst), musst du das Verhalten der Power-Management-Einheit (PMIC) ändern. Der Raspberry Pi 5 ist der erste Pi mit einer eigenen Power-Taste und entsprechend auch mit einem anderen Power-Up-Verhalten als frühere Modelle.

```bash
lars@raspi5:~ $ sudo rpi-eeprom-config --out current-config.txt
lars@raspi5:~ $ sudo nano current-config.txt
```

Folgende Zeile finden und anpassen (oder ergänzen):
```bash
POWER_ON = 1
```
Neue Konfiguration flashen:
```bash
lars@raspi5:~ $ sudo rpi-eeprom-config --apply current-config.txt
Updating bootloader EEPROM
 image: /usr/lib/firmware/raspberrypi/bootloader-2712/default/pieeprom-2025-03-10.bin
config_src: current-config.txt
config: current-config.txt
################################################################################
[all]
BOOT_UART=1
POWER_ON=1
POWER_OFF_ON_HALT=0
BOOT_ORDER=0xf461

################################################################################
*** CREATED UPDATE /tmp/tmpjlt35f4u/pieeprom.upd  ***

   CURRENT: Mon 10 Mar 17:10:37 UTC 2025 (1741626637)
    UPDATE: Mon 10 Mar 17:10:37 UTC 2025 (1741626637)
    BOOTFS: /boot/firmware
'/tmp/tmp.11Ssvn3xkD' -> '/boot/firmware/pieeprom.upd'

UPDATING bootloader. This could take up to a minute. Please wait

*** Do not disconnect the power until the update is complete ***

If a problem occurs then the Raspberry Pi Imager may be used to create
a bootloader rescue SD card image which restores the default bootloader image.

flashrom -p linux_spi:dev=/dev/spidev10.0,spispeed=16000 -w /boot/firmware/pieeprom.upd
Verifying update
VERIFY: SUCCESS
UPDATE SUCCESSFUL
```