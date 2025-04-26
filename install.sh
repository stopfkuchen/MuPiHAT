#!/bin/bash

set -e

# Konfiguration
REPO_URL="https://github.com/stopfkuchen/MuPiHAT.git"
DEFAULT_APP_DIR="/usr/local/bin/mupihat"
SERVICE_NAME="mupi_hat"

function info() {
    echo -e "\033[1;32m$1\033[0m"
}

function warn() {
    echo -e "\033[1;33m$1\033[0m"
}

function error() {
    echo -e "\033[1;31m$1\033[0m"
    exit 1
}

# Prüfungen
if [ "$(id -u)" -ne 0 ]; then
    error "❗ Bitte das Script als root oder mit sudo ausführen!"
fi

if [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
    warn "⚠️ Dieses Skript ist für Raspberry Pi (ARM) optimiert. Weiter geht's trotzdem..."
fi


# User Input: Installationspfad abfragen
echo ""
read -p "📁 Wo soll das MuPiHAT installiert werden? [Standard: $DEFAULT_APP_DIR] " APP_DIR
APP_DIR=${APP_DIR:-$DEFAULT_APP_DIR}

info "➡️  Installation erfolgt nach: $APP_DIR"


info "📦 Aktualisiere Paketliste & installiere Systempakete..."
apt update
apt install -y git python3 python3-pip i2c-tools libgpiod-dev

# Repository klonen
if [ ! -d "$APP_DIR" ]; then
    info "📁 Klone Repository nach $APP_DIR..."
    mkdir -p "$(dirname "$APP_DIR")"
    git clone "$REPO_URL" "$APP_DIR"
else
    info "📁 Repository existiert bereits in $APP_DIR, überspringe Klonen."
fi

cd "$APP_DIR"

# Python-Abhängigkeiten installieren
if [ -f "./src/requirements.txt" ]; then
    info "📦 Installiere Python-Abhängigkeiten..."
    pip3 install --break-system-packages -r ./src/requirements.txt
else
    info "ℹ️ Keine requirements.txt gefunden, überspringe Python-Paketinstallation."
fi

# MuPiHAT aktivieren
info "⚙️ Aktiviere MuPiHAT im System..."
sudo sed -zi '/#--------MuPiHAT--------/!s/$/\n#--------MuPiHAT--------/' /boot/config.txt
sudo sed -zi '/dtparam=i2c_arm=on/!s/$/\ndtparam=i2c_arm=on/' /boot/config.txt
sudo sed -zi '/dtparam=i2c1=on/!s/$/\ndtparam=i2c1=on/' /boot/config.txt
sudo sed -zi '/dtparam=i2c_arm_baudrate=50000/!s/$/\ndtparam=i2c_arm_baudrate=50000/' /boot/config.txt
sudo sed -zi '/dtoverlay=max98357a,sdmode-pin=16/!s/$/\ndtoverlay=max98357a,sdmode-pin=16/' /boot/config.txt
sudo sed -zi '/dtoverlay=i2s-mmap/!s/$/\ndtoverlay=i2s-mmap/' /boot/config.txt
sudo sed -zi '/i2c-dev/!s/$/\ni2c-dev/' /etc/modules
sudo sed -zi '/i2c-bcm2708/!s/$/\ni2c-bcm2708/' /etc/modules
sudo modprobe i2c-dev
sudo modprobe i2c-bcm2708


# Systemd-Service erstellen
info "⚙️ Erstelle Systemd-Service $SERVICE_NAME..."
tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=MuPiHAT Service
Before=basic.target
After=local-fs.target sysinit.target
DefaultDependencies=no

[Service]
Type=simple
WorkingDirectory=/usr/local/bin/mupihat/
User=root
ExecStart=/usr/bin/python3 -B /usr/local/bin/mupihat/mupihat.py -j /tmp/mupihat.json
Restart=on-failure

[Install]
WantedBy=basic.target
EOF

# Systemd neu laden und Service aktivieren
info "🔄 Lade Systemd-Konfiguration neu..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

info "✅ Setup abgeschlossen!"

echo ""
info "📢 WICHTIG: Bitte starte den Raspberry Pi neu, damit I2C und Audio-Overlay aktiv werden:"
echo "    sudo reboot"
echo ""
info "🧪 Nach dem Neustart kannst du mit 'aplay -l' prüfen, ob das MAX98357A-Audiodevice sichtbar ist."
