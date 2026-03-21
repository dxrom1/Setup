#!/data/data/com.termux/files/usr/bin/bash
##########################################################
# 🚀 TERMUX DESKTOP INSTALLER (Stable & Smooth)
# ------------------------------------------------------
# Installs: XFCE4, Firefox, PulseAudio, Termux-X11
# Uses LLVMpipe for software rendering (no Vulkan needed)
# Includes a reliable startup script
##########################################################

# ============== COLORS ==============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; GRAY='\033[0;90m'; NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║   🚀 TERMUX DESKTOP (Stable & Smooth) 🚀            ║
║                                                      ║
║   🔥 Firefox  •  🖥️ XFCE4  •  🎵 PulseAudio         ║
║   📱 Termux-X11  •  ⚡ No lag (LLVMpipe)            ║
╚══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ============== INSTALLATION ==============
echo -e "${YELLOW}Updating packages...${NC}"
pkg update -y && pkg upgrade -y

echo -e "${YELLOW}Installing required repositories...${NC}"
pkg install -y x11-repo tur-repo

echo -e "${YELLOW}Installing XFCE4 desktop and essential tools...${NC}"
pkg install -y xfce4 xfce4-terminal thunar mousepad dbus

echo -e "${YELLOW}Installing Termux-X11 display server...${NC}"
pkg install -y termux-x11-nightly xorg-xrandr

echo -e "${YELLOW}Installing audio support...${NC}"
pkg install -y pulseaudio

echo -e "${YELLOW}Installing Firefox browser...${NC}"
pkg install -y firefox

echo -e "${YELLOW}Installing software rendering (LLVMpipe)...${NC}"
pkg install -y mesa

echo -e "${YELLOW}Installing essential utilities...${NC}"
pkg install -y git curl wget htop neofetch

# ============== CONFIGURATION ==============
echo -e "${YELLOW}Creating configuration files...${NC}"

# GPU config for software rendering
mkdir -p ~/.config
cat > ~/.config/gpu.conf << 'EOF'
export GALLIUM_DRIVER=llvmpipe
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_NO_ERROR=1
EOF

# Add to .bashrc
if ! grep -q "gpu.conf" ~/.bashrc 2>/dev/null; then
    echo "source ~/.config/gpu.conf 2>/dev/null" >> ~/.bashrc
fi

# Firefox preferences for screen sharing (if possible)
mkdir -p ~/.mozilla/firefox
PROFILE=$(find ~/.mozilla/firefox -name "*.default-release" -type d 2>/dev/null | head -1)
if [ -n "$PROFILE" ]; then
    cat > "$PROFILE/user.js" << 'EOF'
user_pref("media.webrtc.screen.allow", true);
user_pref("media.getusermedia.screensharing.enabled", true);
EOF
fi

# ============== LAUNCHER SCRIPTS ==============
echo -e "${YELLOW}Creating startup scripts...${NC}"

# Start script
cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🚀 Starting Desktop..."

# Load GPU config
source ~/.config/gpu.conf 2>/dev/null

# Kill any existing sessions
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

# Start D-Bus (required for some apps)
dbus-daemon --session --fork --print-address 2>/dev/null

# Start Termux-X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📱 Open Termux-X11 app now to see the desktop!"
echo " ⏱️  If it doesn't appear, wait a few seconds..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start XFCE
startxfce4
EOF

chmod +x ~/start-desktop.sh

# Stop script
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

# ============== DESKTOP SHORTCUTS ==============
echo -e "${YELLOW}Creating desktop shortcuts...${NC}"
mkdir -p ~/Desktop

cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Comment=Web Browser
Exec=firefox
Icon=firefox
Type=Application
Categories=Network;
EOF

cat > ~/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Comment=XFCE Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
Categories=System;
EOF

cat > ~/Desktop/FileManager.desktop << 'EOF'
[Desktop Entry]
Name=File Manager
Comment=Thunar File Manager
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
echo ""
echo -e "${WHITE}🛑 To stop the desktop:${NC}"
echo -e "   ${GREEN}bash ~/stop-desktop.sh${NC}"
echo ""
echo -e "${WHITE}📱 IMPORTANT:${NC}"
echo -e "   • Install Termux-X11 from F-Droid if not already installed."
echo -e "   • Open the Termux-X11 app after running the start script."
echo -e "   • The desktop should appear within 5-10 seconds."
echo ""
echo -e "${WHITE}⚡ Performance tips:${NC}"
echo -e "   • This uses software rendering (LLVMpipe) for maximum compatibility."
echo -e "   • Reduce lag by lowering resolution in Termux-X11 settings."
echo -e "   • Disable animations in XFCE (Settings → Window Manager Tweaks)."
echo ""
echo -e "${WHITE}🔧 If the desktop doesn't start:${NC}"
echo -e "   • Run ${GREEN}termux-x11 :0 -ac${NC} manually and check errors."
echo -e "   • Ensure the Termux-X11 app is open before starting."
echo -e "   • Try ${GREEN}bash ~/start-desktop.sh${NC} again after killing with stop script."
echo ""

# Optional: test start
read -p "Do you want to start the desktop now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash ~/start-desktop.sh
fi
