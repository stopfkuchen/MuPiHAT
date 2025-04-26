#!/bin/bash

set -e  # Beende bei Fehler

# Konfiguration
REPO_URL="https://github.com/stopfkuchen/MuPiHAT.git"
APP_DIR="/opt/mupi_hat"
SERVICE_NAME="mupi_hat.service"

echo "📦 Aktualisiere Paketliste & installiere Pakete..."
sudo apt update
sudo apt install -y git python3 python3-pip i2c-tools libgpiod-dev

echo "📁 Klone Repository nach $APP_DIR..."
sudo git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

echo "📦 Installiere Python-Abhängigkeiten..."
sudo pip3 install -r requirements.txt

echo "⚙️ Aktiviere I2C im System..."
if ! grep -q "^dtparam=i2c_arm=on" /boot/config.txt; then
    echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt
fi
sudo modprobe i2c-dev

echo "📡 Lade I2C-Modul dauerhaft..."
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf


echo "🔊 Aktiviere MAX98357A Audio-Overlay..."
if ! grep -q "^dtoverlay=max98357a,sdmode-pin=16" /boot/config.txt; then
    echo "dtoverlay=max98357a,sdmode-pin=16" | sudo tee -a /boot/config.txt
fi

echo "⚙️ Erstelle Systemd-Service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Python Service ($SERVICE_NAME)
After=network.target

[Service]
ExecStart=/usr/bin/python3 $APP_DIR/main.py
WorkingDirectory=$APP_DIR
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Lade & starte den Service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
sudo systemctl status $SERVICE_NAME --no-pager

echo ""
echo "✅ Setup abgeschlossen!"
echo ""
echo "📢 Bitte starte das System neu, um I2C & MAX98357A zu aktivieren:"
echo "    sudo reboot"
echo ""
echo "🧪 Nach dem Reboot kannst du testen, ob das Audio-Device geladen ist:"
echo "    aplay -l"
echo ""
echo "🔎 Du solltest ein Gerät wie 'XXX' oder ähnliches sehen."
echo "❗ Falls kein Gerät erscheint, prüfe ob 'dtoverlay=max98357a,sdmode-pin=16' korrekt in /boot/config.txt eingetragen wurde:"
echo "    grep dtoverlay /boot/config.txt"