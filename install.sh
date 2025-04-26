#!/bin/bash

set -e

# Konfiguration
REPO_URL="https://github.com/stopfkuchen/MuPiHAT.git"
APP_DIR="/usr/local/bin/mupibox"
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

# Betriebssystem-Erkennung
if [ -f /etc/os-release ]; then
    OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
    error "❗ /etc/os-release nicht gefunden. Kann Betriebssystem nicht erkennen."
fi

case "$OS_ID" in
    dietpi)
        info "✅ DietPi erkannt."
        ;;
    raspbian)
        info "✅ Raspberry Pi OS (Raspbian) erkannt."
        ;;
    *)
        error "❗ Unbekanntes System ($OS_ID). Installation abgebrochen!"
        ;;
esac

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
if [ -f "requirements.txt" ]; then
    info "📦 Installiere Python-Abhängigkeiten..."
    pip3 install --break-system-packages -r requirements.txt
else
    info "ℹ️ Keine requirements.txt gefunden, überspringe Python-Paketinstallation."
fi

# I2C aktivieren
info "⚙️ Aktiviere I2C im System..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" | tee -a /boot/config.txt
fi
modprobe i2c-dev
echo "i2c-dev" | tee /etc/modules-load.d/i2c.conf

# MAX98357A Audio-Overlay aktivieren
info "🔊 Aktiviere MAX98357A Audio-Overlay..."
if ! grep -q "^dtoverlay=max98357a,sdmode-pin=16" /boot/config.txt; then
    echo "dtoverlay=max98357a,sdmode-pin=16" | tee -a /boot/config.txt
fi

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
WorkingDirectory=/usr/local/bin/mupibox/
User=root
ExecStart=/usr/bin/python3 -B /usr/local/bin/mupibox/mupihat.py -j /tmp/mupihat.json
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
