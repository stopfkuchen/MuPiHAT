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

#### Option 2 
curl -sSL https://raw.githubusercontent.com/stopfkuchen/MuPiHAT/refs/heads/main/install.sh | sudo bash
