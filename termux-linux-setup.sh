#!/data/data/com.termux/files/usr/bin/bash
##########################################################
# 🚀 TERMUX DESKTOP INSTALLER (Stable + dpkg Fix)
# ------------------------------------------------------
# Fixes dpkg errors, then installs XFCE4, Firefox,
# PulseAudio, Termux-X11, and essential tools.
##########################################################

# ============== COLORS ==============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║   🚀 TERMUX DESKTOP (Stable + dpkg Fix) 🚀          ║
║                                                      ║
║   🔥 Firefox  •  🖥️ XFCE4  •  🎵 PulseAudio         ║
║   📱 Termux-X11  •  ⚡ No lag (LLVMpipe)            ║
╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ============== FIX DPKG FIRST ==============
fix_dpkg() {
    echo -e "${YELLOW}Checking for dpkg errors...${NC}"
    if ! dpkg --configure -a 2>/dev/null; then
        echo -e "${RED}dpkg error detected. Attempting to fix...${NC}"
        pkg clean
        rm -f /data/data/com.termux/files/usr/var/lib/dpkg/updates/*
        dpkg --configure -a
        pkg update -y
    fi
    echo -e "${GREEN}✓ dpkg is ready${NC}"
}

# ============== SAFE INSTALL FUNCTION ==============
safe_install() {
    local pkg="$1"
    local name="${2:-$pkg}"
    echo -e "${YELLOW}Installing ${name}...${NC}"
    for i in {1..3}; do
        if pkg install -y "$pkg" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ ${name} installed${NC}"
            return 0
        else
            echo -e "${RED}Attempt $i failed, retrying...${NC}"
            sleep 2
            # Try to fix broken packages
            pkg install -y -f > /dev/null 2>&1
        fi
    done
    echo -e "${RED}✗ Failed to install ${name}. Continuing anyway.${NC}"
    return 1
}

# ============== MAIN INSTALLATION ==============
main() {
    print_banner

    # Fix any existing dpkg issues
    fix_dpkg

    echo -e "${YELLOW}Updating package lists...${NC}"
    pkg update -y

    echo -e "${YELLOW}Installing repositories...${NC}"
    safe_install "x11-repo" "X11 Repository"
    safe_install "tur-repo" "TUR Repository"
    pkg update -y

    echo -e "${YELLOW}Installing XFCE4 desktop...${NC}"
    safe_install "xfce4" "XFCE4 Desktop"
    safe_install "xfce4-terminal" "Terminal"
    safe_install "thunar" "File Manager"
    safe_install "mousepad" "Text Editor"
    safe_install "dbus" "DBus"

    echo -e "${YELLOW}Installing Termux-X11...${NC}"
    safe_install "termux-x11-nightly" "Termux-X11"
    safe_install "xorg-xrandr" "XRandR"

    echo -e "${YELLOW}Installing audio...${NC}"
    safe_install "pulseaudio" "PulseAudio"

    echo -e "${YELLOW}Installing Firefox...${NC}"
    safe_install "firefox" "Firefox"

    echo -e "${YELLOW}Installing software rendering...${NC}"
    safe_install "mesa" "Mesa (LLVMpipe)"

    echo -e "${YELLOW}Installing utilities...${NC}"
    safe_install "git" "Git"
    safe_install "curl" "cURL"
    safe_install "wget" "Wget"
    safe_install "htop" "htop"
    safe_install "neofetch" "Neofetch"

    # ============== CONFIGURATION ==============
    echo -e "${YELLOW}Creating configuration files...${NC}"

    mkdir -p ~/.config
    cat > ~/.config/gpu.conf << 'EOF'
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_NO_ERROR=1
EOF

    if ! grep -q "gpu.conf" ~/.bashrc 2>/dev/null; then
        echo "source ~/.config/gpu.conf 2>/dev/null" >> ~/.bashrc
    fi

    # Firefox screen sharing prefs (if profile exists)
    PROFILE=$(find ~/.mozilla/firefox -name "*.default-release" -type d 2>/dev/null | head -1)
    if [ -n "$PROFILE" ]; then
        cat >> "$PROFILE/user.js" << 'EOF' 2>/dev/null
user_pref("media.webrtc.screen.allow", true);
user_pref("media.getusermedia.screensharing.enabled", true);
EOF
    fi

    # ============== LAUNCHER SCRIPTS ==============
    echo -e "${YELLOW}Creating startup scripts...${NC}"

    cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🚀 Starting Desktop..."

source ~/.config/gpu.conf 2>/dev/null

# Kill old sessions
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce4" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null

# Start PulseAudio
pulseaudio --kill 2>/dev/null
sleep 0.5
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# Start D-Bus
dbus-daemon --session --fork --print-address 2>/dev/null

# Start Termux-X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📱 Open Termux-X11 app now!"
echo " ⏱️  Desktop should appear in a few seconds."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start XFCE
startxfce4
EOF
    chmod +x ~/start-desktop.sh

    cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🛑 Stopping Desktop..."
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce4" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-desktop.sh

    # Desktop shortcuts
    mkdir -p ~/Desktop
    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;
EOF
    cat > ~/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;
EOF
    cat > ~/Desktop/FileManager.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Exec=thunar
Icon=thunar
Type=Application
Categories=System;
EOF
    chmod +x ~/Desktop/*.desktop

    # ============== SUMMARY ==============
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} ✅ INSTALLATION COMPLETE! ✅${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}🚀 To start the desktop:${NC}"
    echo -e "   ${GREEN}bash ~/start-desktop.sh${NC}"
    echo -e "   (Make sure Termux-X11 app is open before running)"
    echo ""
    echo -e "${WHITE}🛑 To stop the desktop:${NC}"
    echo -e "   ${GREEN}bash ~/stop-desktop.sh${NC}"
    echo ""
    echo -e "${WHITE}⚡ If the desktop is laggy:${NC}"
    echo -e "   • In Termux-X11 settings, reduce resolution (e.g., 1280x720)."
    echo -e "   • In XFCE: Settings → Window Manager Tweaks → set to 'No compositor'."
    echo ""
    echo -e "${WHITE}🔧 If you still get dpkg errors:${NC}"
    echo -e "   • Run: ${GREEN}dpkg --configure -a${NC} manually."
    echo -e "   • Then: ${GREEN}pkg clean${NC} and try starting desktop."
    echo ""
}

# Run main function
main
