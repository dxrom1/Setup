#!/data/data/com.termux/files/usr/bin/bash
# Kali NetHunter Rootless Automated Installer
# One-liner: curl -O https://raw.githubusercontent.com/dxrom1/Setup/main/termux-linux-setup.sh && chmod +x termux-linux-setup.sh && ./termux-linux-setup.sh

set -euo pipefail

# ------------------------------
# Colors and UI helpers
# ------------------------------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║     Kali NetHunter Rootless Setup for Android            ║
║         VS Code + Firefox + Chromium + Opera             ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
    echo -e "${BOLD}Date: $(date '+%Y-%m-%d %H:%M')${RESET}\n"
}

print_status() {
    echo -e "${BLUE}[•]${RESET} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${RESET} $1"
}

print_error() {
    echo -e "${RED}[✗]${RESET} $1"
}

# Spinner for background processes (used only for non-critical long ops)
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" >/dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Retry function for downloads
download_with_retry() {
    local url=$1
    local output=$2
    local max_retries=3
    local retry_delay=5
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        print_status "Downloading $output (attempt $attempt/$max_retries)..."
        if curl -L --progress-bar -o "$output" "$url"; then
            print_success "Downloaded $output"
            return 0
        else
            print_warning "Download failed. Retrying in $retry_delay seconds..."
            sleep $retry_delay
        fi
        ((attempt++))
    done
    print_error "Failed to download $output after $max_retries attempts."
    return 1
}

# ------------------------------
# 1. Initial checks
# ------------------------------
print_banner

# Check if running in Termux
if [ -z "${PREFIX:-}" ] || [ ! -d "/data/data/com.termux" ]; then
    print_error "This script must be run in Termux on Android."
    exit 1
fi

# Check internet connectivity
print_status "Checking internet connection..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    print_error "No internet connection. Please connect and try again."
    exit 1
fi
print_success "Internet connected."

# Optional: check available storage (at least 2GB free)
available=$(df /data | awk 'NR==2 {print $4}')
if [ "$available" -lt 2000000 ]; then
    print_warning "Less than 2GB free storage. Installation may fail."
fi

# ------------------------------
# 2. Update Termux and install prerequisites
# ------------------------------
print_status "Updating Termux packages..."
pkg update -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1 &
spinner $!
print_success "Package lists updated."

print_status "Upgrading Termux packages (this may take a while)..."
pkg upgrade -y -o Dpkg::Options::="--force-confold" > /dev/null 2>&1 &
spinner $!
print_success "Packages upgraded."

print_status "Installing required tools (wget, proot-distro, etc.)..."
pkg install -y wget proot-distro termux-x11-nightly pulseaudio > /dev/null 2>&1 &
spinner $!
print_success "Tools installed."

# ------------------------------
# 3. Install Kali NetHunter Rootless if missing
# ------------------------------
if command -v nethunter &>/dev/null; then
    print_success "Kali NetHunter is already installed."
else
    print_status "Downloading NetHunter Rootless installer..."
    download_with_retry "https://offs.ec/2MceZWr" "install-nethunter-termux"
    chmod +x install-nethunter-termux

    print_warning "Running NetHunter installer in foreground (to show progress/errors)..."
    print_warning "If it asks for permissions, grant them."
    # Run without redirection so user sees any errors
    if ! ./install-nethunter-termux; then
        print_error "NetHunter installer failed. Please check the output above."
        print_error "Common issues: insufficient storage, network problems, or missing dependencies."
        exit 1
    fi

    # Verify installation succeeded
    if ! command -v nethunter &>/dev/null; then
        print_error "NetHunter installation completed but 'nethunter' command not found."
        exit 1
    fi
    print_success "Kali NetHunter installed."
fi

# ------------------------------
# 4. Detect architecture for VS Code
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
# 5. Determine privilege escalation method inside Kali
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
# 6. Install apps inside Kali
# ------------------------------
print_status "Installing VS Code, Firefox, Chromium, and Opera inside Kali..."
print_warning "This may take 10-15 minutes depending on your device and internet."

# Create a temporary script to run inside Kali
cat > /data/data/com.termux/files/home/kali_install.sh <<EOF
#!/bin/bash
set -e

# Update package lists
$PRIV_CMD "apt update -y" > /dev/null 2>&1

# Install prerequisites
$PRIV_CMD "apt install -y wget gpg apt-transport-https" > /dev/null 2>&1

# Install Firefox
echo -e "${BLUE}[•]${RESET} Installing Firefox..."
$PRIV_CMD "apt install -y firefox-esr" > /dev/null 2>&1

# Install Chromium
echo -e "${BLUE}[•]${RESET} Installing Chromium..."
if [ "$ARCH" = "aarch64" ]; then
    $PRIV_CMD "apt install -y chromium" > /dev/null 2>&1
else
    $PRIV_CMD "apt install -y chromium-browser" > /dev/null 2>&1
fi

# Install Opera
echo -e "${BLUE}[•]${RESET} Installing Opera..."
$PRIV_CMD "wget -qO- https://deb.opera.com/archive.key | gpg --dearmor | tee /usr/share/keyrings/opera.gpg >/dev/null"
$PRIV_CMD "echo 'deb [signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free' > /etc/apt/sources.list.d/opera.list"
$PRIV_CMD "apt update -y" > /dev/null 2>&1
$PRIV_CMD "apt install -y opera-stable" > /dev/null 2>&1

# Install VS Code
echo -e "${BLUE}[•]${RESET} Downloading VS Code ($VSCODE_ARCH)..."
wget -q --show-progress -O /tmp/code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$VSCODE_ARCH"
echo -e "${BLUE}[•]${RESET} Installing VS Code..."
$PRIV_CMD "dpkg -i /tmp/code.deb || true" > /dev/null 2>&1
$PRIV_CMD "apt install -f -y" > /dev/null 2>&1
rm -f /tmp/code.deb

# Cleanup
$PRIV_CMD "apt autoremove -y" > /dev/null 2>&1
EOF

# Run the script inside Kali
nethunter bash /data/data/com.termux/files/home/kali_install.sh
rm -f /data/data/com.termux/files/home/kali_install.sh

print_success "All applications installed successfully."

# ------------------------------
# 7. Set up KeX password if not already set
# ------------------------------
print_status "Checking KeX password..."
if nethunter kex status &>/dev/null; then
    print_success "KeX already configured."
else
    print_warning "You need to set a password for KeX (Kali desktop)."
    nethunter kex passwd
fi

# ------------------------------
# 8. Final instructions
# ------------------------------
print_banner
cat <<EOF
${GREEN}✅ Setup Complete!${RESET}

${BOLD}What's installed:${RESET}
  • VS Code (code)
  • Firefox (firefox)
  • Chromium (chromium)
  • Opera (opera)

${BOLD}Next Steps:${RESET}
1. Make sure you have the ${CYAN}NetHunter KeX${RESET} Android app installed
   (get it from store.nethunter.com or F-Droid)

2. Start the Kali desktop:
   ${YELLOW}nethunter kex &${RESET}
   Then open the KeX app and connect (use the password you set).

3. Launch apps from the Kali menu or terminal:
   • Type ${YELLOW}code${RESET} for VS Code
   • Type ${YELLOW}firefox${RESET} for Firefox
   • Type ${YELLOW}chromium${RESET} for Chromium
   • Type ${YELLOW}opera${RESET} for Opera

4. To stop KeX: ${YELLOW}nethunter kex stop${RESET}

${BOLD}Need help?${RESET} Check the official docs:
   https://www.kali.org/docs/nethunter/nethunter-rootless/
EOF

print_success "Enjoy your Kali NetHunter with development tools!"
