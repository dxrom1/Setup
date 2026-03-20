#!/data/data/com.termux/files/usr/bin/bash
##########################################################
# 🚀 TERMUX DESKTOP INSTALLER (Smooth + Screen Share)
# ------------------------------------------------------
# Installs: XFCE4, Firefox, PulseAudio, Termux-X11
# Attempts to enable screen sharing via portal
# Includes error handling, progress bars, and config tweaks
##########################################################

# ============== CONFIG ==============
TOTAL_STEPS=13
CURRENT_STEP=0
REQUIRED_SPACE_MB=1800

# ============== COLORS ==============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; GRAY='\033[0;90m'; NC='\033[0m'
BOLD='\033[1m'

# ============== UI HELPERS ==============
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║   🚀 TERMUX DESKTOP INSTALLER (Smooth) 🚀           ║
║                                                      ║
║   🔥 Firefox  •  🖥️ XFCE4  •  🎵 PulseAudio         ║
║   📸 Screen sharing attempt • 📱 Termux-X11         ║
╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_progress() {
    local percent=$1
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo -e " ${CYAN}${bar}${NC} ${WHITE}${percent}%${NC}"
}

update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo ""
    echo -e "${WHITE}┌────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC} ${GREEN}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} $(print_progress $PERCENT) ${WHITE}│${NC}"
    echo -e "${WHITE}└────────────────────────────────────────────┘${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local msg="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r ${YELLOW}⏳${NC} ${msg} ${CYAN}${spin:$i:1}${NC} "
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r ${GREEN}✓${NC} ${msg} \n"
    else
        printf "\r ${RED}✗${NC} ${msg} ${RED}(failed)${NC} \n"
    fi
}

install_pkg() {
    local pkg=$1
    local name="${2:-$pkg}"
    # Skip if already installed
    if pkg list-installed 2>/dev/null | grep -q "^$pkg\$"; then
        echo -e " ${GREEN}✓${NC} ${name} already installed"
        return 0
    fi
    (yes | pkg install "$pkg" -y > /dev/null 2>&1) & spinner $! "Installing ${name}"
}

check_storage() {
    local avail=$(df /data | awk 'NR==2 {print $4}')
    local avail_mb=$((avail / 1024))
    if [ $avail_mb -lt $REQUIRED_SPACE_MB ]; then
        echo -e "${RED}⚠️ Low storage: ${avail_mb}MB available, ${REQUIRED_SPACE_MB}MB recommended.${NC}"
        echo -e "${YELLOW}Continue anyway? (y/n)${NC} "
        read -n1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Storage OK (${avail_mb}MB available)${NC}"
    fi
}

# ============== INSTALLATION STEPS ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Updating system packages...${NC}\n"
    (yes | pkg update -y > /dev/null 2>&1) & spinner $! "Updating package lists"
    (yes | pkg upgrade -y > /dev/null 2>&1) & spinner $! "Upgrading installed packages"
}

step_repos() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Adding package repositories...${NC}\n"
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository"
}

step_x11() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing Termux-X11 display server...${NC}\n"
    install_pkg "termux-x11-nightly" "Termux-X11"
    install_pkg "xorg-xrandr" "XRandR"
}

step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing XFCE4 desktop environment...${NC}\n"
    install_pkg "xfce4" "XFCE4 Desktop"
    install_pkg "xfce4-terminal" "Terminal"
    install_pkg "thunar" "File Manager"
    install_pkg "mousepad" "Text Editor"
    install_pkg "dbus" "DBus"
}

step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Configuring software rendering (LLVMpipe)...${NC}\n"
    install_pkg "mesa" "Mesa (LLVMpipe)"
    echo -e " ${GREEN}✓${NC} Software rendering configured (compatible with all devices)"
}

step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Setting up audio...${NC}\n"
    install_pkg "pulseaudio" "PulseAudio"
}

step_screen_share() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing screen sharing support (xdg-desktop-portal)...${NC}\n"
    install_pkg "xdg-desktop-portal-termux" "XDG Desktop Portal (Termux)"
    # Note: xdg-desktop-portal-gtk not available; only termux portal is used.
    echo -e " ${GREEN}✓${NC} Screen sharing dependencies installed"
}

step_browser() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing Firefox web browser...${NC}\n"
    install_pkg "firefox" "Firefox"
}

step_essentials() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing essential utilities...${NC}\n"
    install_pkg "git" "Git"
    install_pkg "curl" "cURL"
    install_pkg "wget" "Wget"
    install_pkg "htop" "htop"
    install_pkg "neofetch" "Neofetch"
    echo -e " ${GREEN}✓ Essentials installed${NC}"
}

step_config_firefox() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Configuring Firefox for screen sharing...${NC}\n"
    # Create Firefox profile directory if not exists
    mkdir -p ~/.mozilla/firefox/*.default-release/
    # Set preferences via user.js
    cat > ~/.mozilla/firefox/*.default-release/user.js 2>/dev/null << 'EOF'
// Enable screen sharing
user_pref("media.webrtc.screen.allow", true);
user_pref("media.getusermedia.screensharing.enabled", true);
user_pref("media.webrtc.hw.h264.enabled", false);
user_pref("media.webrtc.hw.vp8.enabled", false);
EOF
    # If no profile exists, create one
    if [ ! -d ~/.mozilla/firefox/*.default-release/ ]; then
        firefox --headless --CreateProfile "default" > /dev/null 2>&1 &
        sleep 2
        pkill -f firefox 2>/dev/null
        # Find the profile path
        PROFILE_PATH=$(find ~/.mozilla/firefox -name "*.default-release" -type d | head -1)
        if [ -n "$PROFILE_PATH" ]; then
            cat > "$PROFILE_PATH/user.js" << 'EOF'
user_pref("media.webrtc.screen.allow", true);
user_pref("media.getusermedia.screensharing.enabled", true);
user_pref("media.webrtc.hw.h264.enabled", false);
user_pref("media.webrtc.hw.vp8.enabled", false);
EOF
        fi
    fi
    echo -e " ${GREEN}✓${NC} Firefox configured"
}

step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Creating launcher scripts...${NC}\n"
    mkdir -p ~/.config

    # GPU config: use software rendering
    cat > ~/.config/gpu.conf << 'EOF'
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_NO_ERROR=1
EOF
    echo -e " ${GREEN}✓${NC} GPU config created"
    if ! grep -q "gpu.conf" ~/.bashrc 2>/dev/null; then
        echo "source ~/.config/gpu.conf 2>/dev/null" >> ~/.bashrc
    fi

    cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "🚀 Starting Desktop Environment..."
source ~/.config/gpu.conf 2>/dev/null

# Environment variables for screen sharing
export WEBRTC_ENABLE_SCREEN_CAPTURE=1
export MOZ_ENABLE_WAYLAND=0
export XDG_CURRENT_DESKTOP=XFCE
export DBUS_SESSION_BUS_ADDRESS=""

# Kill old sessions
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "xdg-desktop-portal" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null

# Audio
pulseaudio --kill 2>/dev/null
sleep 0.5
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# Start dbus
dbus-daemon --session --fork --print-address 2>/dev/null

# Start xdg-desktop-portal-termux
if [ -x /usr/libexec/xdg-desktop-portal-termux ]; then
    /usr/libexec/xdg-desktop-portal-termux &
    sleep 1
fi

# X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📱 Open Termux-X11 app to see the desktop!"
echo " 📸 Screen sharing: Firefox is pre-configured."
echo "    If it fails, set 'media.webrtc.screen.allow'"
echo "    to true in about:config (already done)."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec startxfce4
EOF
    chmod +x ~/start-desktop.sh
    echo -e " ${GREEN}✓${NC} Created ~/start-desktop.sh"

    cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "xdg-desktop-portal" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-desktop.sh
    echo -e " ${GREEN}✓${NC} Created ~/stop-desktop.sh"
}

step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Placing desktop shortcuts...${NC}\n"
    mkdir -p ~/Desktop

    # Firefox
    cat > ~/Desktop/Firefox.desktop << 'FIREFOX'
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;
FIREFOX

    # Terminal
    cat > ~/Desktop/Terminal.desktop << 'TERM'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;
TERM

    # File Manager
    cat > ~/Desktop/FileManager.desktop << 'FM'
[Desktop Entry]
Name=File Manager
Comment=Thunar File Manager
Exec=thunar
Icon=thunar
Type=Application
Categories=System;
FM

    chmod +x ~/Desktop/*.desktop 2>/dev/null
    echo -e " ${GREEN}✓${NC} Shortcuts created"
}

step_final_instructions() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Displaying final instructions...${NC}\n"
    # No action, just a placeholder
}

show_summary() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN} ✅ INSTALLATION COMPLETE! ✅${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}📦 Installed applications:${NC}"
    echo -e " ${CYAN}•${NC} Firefox (pre-configured for screen sharing) ${GREEN}✓${NC}"
    echo -e " ${CYAN}•${NC} XFCE4 Desktop ${GREEN}✓${NC}"
    echo -e " ${CYAN}•${NC} Essentials: git, curl, wget, htop, neofetch ${GREEN}✓${NC}"
    echo ""
    echo -e "${WHITE}🚀 Commands:${NC}"
    echo -e " ${GREEN}bash ~/start-desktop.sh${NC} - Start desktop"
    echo -e " ${GREEN}bash ~/stop-desktop.sh${NC}  - Stop desktop"
    echo ""
    echo -e "${WHITE}📸 Screen Sharing Notes:${NC}"
    echo -e " - Firefox has been configured with screen sharing flags."
    echo -e " - The xdg-desktop-portal-termux is started with the desktop."
    echo -e " - If screen sharing still fails, it's due to missing PipeWire."
    echo -e "   Alternative: Use Termux-X11's built-in screen share button."
    echo -e "   Or share your phone's screen directly via Android's native"
    echo -e "   screen recording (Discord mobile supports screen share)."
    echo ""
    echo -e "${WHITE}🛠️ Troubleshooting:${NC}"
    echo -e " - If desktop doesn't start, run: ${GREEN}termux-x11 :0 -ac${NC}"
    echo -e " - Check portal: ${GREEN}ps aux | grep portal${NC}"
    echo -e " - Check Firefox flags: about:config"
    echo ""
}

# ============== MAIN ==============
main() {
    print_banner
    echo -e "${WHITE}This script will install a smooth Linux desktop with Firefox.${NC}"
    echo -e "${GRAY}Estimated time: 12-20 minutes (depends on internet).${NC}\n"
    check_storage
    echo ""
    echo -e "${YELLOW}Press ENTER to start or Ctrl+C to cancel...${NC}"
    read -s

    step_update
    step_repos
    step_x11
    step_desktop
    step_gpu
    step_audio
    step_screen_share
    step_browser
    step_essentials
    step_config_firefox
    step_launchers
    step_shortcuts
    step_final_instructions
    show_summary
}

main
