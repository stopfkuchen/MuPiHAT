<p align="center">
  <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/MuPiHAT_Logo.png" width="200" alt="MuPiHAT Logo">
</p>

<h1 align="center">MuPiHAT</h1>
<p align="center">
  The All-In-One Raspberry Pi HAT for anyone who wants to create a battery powered audio player.
</p>

<p align="center">
  🌐 Visit <a href="https://mupihat.de">https://mupihat.de</a> for more information.
</p>

---

## 📦 Overview

**MuPiHAT** is the ideal expansion board (HAT) for the Raspberry Pi when you are looking for a Audio Player with battery. 

It is the **All-In-ONE HAT** for building a mobile, battery powered Audio Player! It combines battery management and audio card in a single PCB -  maybe the unique feature of currently shims for the RaspberryPi HATs.

It adds connectors for buttons, LEDs, and optional components such as RFID reader to create a robust and playful audio experience using varios open-source software platforms.


<table>
  <tr>
    <td>
      <a href="https://phoniebox.de/" target="_blank">
        <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/phoniebox.png" width="100" alt="Phoniebox">
      </a>
    </td>
    <td>
      <b>Phoniebox</b><br>
      The open-source jukebox for kids and families.
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://mupibox.de" target="_blank">
        <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/MuPiBox_Header_75h.png" width="200" alt="MuPiBox">
      </a>
    </td>
    <td>
      <b>MuPiBox</b><br>
      The open-source Music-Player with Display for kids and families.
    </td>
  </tr>
  <tr>
    <td>
      <a href="https://volumio.com/" target="_blank">
        <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/volumio-logo.png" width="250" alt="Volumio>"
      </a>
    </td>
    <td>
      <b>Volumio</b><br>
      The Music player made for music lovers by music lovers
    </td>
  </tr>
</table>



<p align="left">
  
</p>



---

## 🔧 Features


- 🎵 2 × 3 W Class-D Audio Amplifier (MAX98357A, Stereo/Mono selectable)  
- 🔋 Fully integrated fast charger for 2-cell Li-Ion batteries (TI BQ25792)  
- 🔌 USB-C Power Delivery compliant (up to 4A for Raspberry Pi)  
- 📴 On/Off Shim function with push-button (clean shutdown + hard-off)  
- ⚡ Uninterrupted Power Supply (UPS) with battery fallback  
- 🔧 I²C & GPIO pin header for extensions/LEDs  

<p align="center">
  <img src="https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/main/assets/MuPiHatv3.2_0019.jpg" width="200" alt="MuPiHAT PCB">
</p>

---

## PCB Versions

- **2.0** – Initial design (deprecated)  
- **3.0** – First release of current generation  
- **3.1** – Improved connectors  
- **3.2** – Current version (Jan 2025)

---

## Hardware Overview

| Connector | Function                 | Type/Notes |
|-----------|--------------------------|------------|
| J1        | Push Button              | Power on/off, shutdown |
| J15       | LED (GPIO13)             | Status LED connector |
| J2        | 5V Output                | For powering display |
| J3        | Charger Status LED (3.2) | External status LED |
| J4        | USB-C Power IN           | 3.6–12 V, typical 5 V |
| J6        | Battery Power            | 2-cell Li-Ion (7.4 V) |
| J7        | Battery Thermal Sensor   | NTC 10K input |
| J8        | Speaker Output           | 4 Ω or 8 Ω speaker |
| J5        | GPIO/I²C                 | 8 GPIO + SDA/SCL |
| J10       | Raspberry Pi Connector   | 40-pin HAT header |

---

## Switch & Jumper Settings

| Switch/Jumper | Function                      | Default |
|---------------|-------------------------------|---------|
| SW1           | Enable LEDs / On-Off Shim     | ON      |
| SW2           | Battery config (enable/disable)| Use Battery |
| SW3           | Stereo/Mono audio config      | Stereo  |
| JP2           | Power supply source select    | Open (when Pi powered externally) |

⚠️ **Important:** If JP2 is closed *and* 5V comes from Raspberry Pi USB, the HAT will be damaged.

---

## 🚀 Installation & Quick Start

1. Attach the HAT to Raspberry Pi (use ≥2 cm standoffs). Check out user manual <a href="https://mupihat.de">https://mupihat.de</a> for more information. 
2. Connect speakers to **J8**.  
3. *Optionally:* Connect pushbutton (J1) & LED (J15).  
4. *Optionally:* Attach Li-Ion battery pack (2-cell, J6).  
5. Connect USB-C PD charger (20 W recommended).  
6. Power on and depending on your software  
  a) MupiBox: enable MuPiHAT service in Admin Menu. [MuPiBox Installation Guide](https://mupibox.de/anleitungen/installationsanleitung/einfache-installation/)  
  b) Volumio: install MuPiHat Plugin (*coming soon*)  
  c) Phonibox [Phoniebox + MuPiHAT setup](https://github.com/DontUPanic/MuPiHAT_on_phoniebox2.7)  
  d) others: using install script

---

## Raspberry Pi Configuration

Edit `/boot/config.txt` (or `/boot/firmware/config.txt` on newer OS):

```ini
dtparam=i2c_arm=on
dtparam=i2c1=on
dtparam=i2c_arm_baudrate=50000
dtoverlay=max98357a,sdmode-pin=16
dtoverlay=i2s-mmap
dtparam=gpio=on

dtoverlay=gpio-poweroff,gpiopin=4,active_low=1
dtoverlay=gpio-shutdown,gpio_pin=17,active_low=1,gpio_pull=up
```

*Note:* If you use the **MuPiBox software**, or **Volumio Plugin** this is done automatically.

---

## Battery & Charger Notes

- Only **2-cell Li-Ion packs (7.4 V nominal)** supported.  
- Use packs with **internal over-discharge protection**.  
- Typical runtimes:  
  - 2S1P (2 × 18650, ~3500 mAh) → ~4 h  
  - 2S2P (4 × 18650, ~7000–10000 mAh) → ~8–12 h  

Charger follows **JEITA safety guidelines**, includes OVP, OCP, thermal shutdown, and safety timer.  

Datasheet: [TI BQ25792](https://www.ti.com/lit/gpn/bq25792)  


## 🚀 Quick Start

### 1. Connect the MuPiHAT
Attach the MuPiHAT to your Raspberry Pi’s GPIO header. Check out user manual <a href="https://mupihat.de">https://mupihat.de</a> for more information.

### Install MuPiHAT and Service

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

---

## 📊 Web-based Monitoring Service

The MuPiHAT includes a built-in Flask-based web server that provides real-time monitoring of the battery management system (BQ25792 charger IC). This monitoring service offers both a web interface and JSON API endpoints.

### Features

- **Real-time Register Monitoring**: View live register values from the BQ25792 charger IC
- **Web Interface**: User-friendly HTML dashboard that auto-refreshes every 5 seconds
- **JSON API**: RESTful API endpoint for programmatic access to register data
- **Continuous Data Logging**: Optional JSON file generation and logging capabilities

### Accessing the Monitoring Service

Once the MuPiHAT service is running, you can access the monitoring interface:

- **Web Interface**: http://your-raspberry-pi-ip:5000
- **JSON API**: http://your-raspberry-pi-ip:5000/api/registers

### Key Monitoring Data

The service provides real-time access to critical battery and charging parameters:

- Battery voltage (VBAT) and current (IBAT)
- Input voltage (VBUS) and current (IBUS) 
- System voltage (VSYS)
- IC temperature and thermal regulation status
- Charge status and voltage limits
- Input current limits

### Usage Examples

**Manual Service Start with Web Interface:**
```bash
python3 /usr/local/bin/mupibox/mupihat.py
```

**Service with JSON Logging:**
```bash
python3 /usr/local/bin/mupibox/mupihat.py -j /tmp/mupihat.json
```

**Service with Debug Logging:**
```bash
python3 /usr/local/bin/mupibox/mupihat.py -l /tmp/mupihat.log
```

### API Integration

The JSON API endpoint returns structured data that can be integrated into monitoring systems:

```bash
curl http://localhost:5000/api/registers
```

Returns register data in JSON format for automated monitoring and alerting systems.

---

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


---

## Change Log

- **2.4 (Jan 2025)** – PCB v3.2, current release  
- 2.3 (Nov 2024) – PCB v3.1  
- 2.2 (Oct 2024) – JP2 caution added  
- 2.1 (Oct 2024) – J2 pin marking erratum  
- 2.0 (Jul 2024) – PCB v3.0  

---

## Links

- 🌐 [MuPiHAT Website](https://mupihat.de)  
- 📦 [MuPiBox Project](https://mupibox.de)  

---

© 2025 MuPiHAT – Version 2.4 (25.01.2025)
