#!/bin/bash

set -e

# Konfiguration
REPO_URL="https://github.com/stopfkuchen/MuPiHAT.git"
DEFAULT_GIT_BRANCH="main"
DEFAULT_APP_DIR="/usr/local/bin/mupihat"
DEFAULT_CONFIG_DIR="/etc/mupihat"

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

function ensure_config_in_file() {
    local entry="$1"
    local file="$2"
    local comment="$3"

    if ! grep -qF "$entry" "$file"; then
        echo "" | sudo tee -a "$file" >/dev/null
        if [ -n "$comment" ]; then
            echo "# $comment" | sudo tee -a "$file" >/dev/null
        fi
        echo "$entry" | sudo tee -a "$file" >/dev/null
        info "✅ Eintrag hinzugefügt in $file: $entry"
    else
        info "ℹ️ Eintrag schon vorhanden in $file: $entry"
    fi
}

function ensure_kernel_modules() {
    local modules=("i2c-dev" "i2c-bcm2708")
    local file="/etc/modules-load.d/mupihat.conf"

    info "🔧 Konfiguriere Kernelmodule für Autostart..."

    sudo bash -c "echo '# MuPiHAT benötigte Kernelmodule' > $file"
    for module in "${modules[@]}"; do
        echo "$module" | sudo tee -a "$file" >/dev/null
    done

    info "✅ Kernelmodule für Autostart eingetragen: ${modules[*]}"

    # Jetzt sofort laden:
    for module in "${modules[@]}"; do
        if ! lsmod | grep -q "^${module}"; then
            info "📦 Lade Kernelmodul $module..."
            sudo modprobe "$module"
        else
            info "ℹ️ Kernelmodul $module ist bereits geladen."
        fi
    done
}

# Prüfungen
if [ "$(id -u)" -ne 0 ]; then
    error "❗ Bitte das Script als root oder mit sudo ausführen!"
fi

if [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
    warn "⚠️ Dieses Skript ist für Raspberry Pi (ARM) optimiert. Weiter geht's trotzdem..."
fi

if grep -q "Raspberry Pi 5" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 5 erkannt!"
elif grep -q "Raspberry Pi 4" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 4 erkannt!"
elif grep -q "Raspberry Pi 3" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 3 erkannt!"
else
    warn "⚠️  Dieses Skript unterstützt offiziell nur Raspberry Pi 3, 4 oder 5."
fi

# User Input: Installationspfad abfragen
echo ""
echo "📁 Wo soll das MuPiHAT installiert werden? [Standard: $DEFAULT_APP_DIR] "
read -r -e -i "$DEFAULT_APP_DIR" APP_DIR < /dev/tty
APP_DIR=${APP_DIR:-$DEFAULT_APP_DIR}

echo ""
echo "📁 Wo soll die MuPiHAT Configuration gespeichtert werden? [Standard: $DEFAULT_CONFIG_DIR] "
read -r -e -i "$DEFAULT_CONFIG_DIR" CONFIG_DIR < /dev/tty
CONFIG_DIR=${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}
CONFIG_FILE="$APP_DIR/src/templates/mupihatconfig.json"

info "➡️  Installation erfolgt nach: $APP_DIR"
info "➡️  Config liegt in: $CONFIG_DIR"

echo "📁 Welche Git-Branch soll verwendet werden? [Standard: $DEFAULT_GIT_BRANCH] "
read -r -e -i "$DEFAULT_GIT_BRANCH" GIT_BRANCH < /dev/tty
GIT_BRANCH=${GIT_BRANCH:-$DEFAULT_GIT_BRANCH}


info "📦 Aktualisiere Paketliste & installiere Systempakete..."
apt update
apt install -y git python3 python3-pip python3-smbus python3-rpi.gpio i2c-tools libgpiod-dev


# Repository klonen
if [ ! -d "$APP_DIR" ]; then
    echo "📥 Klone Repo Branch $GIT_BRANCH nach $APP_DIR ..."
    mkdir -p "$(dirname "$APP_DIR")"
    git clone --branch "$GIT_BRANCH" --single-branch "$REPO_URL" "$APP_DIR"
else
    echo "📁 Projektverzeichnis existiert bereits. Aktualisiere Branch $GIT_BRANCH ..."
    git -C "$APP_DIR" fetch
    git -C "$APP_DIR" checkout "$GIT_BRANCH"
    git -C "$APP_DIR" pull
fi

cd "$APP_DIR"

## Python-Abhängigkeiten installieren
#if [ -f "./src/requirements.txt" ]; then
#    info "📦 Installiere Python-Abhängigkeiten..."
#    pip3 install -r ./src/requirements.txt
#else
#    info "ℹ️ Keine requirements.txt gefunden, überspringe Python-Paketinstallation."
#fi

# Copy configuration file to /etc/mupihat/

info "📄 Kopiere Konfigurationsdatei nach $CONFIG_DIR"

# Ensure the target directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    info "📁 Verzeichnis $CONFIG_DIR erstellt."
fi

# Copy the configuration file
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_DIR/"
    info "✅ Konfigurationsdatei kopiert nach $CONFIG_DIR."
else
    warn "⚠️ Konfigurationsdatei $CONFIG_FILE nicht gefunden. Überspringe Kopiervorgang."
fi

# ...existing code...

# Detect OS and set config.txt path accordingly
if grep -qi dietpi /etc/os-release; then
    info "ℹ️ DietPi erkannt."
    if [ -f "/boot/config.txt" ]; then
        CONFIG_TXT="/boot/config.txt"
    else
        error "❗ Konnte keine config.txt auf DietPi finden!"
    fi
elif grep -qi "raspbian" /etc/os-release || grep -qi "raspberry pi os" /etc/os-release; then
    info "ℹ️ Raspberry Pi OS erkannt."
    if [ -f "/boot/firmware/config.txt" ]; then
        CONFIG_TXT="/boot/firmware/config.txt"
    else
        error "❗ Konnte keine config.txt auf Raspberry Pi OS finden!"
    fi
else
    # Fallback: try common locations
    if [ -f "/boot/config.txt" ]; then
        CONFIG_TXT="/boot/config.txt"
    elif [ -f "/boot/firmware/config.txt" ]; then
        CONFIG_TXT="/boot/firmware/config.txt"
    else
        error "❗ Konnte keine config.txt finden!"
    fi
fi

info "🔧 Aktualisiere $CONFIG_TXT..."
ensure_config_in_file "#--------MuPiHAT--------" "$CONFIG_TXT" "Marker für MuPiHAT Einstellungen"
ensure_config_in_file "dtparam=i2c_arm=on" "$CONFIG_TXT" "I2C ARM aktivieren"
ensure_config_in_file "dtparam=i2c1=on" "$CONFIG_TXT" "I2C1 aktivieren"
ensure_config_in_file "dtparam=i2c_arm_baudrate=50000" "$CONFIG_TXT" "I2C Bus Baudrate auf 50kHz setzen"
ensure_config_in_file "dtoverlay=max98357a,sdmode-pin=16" "$CONFIG_TXT" "Audio Overlay MAX98357A setzen"
ensure_config_in_file "dtoverlay=i2s-mmap" "$CONFIG_TXT" "I2S Memory Map Overlay setzen"

info "🔧 Aktualisiere Kernelmodule..."
ensure_kernel_modules


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
WorkingDirectory=$APP_DIR
User=root
ExecStart=/usr/bin/python3 -B $APP_DIR/src/mupihat.py -j /tmp/mupihat.json -c $CONFIG_DIR/mupihatconfig.json
Restart=on-failure

[Install]
WantedBy=basic.target
EOF

# Systemd neu laden und Service aktivieren
info "🔄 Lade Systemd-Konfiguration neu..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Überprüfe den Status des Services
info "🔍 Überprüfe den Status des Services $SERVICE_NAME..."
if systemctl is-active --quiet $SERVICE_NAME; then
    info "✅ Der Service $SERVICE_NAME läuft erfolgreich."
else
    warn "⚠️ Der Service $SERVICE_NAME konnte nicht gestartet werden. Überprüfe die Logs mit:"
    echo "    journalctl -u $SERVICE_NAME -xe"
fi

info "✅ Setup abgeschlossen!"

echo ""
info "📢 WICHTIG: Bitte starte den Raspberry Pi neu, damit I2C und Audio-Overlay aktiv werden:"
echo "    sudo reboot"
echo ""

echo ""
read -r -e -i "y" -p "🔊 Möchtest du einen Testsound abspielen? (y/n) " REPLY < /dev/tty
echo ""
if [[ $REPLY =~ ^[YyJj]$ ]]; then
    info "📢 Teste Audioausgabe mit stereo-test.wav ..."
    if command -v aplay >/dev/null 2>&1; then
        if [ -f "$APP_DIR/assets/stereo-test.wav" ]; then
            runuser -l "$SUDO_USER" -c "aplay '$APP_DIR/assets/stereo-test.wav'"
            info "✅ Testsound wurde abgespielt."
        else
            warn "⚠️ Testsound-Datei $APP_DIR/assets/stereo-test.wav nicht gefunden."
        fi
    else
        warn "⚠️ 'aplay' ist nicht installiert. Testsound kann nicht abgespielt werden."
    fi
else
    info "⏭️  Testsound wird übersprungen."
fi