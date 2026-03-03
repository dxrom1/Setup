#!/data/data/com.termux/files/usr/bin/bash
# Kali NetHunter Rootless Automated Setup
# Run this script in Termux on your Android device (no root required)

set -e  # exit on error
set -u  # treat unset variables as error

# ------------------------------
# Helper functions
# ------------------------------
print_status() {
    echo -e "\n\033[1;34m[*]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[✓]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[✗]\033[0m $1"
}

# Check if we're in Termux (not inside proot)
if [ -z "$PREFIX" ] || [ ! -d "/data/data/com.termux" ]; then
    print_error "This script must be run in Termux on Android."
    exit 1
fi

# ------------------------------
# 1. Update Termux and install prerequisites
# ------------------------------
print_status "Updating Termux packages..."
pkg update -y && pkg upgrade -y

print_status "Installing required tools..."
pkg install -y wget proot-distro termux-x11-nightly pulseaudio

# ------------------------------
# 2. Check/Install Kali NetHunter Rootless
# ------------------------------
if command -v nethunter &>/dev/null; then
    print_success "Kali NetHunter is already installed."
else
    print_status "Downloading and installing Kali NetHunter Rootless..."
    # Official NetHunter installer script
    wget -O install-nethunter-termux https://offs.ec/2MceZWr
    chmod +x install-nethunter-termux
    ./install-nethunter-termux

    # Verify installation
    if ! command -v nethunter &>/dev/null; then
        print_error "NetHunter installation failed. Please check manually."
        exit 1
    fi
    print_success "NetHunter installed successfully."
fi

# ------------------------------
# 3. Detect architecture for VS Code
# ------------------------------
ARCH=$(uname -m)
case "$ARCH" in
    aarch64)
        VSCODE_ARCH="arm64"
        ;;
    armv7l|armhf)
        VSCODE_ARCH="armhf"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
print_success "Detected architecture: $ARCH (VS Code: $VSCODE_ARCH)"

# ------------------------------
# 4. Determine privilege escalation method inside Kali
#    Some Galaxy phones need su -c instead of sudo
# ------------------------------
print_status "Testing sudo inside Kali..."
if nethunter sudo whoami &>/dev/null; then
    PRIV_CMD="sudo"
    print_success "sudo works. Will use 'sudo'."
else
    PRIV_CMD="su -c"
    print_success "sudo not available; will use 'su -c' (common on Galaxy devices)."
fi

# ------------------------------
# 5. Install apps inside Kali (VS Code, Firefox, Chromium, Opera)
# ------------------------------
print_status "Installing VS Code and browsers inside Kali (this may take a while)..."

# We'll feed commands to Kali via a here-document
nethunter bash <<EOF
set -e

# Update package lists
$PRIV_CMD "apt update"

# Install prerequisites for adding repos
$PRIV_CMD "apt install -y wget gpg apt-transport-https"

# Install Firefox (from repos)
echo "Installing Firefox..."
$PRIV_CMD "apt install -y firefox-esr"

# Install Chromium
echo "Installing Chromium..."
if [ "$ARCH" = "aarch64" ]; then
    $PRIV_CMD "apt install -y chromium"
else
    $PRIV_CMD "apt install -y chromium-browser"
fi

# Install Opera (add repo, then install)
echo "Installing Opera..."
$PRIV_CMD "wget -qO- https://deb.opera.com/archive.key | gpg --dearmor | tee /usr/share/keyrings/opera.gpg >/dev/null"
$PRIV_CMD "echo 'deb [signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free' > /etc/apt/sources.list.d/opera.list"
$PRIV_CMD "apt update"
$PRIV_CMD "apt install -y opera-stable"

# Install VS Code
echo "Downloading VS Code ($VSCODE_ARCH)..."
wget -O /tmp/code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$VSCODE_ARCH"
echo "Installing VS Code..."
$PRIV_CMD "dpkg -i /tmp/code.deb || true"
$PRIV_CMD "apt install -f -y"   # fix deps
rm /tmp/code.deb

# Final cleanup
$PRIV_CMD "apt autoremove -y"

echo "All applications installed successfully inside Kali."
EOF

print_success "VS Code, Firefox, Chromium, and Opera are now installed."

# ------------------------------
# 6. Set up KeX password (if not already set)
# ------------------------------
print_status "Checking KeX password..."
if nethunter kex status &>/dev/null; then
    print_success "KeX seems configured."
else
    print_status "Please set a password for KeX (Kali desktop)."
    nethunter kex passwd
fi

# ------------------------------
# 7. Final instructions
# ------------------------------
cat <<EOF

╔══════════════════════════════════════════════════════════╗
║  ✅ Setup complete!                                      ║
╠══════════════════════════════════════════════════════════╣
║  Next steps:                                             ║
║  1. Make sure you have installed the following APKs:    ║
║     • NetHunter Store  (from store.nethunter.com)       ║
║     • NetHunter KeX    (from the store)                 ║
║     • Termux:X11       (from GitHub, optional)          ║
║                                                          ║
║  2. Start Kali desktop:                                  ║
║     In Termux, run:  nethunter kex &                    ║
║     Then open the NetHunter KeX client and connect.     ║
║                                                          ║
║  3. Launch your apps from the Kali menu or terminal:    ║
║     • code          (VS Code)                            ║
║     • firefox       (Firefox ESR)                        ║
║     • chromium      (Chromium)                           ║
║     • opera         (Opera)                              ║
║                                                          ║
║  4. To stop KeX:  nethunter kex stop                     ║
║                                                          ║
║  For better performance, check hardware acceleration     ║
║  tutorials (Turnip/Zink) for your specific device.      ║
╚══════════════════════════════════════════════════════════╝
EOF

print_success "Enjoy your Kali NetHunter with VS Code and browsers!"
