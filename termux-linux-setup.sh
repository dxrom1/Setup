#!/data/data/com.termux/files/usr/bin/bash
##########################################################
#  🎨 ULTIMATE TERMUX DESKTOP INSTALLER
#  ------------------------------------------------------
#  Installs: Firefox | Chromium | VS Code |
#            Extra coding tools
#
#  With GPU acceleration, audio, and beautiful UI
##########################################################

# ============== CONFIG ==============
TOTAL_STEPS=11                     # Removed Blender & LibreOffice
CURRENT_STEP=0
REQUIRED_SPACE_MB=2500             # Less space needed without Blender/LibreOffice

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
    ║     🚀  TERMUX DEV + CREATOR INSTALLER  🚀          ║
    ║                                                      ║
    ║   🔥 Firefox   ●   🌐 Chromium   ●   💻 VS Code     ║
    ║   🛠️  GCC · Clang · Python · Node · Rust · more     ║
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
    install_pkg "tur-repo" "TUR Repository (extra GUI apps)"
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
    echo -e "  ${GREEN}✓${NC} GPU configured"
}

step_audio() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Setting up audio...${NC}\n"
    install_pkg "pulseaudio" "PulseAudio"
}

step_browsers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing web browsers...${NC}\n"
    install_pkg "firefox" "Firefox"
    install_pkg "chromium" "Chromium"
}

step_vscode() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing VS Code...${NC}\n"
    install_pkg "code-oss" "VS Code (Open Source)"
}

step_dev_tools() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Installing extra development tools...${NC}\n"
    
    # Compilers & build tools
    install_pkg "gcc" "GCC"
    install_pkg "clang" "Clang"
    install_pkg "make" "Make"
    install_pkg "cmake" "CMake"
    install_pkg "pkg-config" "pkg-config"
    
    # Languages & runtimes
    install_pkg "python" "Python"
    install_pkg "nodejs" "Node.js"
    install_pkg "rust" "Rust"
    
    # Debuggers & analyzers
    install_pkg "gdb" "GDB"
    install_pkg "valgrind" "Valgrind"
    install_pkg "strace" "strace"
    
    # Editors & utilities
    install_pkg "vim" "Vim"
    install_pkg "nano" "Nano"
    install_pkg "git" "Git"
    install_pkg "curl" "cURL"
    install_pkg "wget" "Wget"
    install_pkg "htop" "htop"
    install_pkg "neofetch" "Neofetch"
    
    # Version control extras
    install_pkg "subversion" "Subversion"
    
    echo -e "  ${GREEN}✓ Development tools installed${NC}"
}

step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}] Creating launcher scripts...${NC}\n"

    mkdir -p ~/.config
    cat > ~/.config/gpu.conf << 'EOF'
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export MESA_VK_WSI_PRESENT_MODE=immediate
EOF
    echo -e "  ${GREEN}✓${NC} GPU config created"

    if ! grep -q "gpu.conf" ~/.bashrc 2>/dev/null; then
        echo "source ~/.config/gpu.conf 2>/dev/null" >> ~/.bashrc
    fi

    cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "🚀 Starting Desktop Environment..."
source ~/.config/gpu.conf 2>/dev/null

# Kill old sessions
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null

# Audio
pulseaudio --kill 2>/dev/null
sleep 0.5
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📱 Open Termux-X11 app to see the desktop!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec startxfce4
EOF
    chmod +x ~/start-desktop.sh
    echo -e "  ${GREEN}✓${NC} Created ~/start-desktop.sh"

    cat > ~/stop-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
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

    # Chromium
    cat > ~/Desktop/Chromium.desktop << 'CHROMIUM'
[Desktop Entry]
Name=Chromium
Comment=Web Browser
Exec=chromium-browser
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
    echo -e "${GREEN}  ✅  INSTALLATION COMPLETE!  ✅${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}📦 Installed applications:${NC}"
    echo -e "  ${CYAN}•${NC} Firefox         ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} Chromium        ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} VS Code         ${GREEN}✓${NC}"
    echo -e "  ${CYAN}•${NC} Development tools (GCC, Clang, Python, Node, Rust, ...) ${GREEN}✓${NC}"
    echo ""
    echo -e "${WHITE}🚀 Commands:${NC}"
    echo -e "  ${GREEN}bash ~/start-desktop.sh${NC}  - Start XFCE desktop"
    echo -e "  ${GREEN}bash ~/stop-desktop.sh${NC}   - Stop desktop"
    echo ""
}

# ============== MAIN ==============
main() {
    print_banner
    echo -e "${WHITE}This script will install a full Linux desktop with the apps above.${NC}"
    echo -e "${GRAY}Estimated time: 15-20 minutes (depends on internet).${NC}\n"
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
    step_audio
    step_browsers
    step_vscode
    step_dev_tools
    step_launchers
    step_shortcuts

    show_summary
}

main
