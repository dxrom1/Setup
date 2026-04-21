#!/data/data/com.termux/files/usr/bin/bash
##########################################################
#  🎨 TERMUX DESKTOP + SCREEN SHARE FIX + LAG REDUCTION
#  ------------------------------------------------------
#  Fixes: Discord screen share, browser lag, GPU acceleration
##########################################################

# ============== CONFIG ==============
TOTAL_STEPS=13
CURRENT_STEP=0
REQUIRED_SPACE_MB=2800

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
    ║   🚀  TERMUX DEV + CREATOR INSTALLER (FIXED)       ║
    ║   ✅ Discord screen share  |  🚀 Low lag           ║
    ║   🔥 Firefox   ●   🌐 Chromium   ●   💻 VS Code     ║
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
    echo -e "  ${CYAN}${bar}${NC} ${WHITE}${percent}%${NC}"
}

update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo ""
    echo -e "${WHITE}┌────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC}  ${GREEN}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC}  $(print_progress $PERCENT)  ${WHITE}│${NC}"
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
        printf "\r  ${YELLOW}⏳${NC} ${msg} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r  ${GREEN}✓${NC} ${msg}                      \n"
    else
        printf "\r  ${RED}✗${NC} ${msg} ${RED}(failed)${NC}    \n"
    fi
}

install_pkg() {
    local pkg=$1
    local name="${2:-$pkg}"
    (yes | pkg install "$pkg" -y > /dev/null 2>&1) &
    spinner $! "Installing ${name}"
}

check_storage() {
    local avail=$(df /data | awk 'NR==2 {print $4}')
    local avail_mb=$((avail / 1024))
    if [ $avail_mb -lt $REQUIRED_SPACE_MB ]; then
        echo -e "${RED}⚠️  Low storage: ${avail_mb}MB available, ${REQUIRED_SPACE_MB}MB recommended.${NC}"
        echo -e "${YELLOW}Continue anyway? (y/n)${NC} "
        read -n1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
    else
        echo -e "${GREEN}✓ Storage OK (${avail_mb}MB available)${NC}"
    fi
}

# ============== DEVICE DETECTION ==============
detect_device() {
    echo -e "${PURPLE}[*] Gathering system information...${NC}\n"
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
    STORAGE=$(df -h /data | awk 'NR==2 {print $4}')

    echo -e "  ${GREEN}📱${NC} Device   : ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  ${GREEN}🤖${NC} Android  : ${WHITE}${ANDROID_VERSION}${NC}"
    echo -e "  ${GREEN}⚙️${NC}  CPU     : ${WHITE}${CPU_ABI}${NC}"
    echo -e "  ${GREEN}💾${NC} RAM      : ${WHITE}${TOTAL_RAM}MB${NC}"
    echo -e "  ${GREEN}📀${NC} Storage  : ${WHITE}${STORAGE} free${NC}"

    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" =~ (samsung|oneplus|xiaomi) ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  ${GREEN}🎮${NC} GPU      : ${WHITE}Adreno (Turnip driver)${NC}"
    else
        GPU_DRIVER="swrast"
        echo -e "  ${GREEN}🎮${NC} GPU      : ${WHITE}Software rendering${NC}"
    fi
    echo ""
    sleep 1
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
    # Performance tweaks: disable compositing in xfwm4 (we'll use picom instead)
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="vblank_mode" type="string" value="off"/>
  </property>
</channel>
EOF
}

step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Enabling GPU acceleration...${NC}\n"
    install_pkg "mesa-zink" "Mesa Zink (OpenGL over Vulkan)"
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        install_pkg "mesa-vulkan-icd-freedreno" "Turnip Adreno Driver"
    else
        install_pkg "mesa-vulkan-icd-swrast" "Software Vulkan"
    fi
    install_pkg "vulkan-loader-android" "Vulkan Loader"
    # Additional GPU utils
    install_pkg "mesa-utils" "Mesa utilities (glxinfo)"
    echo -e "  ${GREEN}✓${NC} GPU configured"
}

step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Setting up PipeWire (replaces PulseAudio for screen sharing)...${NC}\n"
    # Remove PulseAudio to avoid conflict
    pkg uninstall pulseaudio -y 2>/dev/null
    install_pkg "pipewire" "PipeWire"
    install_pkg "wireplumber" "WirePlumber (session manager)"
    install_pkg "pipewire-pulse" "PipeWire Pulse replacement"
    # Enable socket for apps
    mkdir -p ~/.config/pipewire
    cp /data/data/com.termux/files/usr/share/examples/pipewire/pipewire.conf ~/.config/pipewire/ 2>/dev/null || true
}

step_compositor() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing Picom compositor (fixes screen sharing)...${NC}\n"
    install_pkg "picom" "Picom (X11 compositor)"
    # Create picom config for low latency
    mkdir -p ~/.config/picom
    cat > ~/.config/picom/picom.conf << 'EOF'
backend = "glx";
vsync = false;
unredir-if-possible = false;
experimental-backends = true;
glx-no-stencil = true;
glx-no-rebind-pixmap = true;
xrender-sync-fence = true;
EOF
}

step_portals() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing desktop portals (required for Discord screen share)...${NC}\n"
    install_pkg "xdg-desktop-portal" "XDG Desktop Portal"
    install_pkg "xdg-desktop-portal-gtk" "GTK portal"
}

step_browsers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing web browsers with screen share & GPU flags...${NC}\n"
    install_pkg "firefox" "Firefox"
    install_pkg "chromium" "Chromium"
    
    # Create wrapper scripts that include hardware acceleration and screen share flags
    cat > ~/bin/firefox-fixed << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
export MOZ_ENABLE_WAYLAND=0
export MOZ_X11_EGL=1
exec firefox --enable-features=VaapiVideoDecoder,VaapiVideoEncoder "$@"
EOF
    chmod +x ~/bin/firefox-fixed

    cat > ~/bin/chromium-fixed << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec chromium --enable-features=VaapiVideoDecoder,VaapiVideoEncoder --use-gl=egl --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --disable-accelerated-2d-canvas --disable-gpu-sandbox --ozone-platform=x11 "$@"
EOF
    chmod +x ~/bin/chromium-fixed
    
    mkdir -p ~/bin
    echo -e "  ${GREEN}✓${NC} Browser wrappers created (use 'firefox-fixed' or 'chromium-fixed')"
}

step_vscode() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing VS Code...${NC}\n"
    install_pkg "code-oss" "VS Code (Open Source)"
}

step_dev_tools() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing extra development tools...${NC}\n"
    install_pkg "gcc" "GCC"
    install_pkg "clang" "Clang"
    install_pkg "make" "Make"
    install_pkg "cmake" "CMake"
    install_pkg "pkg-config" "pkg-config"
    install_pkg "python" "Python"
    install_pkg "nodejs" "Node.js"
    install_pkg "rust" "Rust"
    install_pkg "gdb" "GDB"
    install_pkg "valgrind" "Valgrind"
    install_pkg "strace" "strace"
    install_pkg "vim" "Vim"
    install_pkg "nano" "Nano"
    install_pkg "git" "Git"
    install_pkg "curl" "cURL"
    install_pkg "wget" "Wget"
    install_pkg "htop" "Htop"
    install_pkg "neofetch" "Neofetch"
    install_pkg "subversion" "Subversion"
    echo -e "  ${GREEN}✓ Development tools installed${NC}"
}

step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Creating launcher scripts with PipeWire & Picom...${NC}\n"

    mkdir -p ~/.config
    cat > ~/.config/gpu.conf << 'EOF'
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
export EGL_PLATFORM=x11
export GDK_BACKEND=x11
EOF
    echo -e "  ${GREEN}✓${NC} GPU config created"

    if ! grep -q "gpu.conf" ~/.bashrc 2>/dev/null; then
        echo "source ~/.config/gpu.conf 2>/dev/null" >> ~/.bashrc
    fi

    cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "🚀 Starting Desktop Environment with screen share support..."
source ~/.config/gpu.conf 2>/dev/null

# Kill old sessions
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "picom" 2>/dev/null
pkill -9 -f "pipewire" 2>/dev/null
pkill -9 -f "wireplumber" 2>/dev/null

# Start PipeWire (replaces PulseAudio)
pipewire -c ~/.config/pipewire/pipewire.conf &
sleep 1
wireplumber &
sleep 1
pipewire-pulse &
sleep 1
export PULSE_SERVER=unix:/tmp/pulse-socket

# Start Termux-X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

# Start Picom compositor (fixes screen sharing)
picom --config ~/.config/picom/picom.conf -b

# Start XFCE (compositing already disabled in xfwm4)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 Open Termux-X11 app to see the desktop!"
echo "  🖥️  For Discord screen share:"
echo "     - Use 'firefox-fixed' or 'chromium-fixed'"
echo "     - Share entire screen (not window)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec startxfce4
EOF
    chmod +x ~/start-desktop.sh
    echo -e "  ${GREEN}✓${NC} Created ~/start-desktop.sh"

    cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pipewire" 2>/dev/null
pkill -9 -f "wireplumber" 2>/dev/null
pkill -9 -f "picom" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-desktop.sh
    echo -e "  ${GREEN}✓${NC} Created ~/stop-desktop.sh"
}

step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Placing desktop shortcuts...${NC}\n"
    mkdir -p ~/Desktop

    # Firefox (using fixed wrapper)
    cat > ~/Desktop/Firefox.desktop << 'FIREFOX'
[Desktop Entry]
Name=Firefox (Screen Share Fix)
Comment=Web Browser
Exec=/data/data/com.termux/files/home/bin/firefox-fixed
Icon=firefox
Type=Application
Categories=Network;
FIREFOX

    # Chromium (fixed wrapper)
    cat > ~/Desktop/Chromium.desktop << 'CHROMIUM'
[Desktop Entry]
Name=Chromium (Screen Share Fix)
Comment=Web Browser
Exec=/data/data/com.termux/files/home/bin/chromium-fixed
Icon=chromium
Type=Application
Categories=Network;
CHROMIUM

    # VS Code
    cat > ~/Desktop/VSCode.desktop << 'VSCODE'
[Desktop Entry]
Name=VS Code
Comment=Code Editor
Exec=code-oss --no-sandbox
Icon=code-oss
Type=Application
Categories=Development;
VSCODE

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
    echo -e "  ${GREEN}✓${NC} Shortcuts created"
}

# ============== COMPLETION ==============
show_summary() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅  INSTALLATION COMPLETE (SCREEN SHARE FIXED)  ✅${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}📦 Installed applications:${NC}"
    echo -e "  ${CYAN}•${NC} Firefox (with screen share flags)   ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} Chromium (with GPU acceleration)    ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} VS Code                             ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} Development tools (GCC, Python, Node, Rust, ...) ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} PipeWire + WirePlumber (audio + screen capture) ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} Picom compositor (fixes screen sharing) ${GREEN}✓${NC}"
    echo ""
    echo -e "${WHITE}🚀 Commands:${NC}"
    echo -e "  ${GREEN}bash ~/start-desktop.sh${NC}  - Start XFCE desktop"
    echo -e "  ${GREEN}bash ~/stop-desktop.sh${NC}   - Stop desktop"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT for Discord screen sharing:${NC}"
    echo -e "  1. Use ${WHITE}Firefox (Screen Share Fix)${NC} or ${WHITE}Chromium (Screen Share Fix)${NC}"
    echo -e "  2. When sharing, choose ${WHITE}\"Entire Screen\"${NC} (not application window)"
    echo -e "  3. If still not working, try: ${WHITE}sudo sysctl kernel.unprivileged_userns_clone=1${NC} (if rooted)"
    echo ""
}

# ============== MAIN ==============
main() {
    print_banner
    echo -e "${WHITE}This script will install a full Linux desktop with screen share fixes.${NC}"
    echo -e "${GRAY}Estimated time: 20-25 minutes (depends on internet).${NC}\n"
    check_storage
    echo ""
    echo -e "${YELLOW}Press ENTER to start or Ctrl+C to cancel...${NC}"
    read -s

    detect_device
    step_update
    step_repos
    step_x11
    step_desktop
    step_gpu
    step_audio        # Now PipeWire
    step_compositor   # NEW: Picom
    step_portals      # NEW: XDG portals
    step_browsers
    step_vscode
    step_dev_tools
    step_launchers
    step_shortcuts

    show_summary
}

main
