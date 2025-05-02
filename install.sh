#!/bin/bash

set -e

# Konfiguration
REPO_URL="https://github.com/stopfkuchen/MuPiHAT.git"
DEFAULT_GIT_BRANCH="main"
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


# User Input: Installationspfad abfragen
echo ""
echo "📁 Wo soll das MuPiHAT installiert werden? [Standard: $DEFAULT_APP_DIR] "
read -r -e -i "$DEFAULT_APP_DIR" APP_DIR < /dev/tty
APP_DIR=${APP_DIR:-$DEFAULT_APP_DIR}

info "➡️  Installation erfolgt nach: $APP_DIR"

echo "📁 Welche Git-Branch soll verwendet werden? [Standard: $DEFAULT_GIT_BRANCH] "
read -r -e -i "$DEFAULT_GIT_BRANCH" GIT_BRANCH < /dev/tty
GIT_BRANCH=${GIT_BRANCH:-$DEFAULT_GIT_BRANCH}


info "📦 Aktualisiere Paketliste & installiere Systempakete..."
apt update
apt install -y git python3 python3-pip i2c-tools libgpiod-dev


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

# Python-Abhängigkeiten installieren
if [ -f "./src/requirements.txt" ]; then
    info "📦 Installiere Python-Abhängigkeiten..."
    pip3 install --break-system-packages -r ./src/requirements.txt
else
    info "ℹ️ Keine requirements.txt gefunden, überspringe Python-Paketinstallation."
fi

# Copy configuration file to /etc/mupihat/
info "📄 Kopiere Konfigurationsdatei nach /etc/mupihat/..."
CONFIG_DIR="/etc/mupihat"
CONFIG_FILE="$APP_DIR/templates/mupihatconfig.json"

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


info "🔧 Aktualisiere /boot/config.txt..."
ensure_config_in_file "#--------MuPiHAT--------" "/boot/config.txt" "Marker für MuPiHAT Einstellungen"
ensure_config_in_file "dtparam=i2c_arm=on" "/boot/config.txt" "I2C ARM aktivieren"
ensure_config_in_file "dtparam=i2c1=on" "/boot/config.txt" "I2C1 aktivieren"
ensure_config_in_file "dtparam=i2c_arm_baudrate=50000" "/boot/config.txt" "I2C Bus Baudrate auf 50kHz setzen"
ensure_config_in_file "dtoverlay=max98357a,sdmode-pin=16" "/boot/config.txt" "Audio Overlay MAX98357A setzen"
ensure_config_in_file "dtoverlay=i2s-mmap" "/boot/config.txt" "I2S Memory Map Overlay setzen"

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
WorkingDirectory=/usr/local/bin/mupihat/
User=root
ExecStart=/usr/bin/python3 -B /usr/local/bin/mupihat/src/mupihat.py -j /tmp/mupihat.json
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
