#!/bin/bash

set -e

# Configuration
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
        info "✅ Entry added to $file: $entry"
    else
        info "ℹ️ Entry already exists in $file: $entry"
    fi
}

function ensure_kernel_modules() {
    local modules=("i2c-dev" "i2c-bcm2708")
    local file="/etc/modules-load.d/mupihat.conf"

    info "🔧 Configuring kernel modules for autostart..."

    sudo bash -c "echo '# MuPiHAT required kernel modules' > $file"
    for module in "${modules[@]}"; do
        echo "$module" | sudo tee -a "$file" >/dev/null
    done

    info "✅ Kernel modules configured for autostart: ${modules[*]}"

    # Load immediately:
    for module in "${modules[@]}"; do
        if ! lsmod | grep -q "^${module}"; then
            info "📦 Loading kernel module $module..."
            sudo modprobe "$module"
        else
            info "ℹ️ Kernel module $module is already loaded."
        fi
    done
}

# Checks
if [ "$(id -u)" -ne 0 ]; then
    error "❗ Please run this script as root or with sudo!"
fi

if [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
    warn "⚠️ This script is optimized for Raspberry Pi (ARM). Continuing anyway..."
fi

if grep -q "Raspberry Pi 5" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 5 detected!"
elif grep -q "Raspberry Pi 4" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 4 detected!"
elif grep -q "Raspberry Pi 3" /proc/device-tree/model 2>/dev/null; then
    info "✅ Raspberry Pi 3 detected!"
else
    warn "⚠️  This script officially supports only Raspberry Pi 3, 4, or 5."
fi

# User Input: Query installation path
echo ""
echo "📁 Where should MuPiHAT be installed? [Default: $DEFAULT_APP_DIR] "
read -r -e -i "$DEFAULT_APP_DIR" APP_DIR < /dev/tty
APP_DIR=${APP_DIR:-$DEFAULT_APP_DIR}

echo ""
echo "📁 Where should the MuPiHAT configuration be saved? [Default: $DEFAULT_CONFIG_DIR] "
read -r -e -i "$DEFAULT_CONFIG_DIR" CONFIG_DIR < /dev/tty
CONFIG_DIR=${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}
CONFIG_FILE="$APP_DIR/src/templates/mupihatconfig.json"

info "➡️  Installation will be performed to: $APP_DIR"
info "➡️  Config will be located in: $CONFIG_DIR"

echo "📁 Which Git branch should be used? [Default: $DEFAULT_GIT_BRANCH] "
read -r -e -i "$DEFAULT_GIT_BRANCH" GIT_BRANCH < /dev/tty
GIT_BRANCH=${GIT_BRANCH:-$DEFAULT_GIT_BRANCH}


info "📦 Updating package list & installing system packages..."
apt update
apt install -y git python3 python3-smbus python3-rpi.gpio i2c-tools libgpiod-dev curl

# Install uv - fast Python package manager
info "📦 Installing uv (fast Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"


# Clone repository
if [ ! -d "$APP_DIR" ]; then
    echo "📥 Cloning repo branch $GIT_BRANCH to $APP_DIR ..."
    mkdir -p "$(dirname "$APP_DIR")"
    git clone --branch "$GIT_BRANCH" --single-branch "$REPO_URL" "$APP_DIR"
else
    echo "📁 Project directory already exists. Updating branch $GIT_BRANCH ..."
    git -C "$APP_DIR" fetch
    git -C "$APP_DIR" checkout "$GIT_BRANCH"
    git -C "$APP_DIR" pull
fi

cd "$APP_DIR"

# Install Python dependencies
if [ -f "./src/requirements.txt" ]; then
    info "📦 Installing Python dependencies with uv..."
    # Ensure uv is available in the current shell
    export PATH="$HOME/.cargo/bin:$PATH"
    # Install dependencies using uv (faster and more reliable than pip)
    sudo -u "$SUDO_USER" bash -c "export PATH=\"$HOME/.cargo/bin:\$PATH\"; uv pip install --system -r ./src/requirements.txt"
else
    info "ℹ️ No requirements.txt found, skipping Python package installation."
fi

# Copy configuration file to /etc/mupihat/

info "📄 Copying configuration file to $CONFIG_DIR"

# Ensure the target directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    info "📁 Directory $CONFIG_DIR created."
fi

# Copy the configuration file
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_DIR/"
    info "✅ Configuration file copied to $CONFIG_DIR."
else
    warn "⚠️ Configuration file $CONFIG_FILE not found. Skipping copy operation."
fi

# ...existing code...

# Detect OS and set config.txt path accordingly
if grep -qi dietpi /etc/os-release; then
    info "ℹ️ DietPi detected."
    if [ -f "/boot/config.txt" ]; then
        CONFIG_TXT="/boot/config.txt"
    elif [ -f "/boot/firmware/config.txt" ]; then
        CONFIG_TXT="/boot/firmware/config.txt"
    else
        error "❗ Could not find config.txt on DietPi!"
    fi
elif grep -qi "raspbian" /etc/os-release || grep -qi "raspberry pi os" /etc/os-release; then
    info "ℹ️ Raspberry Pi OS detected."
    if [ -f "/boot/firmware/config.txt" ]; then
        CONFIG_TXT="/boot/firmware/config.txt"
    elif [ -f "/boot/config.txt" ]; then
        CONFIG_TXT="/boot/config.txt"
    else
        error "❗ Could not find config.txt on Raspberry Pi OS!"
    fi
else
    # Fallback: try common locations
    if [ -f "/boot/config.txt" ]; then
        CONFIG_TXT="/boot/config.txt"
    elif [ -f "/boot/firmware/config.txt" ]; then
        CONFIG_TXT="/boot/firmware/config.txt"
    else
        error "❗ Could not find config.txt!"
    fi
fi

info "🔧 Updating $CONFIG_TXT..."
ensure_config_in_file "#--------MuPiHAT--------" "$CONFIG_TXT" "Marker for MuPiHAT settings"
ensure_config_in_file "dtparam=i2c_arm=on" "$CONFIG_TXT" "Enable I2C ARM"
ensure_config_in_file "dtparam=i2c1=on" "$CONFIG_TXT" "Enable I2C1"
ensure_config_in_file "dtparam=i2c_arm_baudrate=50000" "$CONFIG_TXT" "Set I2C bus baudrate to 50kHz"
ensure_config_in_file "dtoverlay=max98357a,sdmode-pin=16" "$CONFIG_TXT" "Set audio overlay MAX98357A"
ensure_config_in_file "dtoverlay=i2s-mmap" "$CONFIG_TXT" "Set I2S memory map overlay"
ensure_config_in_file "gpio=4=op,dh" "$CONFIG_TXT" "GPIO 4 as output, default HIGH (will be LOW later)"

info "🔧 Updating kernel modules..."
ensure_kernel_modules


# Create systemd service
info "⚙️ Creating systemd service $SERVICE_NAME..."
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

# Reload systemd and enable service
info "🔄 Reloading systemd configuration..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Check service status
info "🔍 Checking status of service $SERVICE_NAME..."
if systemctl is-active --quiet $SERVICE_NAME; then
    info "✅ Service $SERVICE_NAME is running successfully."
else
    warn "⚠️ Service $SERVICE_NAME could not be started. Check the logs with:"
    echo "    sudo systemctl status mupi_hat.service"
    echo "    sudo journalctl -u $SERVICE_NAME -xe"
fi

info "✅ Setup completed!"

echo ""
info "📢 IMPORTANT: Please restart the Raspberry Pi so that I2C and audio overlay become active:"
echo "    sudo reboot"
echo ""

info "🔊 After the restart, you can test the audio output with:"
echo "    aplay $APP_DIR/assets/stereo-test.wav"
echo ""
