#!/data/data/com.termux/files/usr/bin/bash
##########################################################
# 🚀 LIGHTWEIGHT TERMUX DESKTOP INSTALLER
# Optimized: Faster • Smaller • Stable
##########################################################

TOTAL_STEPS=11
CURRENT_STEP=0
REQUIRED_SPACE_MB=2000

# COLORS
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${CYAN}═══ Step ${CURRENT_STEP}/${TOTAL_STEPS} ═══${NC}\n"
}

install_pkg() {
    pkg install -y "$1" > /dev/null 2>&1
    echo -e "${GREEN}✓${NC} $1 installed"
}

check_storage() {
    avail=$(df /data | awk 'NR==2 {print $4}')
    avail_mb=$((avail / 1024))
    if [ $avail_mb -lt $REQUIRED_SPACE_MB ]; then
        echo -e "${RED}Low storage: ${avail_mb}MB available${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Storage OK (${avail_mb}MB)${NC}"
    fi
}

detect_gpu() {
    GPU=$(getprop ro.hardware.egl)
    if [[ "$GPU" == *"adreno"* ]]; then
        DRIVER="mesa-vulkan-icd-freedreno"
        echo -e "${GREEN}Adreno GPU detected${NC}"
    else
        DRIVER="mesa-vulkan-icd-swrast"
        echo -e "${YELLOW}Using software rendering${NC}"
    fi
}

# STEPS

step_update() {
    update_progress
    pkg update -y && pkg upgrade -y > /dev/null 2>&1
}

step_repos() {
    update_progress
    install_pkg x11-repo
    install_pkg tur-repo
}

step_x11() {
    update_progress
    install_pkg termux-x11-nightly
}

step_desktop() {
    update_progress
    install_pkg xfce4
    install_pkg xfce4-terminal
    install_pkg thunar
}

step_gpu() {
    update_progress
    install_pkg mesa-zink
    install_pkg $DRIVER
    install_pkg vulkan-loader-android
}

step_audio() {
    update_progress
    install_pkg pulseaudio
}

step_apps() {
    update_progress
    install_pkg firefox
    install_pkg chromium
    install_pkg code-oss
}

step_dev() {
    update_progress
    install_pkg git
    install_pkg nodejs
    install_pkg python
    install_pkg clang
    install_pkg make
    install_pkg cmake
    install_pkg neovim
    install_pkg htop
}

step_configs() {
    update_progress

    mkdir -p ~/.config

    cat > ~/.config/gpu.conf << 'EOF'
export MESA_NO_ERROR=1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export MESA_GL_VERSION_OVERRIDE=4.6
EOF

    echo "source ~/.config/gpu.conf" >> ~/.bashrc
}

step_launcher() {
    update_progress

    cat > ~/start-desktop.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -9 -f termux.x11 2>/dev/null
pkill -9 -f xfce 2>/dev/null

pulseaudio --kill 2>/dev/null
pulseaudio --start

export DISPLAY=:0
termux-x11 :0 -ac &

sleep 3
startxfce4
EOF

    chmod +x ~/start-desktop.sh
}

step_shortcuts() {
    update_progress

    mkdir -p ~/Desktop

    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Type=Application
EOF

    cat > ~/Desktop/Chromium.desktop << 'EOF'
[Desktop Entry]
Name=Chromium
Exec=chromium-browser
Type=Application
EOF

    cat > ~/Desktop/VSCode.desktop << 'EOF'
[Desktop Entry]
Name=VS Code
Exec=code-oss --no-sandbox
Type=Application
EOF
}

finish() {
    echo -e "\n${GREEN}✅ INSTALL COMPLETE${NC}\n"
    echo -e "${WHITE}Run:${NC}"
    echo -e "${CYAN}bash ~/start-desktop.sh${NC}"
}

# MAIN

clear
echo -e "${CYAN}🚀 Starting Lightweight Installer...${NC}\n"

check_storage
detect_gpu

step_update
step_repos
step_x11
step_desktop
step_gpu
step_audio
step_apps
step_dev
step_configs
step_launcher
step_shortcuts

finish
