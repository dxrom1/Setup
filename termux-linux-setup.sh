#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  Termux PROOT Linux Setup Script
#  
#  Features:
#  - Installs Debian via proot-distro
#  - Choice of Desktop Environment (XFCE, LXQt, MATE, KDE)
#  - Smart GPU acceleration detection (Turnip/Zink)
#  - VS Code, Firefox, Chromium, Opera inside proot
#  - Python & Flask demo
#  - Windows App Support (Wine)
#######################################################

# ============== CONFIGURATION ==============
TOTAL_STEPS=13
CURRENT_STEP=0
DE_CHOICE="1"
DE_NAME="XFCE4"
DISTRO="debian"          # Change to "ubuntu" if preferred

# ============== COLORS ==============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
WHITE='\033[1;37m'; GRAY='\033[0;90m'; NC='\033[0m'; BOLD='\033[1m'

# ============== PROGRESS FUNCTIONS ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="*"; done
    BAR+="${GRAY}"
    for ((i=0; i<EMPTY; i++)); do BAR+="-"; done
    BAR+="${NC}"
    echo ""
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo -e "${CYAN}  OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r  [*] ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    wait $pid
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        printf "\r  [+] ${message}                    \n"
    else
        printf "\r  [-] ${message} ${RED}(failed)${NC}     \n"
    fi
    return $exit_code
}

install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    (pkg install -y $pkg > /dev/null 2>&1) &
    spinner $! "Installing ${name}..."
}

run_in_proot() {
    local cmd=$1
    local message=$2
    (proot-distro login $DISTRO -- bash -c "$cmd" > /dev/null 2>&1) &
    spinner $! "$message"
}

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    -------------------------------------------
         Termux PROOT Linux Setup Script       
         (Full Linux with VS Code & Browsers)  
    -------------------------------------------
BANNER
    echo -e "${NC}"
    echo ""
}

# ============== DEVICE & USER SELECTION ==============
setup_environment() {
    echo -e "${PURPLE}[*] Detecting your device...${NC}\n"
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  [*] Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  [*] Android: ${WHITE}${ANDROID_VERSION}${NC}"
    
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" =~ (samsung|oneplus|xiaomi) ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  [*] GPU: ${WHITE}Adreno (Qualcomm) - Hardware Acceleration Supported${NC}"
    else
        GPU_DRIVER="zink_native"
        echo -e "  [*] GPU: ${WHITE}Non-Adreno - Zink Native Vulkan${NC}"
        echo -e "${YELLOW}      [!] WARNING: Your device may not fully support advanced GPU acceleration.${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Please choose your Desktop Environment:${NC}"
    echo -e "  ${WHITE}1) XFCE4${NC}       (Recommended - Fast, Customizable)"
    echo -e "  ${WHITE}2) LXQt${NC}        (Ultra lightweight)"
    echo -e "  ${WHITE}3) MATE${NC}        (Classic UI, moderately heavy)"
    echo -e "  ${WHITE}4) KDE Plasma${NC}  (Very heavy, requires strong GPU/RAM)"
    echo ""
    while true; do
        read -p "Enter number (1-4) [default: 1]: " DE_INPUT
        DE_INPUT=${DE_INPUT:-1}
        if [[ "$DE_INPUT" =~ ^[1-4]$ ]]; then
            DE_CHOICE="$DE_INPUT"
            break
        else
            echo "Invalid input. Please enter 1, 2, 3, or 4."
        fi
    done
    
    case $DE_CHOICE in
        1) DE_NAME="XFCE4";;
        2) DE_NAME="LXQt";;
        3) DE_NAME="MATE";;
        4) DE_NAME="KDE Plasma";;
    esac
    
    echo -e "\n${GREEN}[+] Selected: ${DE_NAME}.${NC}"
    sleep 2
}

# ============== STEP 1: UPDATE TERMUX ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Updating Termux packages...${NC}\n"
    (pkg update -y > /dev/null 2>&1) &
    spinner $! "Updating package lists..."
    (pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Upgrading installed packages..."
}

# ============== STEP 2: INSTALL TERMUX DEPENDENCIES ==============
step_deps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Termux dependencies...${NC}\n"
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository"
    install_pkg "proot-distro" "PROOT Distro"
    install_pkg "termux-x11-nightly" "Termux-X11 Server"
    install_pkg "pulseaudio" "PulseAudio"
    install_pkg "wget" "Wget"
}

# ============== STEP 3: INSTALL PROOT DISTRO (DEBIAN) ==============
step_proot() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DISTRO^} via proot...${NC}\n"
    
    if proot-distro list | grep -q installed.*$DISTRO; then
        echo -e "  [+] ${DISTRO^} already installed."
    else
        (proot-distro install $DISTRO > /dev/null 2>&1) &
        spinner $! "Downloading and installing ${DISTRO^} (this may take a while)..."
    fi
}

# ============== STEP 4: CREATE USER INSIDE PROOT ==============
step_user() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Setting up user account inside proot...${NC}\n"
    
    USERNAME="user"
    
    proot-distro login $DISTRO -- id $USERNAME &>/dev/null || {
        proot-distro login $DISTRO -- bash -c "
            apt update -qq && apt install -y sudo adduser >/dev/null 2>&1
            adduser --disabled-password --gecos '' $USERNAME >/dev/null 2>&1
            echo '$USERNAME:$USERNAME' | chpasswd >/dev/null 2>&1
            usermod -aG sudo $USERNAME >/dev/null 2>&1
            echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
        " > /dev/null 2>&1 &
        spinner $! "Creating user '$USERNAME' (password: $USERNAME)..."
    }
}

# ============== STEP 5: INSTALL DESKTOP (INSIDE PROOT) ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DE_NAME} Desktop inside proot...${NC}\n"
    
    local desktop_pkgs=""
    case $DE_CHOICE in
        1) desktop_pkgs="xfce4 xfce4-terminal thunar mousepad xfce4-whiskermenu-plugin plank" ;;
        2) desktop_pkgs="lxqt qterminal pcmanfm-qt featherpad" ;;
        3) desktop_pkgs="mate mate-terminal mate-tweak plank" ;;
        4) desktop_pkgs="plasma-desktop konsole dolphin" ;;
    esac
    
    run_in_proot "DEBIAN_FRONTEND=noninteractive apt install -y $desktop_pkgs" "Installing desktop packages"
}

# ============== STEP 6: INSTALL GPU DRIVERS (INSIDE PROOT) ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing GPU acceleration...${NC}\n"
    
    run_in_proot "apt install -y mesa-utils mesa-zink" "Installing Mesa Zink"
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        run_in_proot "apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:armhf 2>/dev/null || true" "Installing Turnip drivers"
    fi
}

# ============== STEP 7: INSTALL BROWSERS (INSIDE PROOT) ==============
step_browsers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing browsers (Firefox, Chromium, Opera)...${NC}\n"
    
    run_in_proot "apt install -y firefox-esr chromium" "Installing Firefox & Chromium"
    
    # Opera requires adding repo
    run_in_proot "
        wget -qO- https://deb.opera.com/archive.key | gpg --dearmor | tee /usr/share/keyrings/opera.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free' > /etc/apt/sources.list.d/opera.list
        apt update -qq
        apt install -y opera-stable
    " "Installing Opera"
}

# ============== STEP 8: INSTALL VS CODE (INSIDE PROOT) ==============
step_vscode() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing VS Code...${NC}\n"
    
    local arch=$(proot-distro login $DISTRO -- uname -m)
    if [[ "$arch" == "aarch64" ]]; then
        vscode_arch="arm64"
    else
        vscode_arch="armhf"
    fi
    
    run_in_proot "
        wget -q --show-progress -O /tmp/code.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$vscode_arch
        dpkg -i /tmp/code.deb || true
        apt install -f -y
        rm /tmp/code.deb
    " "Installing VS Code"
}

# ============== STEP 9: INSTALL PYTHON & FLASK DEMO ==============
step_python() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Python environment...${NC}\n"
    
    run_in_proot "apt install -y python3 python3-pip" "Installing Python"
    
    proot-distro login $DISTRO --user $USERNAME -- bash -c "
        pip3 install flask >/dev/null 2>&1
        mkdir -p ~/demo_python
        cat > ~/demo_python/app.py << 'EOF'
from flask import Flask, render_template_string
app = Flask(__name__)
@app.route('/')
def hello():
    return render_template_string('''
    <html>
        <body style="background:#1e1e1e;color:#00ff00;font-family:monospace;text-align:center;padding:50px">
            <h1>Hardware Accelerated Linux</h1>
            <h3>This Python server runs inside proot on Android!</h3>
        </body>
    </html>
    ''')
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
    " > /dev/null 2>&1 &
    spinner $! "Creating Flask demo in ~/demo_python"
}

# ============== STEP 10: INSTALL WINE (OPTIONAL) ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Windows compatibility (Wine)...${NC}\n"
    
    run_in_proot "
        dpkg --add-architecture i386
        apt update -qq
        apt install -y wine wine32 wine64
    " "Installing Wine (may take a while)"
}

# ============== STEP 11: CREATE LAUNCH SCRIPTS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating start/stop scripts...${NC}\n"
    
    # Determine desktop command
    case $DE_CHOICE in
        1) START_CMD="startxfce4" ;;
        2) START_CMD="startlxqt" ;;
        3) START_CMD="mate-session" ;;
        4) START_CMD="startplasma-x11" ;;
    esac
    
    # Start script – FIXED VERSION
    cat > ~/start-linux.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "[*] Starting ${DE_NAME} in proot..."
echo ""

# Kill any existing Termux:X11 and audio sessions
echo "[*] Cleaning up old sessions..."
pkill -f termux-x11 2>/dev/null
pulseaudio --kill 2>/dev/null
sleep 2

# Start PulseAudio
echo "[*] Starting audio server..."
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# Start Termux:X11 on display :1 (avoid conflict with existing X servers)
echo "[*] Starting X11 server on display :1..."
termux-x11 :1 -ac &
sleep 3
export DISPLAY=:1

echo "-----------------------------------------------"
echo "  [*] Open Termux:X11 app to view desktop!"
echo "-----------------------------------------------"

# Wait for X server to be ready
timeout 10s bash -c "while ! xset q &>/dev/null; do sleep 0.5; done" || echo "  [!] X server may not be ready, but continuing..."

# Launch proot with desktop
proot-distro login $DISTRO --user $USERNAME -- bash -c "
    export DISPLAY=:1
    export PULSE_SERVER=tcp:127.0.0.1:4713
    export MESA_NO_ERROR=1
    export MESA_GL_VERSION_OVERRIDE=4.6
    export GALLIUM_DRIVER=zink
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    dbus-launch --exit-with-session $START_CMD
"
EOF
    chmod +x ~/start-linux.sh
    
    # Stop script
    cat > ~/stop-linux.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping ${DE_NAME}..."
pkill -f termux-x11 2>/dev/null
pkill -f pulseaudio 2>/dev/null
proot-distro login $DISTRO -- pkill -u $USERNAME 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-linux.sh
    
    echo -e "  [+] Created ~/start-linux.sh and ~/stop-linux.sh"
}

# ============== STEP 12: CREATE DESKTOP SHORTCUTS (INSIDE PROOT) ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating desktop shortcuts inside proot...${NC}\n"
    
    proot-distro login $DISTRO --user $USERNAME -- bash -c "
        mkdir -p ~/Desktop
        cat > ~/Desktop/Firefox.desktop << 'FIREFOX'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
FIREFOX
        cat > ~/Desktop/Chromium.desktop << 'CHROMIUM'
[Desktop Entry]
Name=Chromium
Exec=chromium
Icon=chromium
Type=Application
CHROMIUM
        cat > ~/Desktop/Opera.desktop << 'OPERA'
[Desktop Entry]
Name=Opera
Exec=opera
Icon=opera
Type=Application
OPERA
        cat > ~/Desktop/VS\ Code.desktop << 'VSCODE'
[Desktop Entry]
Name=VS Code
Exec=/usr/share/code/code
Icon=code
Type=Application
VSCODE
        cat > ~/Desktop/Terminal.desktop << 'TERM'
[Desktop Entry]
Name=Terminal
Exec=$(which xfce4-terminal 2>/dev/null || which qterminal 2>/dev/null || which mate-terminal 2>/dev/null || which konsole 2>/dev/null)
Icon=utilities-terminal
Type=Application
TERM
        chmod +x ~/Desktop/*.desktop 2>/dev/null
    " > /dev/null 2>&1 &
    spinner $! "Adding shortcuts to Desktop"
}

# ============== STEP 13: FINAL CLEANUP ==============
step_cleanup() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Final cleanup...${NC}\n"
    
    run_in_proot "apt autoremove -y" "Removing unnecessary packages"
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
    ---------------------------------------------------------------
             [*]  INSTALLATION COMPLETE!  [*]                      
    ---------------------------------------------------------------
COMPLETE
    echo -e "${NC}"
    
    echo -e "${WHITE}[*] Your ${DE_NAME} environment is ready inside a ${DISTRO^} proot.${NC}"
    echo -e "${CYAN}[*] Installed Software:${NC}"
    echo "    - VS Code, Firefox, Chromium, Opera"
    echo "    - Python (Flask demo in ~/demo_python)"
    echo "    - Wine (Windows app compatibility)"
    echo "    - GPU Hardware Acceleration (if supported)"
    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "${WHITE}[*] TO START THE DESKTOP:${NC}  ${GREEN}./start-linux.sh${NC}"
    echo -e "${WHITE}[*] TO STOP THE DESKTOP:${NC}   ${GREEN}./stop-linux.sh${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo ""
    echo -e "${BLUE}Note: Make sure you have the Termux:X11 app installed from GitHub/F-Droid.${NC}"
}

# ============== MAIN ==============
main() {
    show_banner
    setup_environment
    
    step_update
    step_deps
    step_proot
    step_user
    step_desktop
    step_gpu
    step_browsers
    step_vscode
    step_python
    step_wine
    step_launchers
    step_shortcuts
    step_cleanup
    
    show_completion
}

main    echo ""
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo -e "${CYAN}  OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r  [*] ${message} ${CYAN}${spin:$i:1}${NC}  "
        sleep 0.1
    done
    wait $pid
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        printf "\r  [+] ${message}                    \n"
    else
        printf "\r  [-] ${message} ${RED}(failed)${NC}     \n"
    fi
    return $exit_code
}

install_pkg() {
    local pkg=$1
    local name=${2:-$pkg}
    (pkg install -y $pkg > /dev/null 2>&1) &
    spinner $! "Installing ${name}..."
}

run_in_proot() {
    local cmd=$1
    local message=$2
    (proot-distro login $DISTRO -- bash -c "$cmd" > /dev/null 2>&1) &
    spinner $! "$message"
}

# ============== BANNER ==============
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    -------------------------------------------
         Termux PROOT Linux Setup Script       
         (Full Linux with VS Code & Browsers)  
    -------------------------------------------
BANNER
    echo -e "${NC}"
    echo ""
}

# ============== DEVICE & USER SELECTION ==============
setup_environment() {
    echo -e "${PURPLE}[*] Detecting your device...${NC}\n"
    
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    
    echo -e "  [*] Device: ${WHITE}${DEVICE_BRAND} ${DEVICE_MODEL}${NC}"
    echo -e "  [*] Android: ${WHITE}${ANDROID_VERSION}${NC}"
    
    if [[ "$GPU_VENDOR" == *"adreno"* ]] || [[ "$DEVICE_BRAND" =~ (samsung|oneplus|xiaomi) ]]; then
        GPU_DRIVER="freedreno"
        echo -e "  [*] GPU: ${WHITE}Adreno (Qualcomm) - Hardware Acceleration Supported${NC}"
    else
        GPU_DRIVER="zink_native"
        echo -e "  [*] GPU: ${WHITE}Non-Adreno - Zink Native Vulkan${NC}"
        echo -e "${YELLOW}      [!] WARNING: Your device may not fully support advanced GPU acceleration.${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Please choose your Desktop Environment:${NC}"
    echo -e "  ${WHITE}1) XFCE4${NC}       (Recommended - Fast, Customizable)"
    echo -e "  ${WHITE}2) LXQt${NC}        (Ultra lightweight)"
    echo -e "  ${WHITE}3) MATE${NC}        (Classic UI, moderately heavy)"
    echo -e "  ${WHITE}4) KDE Plasma${NC}  (Very heavy, requires strong GPU/RAM)"
    echo ""
    while true; do
        read -p "Enter number (1-4) [default: 1]: " DE_INPUT
        DE_INPUT=${DE_INPUT:-1}
        if [[ "$DE_INPUT" =~ ^[1-4]$ ]]; then
            DE_CHOICE="$DE_INPUT"
            break
        else
            echo "Invalid input. Please enter 1, 2, 3, or 4."
        fi
    done
    
    case $DE_CHOICE in
        1) DE_NAME="XFCE4";;
        2) DE_NAME="LXQt";;
        3) DE_NAME="MATE";;
        4) DE_NAME="KDE Plasma";;
    esac
    
    echo -e "\n${GREEN}[+] Selected: ${DE_NAME}.${NC}"
    sleep 2
}

# ============== STEP 1: UPDATE TERMUX ==============
step_update() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Updating Termux packages...${NC}\n"
    (pkg update -y > /dev/null 2>&1) &
    spinner $! "Updating package lists..."
    (pkg upgrade -y > /dev/null 2>&1) &
    spinner $! "Upgrading installed packages..."
}

# ============== STEP 2: INSTALL TERMUX DEPENDENCIES ==============
step_deps() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Termux dependencies...${NC}\n"
    install_pkg "x11-repo" "X11 Repository"
    install_pkg "tur-repo" "TUR Repository"
    install_pkg "proot-distro" "PROOT Distro"
    install_pkg "termux-x11-nightly" "Termux-X11 Server"
    install_pkg "pulseaudio" "PulseAudio"
    install_pkg "wget" "Wget"
}

# ============== STEP 3: INSTALL PROOT DISTRO (DEBIAN) ==============
step_proot() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DISTRO^} via proot...${NC}\n"
    
    if proot-distro list | grep -q installed.*$DISTRO; then
        echo -e "  [+] ${DISTRO^} already installed."
    else
        (proot-distro install $DISTRO > /dev/null 2>&1) &
        spinner $! "Downloading and installing ${DISTRO^} (this may take a while)..."
    fi
}

# ============== STEP 4: CREATE USER INSIDE PROOT ==============
step_user() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Setting up user account inside proot...${NC}\n"
    
    # Default username: 'user'
    USERNAME="user"
    
    # Check if user exists; if not, create
    proot-distro login $DISTRO -- id $USERNAME &>/dev/null || {
        proot-distro login $DISTRO -- bash -c "
            apt update -qq && apt install -y sudo adduser >/dev/null 2>&1
            adduser --disabled-password --gecos '' $USERNAME >/dev/null 2>&1
            echo '$USERNAME:$USERNAME' | chpasswd >/dev/null 2>&1
            usermod -aG sudo $USERNAME >/dev/null 2>&1
            echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
        " > /dev/null 2>&1 &
        spinner $! "Creating user '$USERNAME' (password: $USERNAME)..."
    }
}

# ============== STEP 5: INSTALL DESKTOP (INSIDE PROOT) ==============
step_desktop() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing ${DE_NAME} Desktop inside proot...${NC}\n"
    
    local desktop_pkgs=""
    case $DE_CHOICE in
        1) desktop_pkgs="xfce4 xfce4-terminal thunar mousepad xfce4-whiskermenu-plugin plank" ;;
        2) desktop_pkgs="lxqt qterminal pcmanfm-qt featherpad" ;;
        3) desktop_pkgs="mate mate-terminal mate-tweak plank" ;;
        4) desktop_pkgs="plasma-desktop konsole dolphin" ;;
    esac
    
    run_in_proot "DEBIAN_FRONTEND=noninteractive apt install -y $desktop_pkgs" "Installing desktop packages"
}

# ============== STEP 6: INSTALL GPU DRIVERS (INSIDE PROOT) ==============
step_gpu() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing GPU acceleration...${NC}\n"
    
    run_in_proot "apt install -y mesa-utils mesa-zink" "Installing Mesa Zink"
    if [ "$GPU_DRIVER" == "freedreno" ]; then
        run_in_proot "apt install -y mesa-vulkan-drivers mesa-vulkan-drivers:armhf 2>/dev/null || true" "Installing Turnip drivers"
    fi
}

# ============== STEP 7: INSTALL BROWSERS (INSIDE PROOT) ==============
step_browsers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing browsers (Firefox, Chromium, Opera)...${NC}\n"
    
    run_in_proot "apt install -y firefox-esr chromium" "Installing Firefox & Chromium"
    
    # Opera requires adding repo
    run_in_proot "
        wget -qO- https://deb.opera.com/archive.key | gpg --dearmor | tee /usr/share/keyrings/opera.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free' > /etc/apt/sources.list.d/opera.list
        apt update -qq
        apt install -y opera-stable
    " "Installing Opera"
}

# ============== STEP 8: INSTALL VS CODE (INSIDE PROOT) ==============
step_vscode() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing VS Code...${NC}\n"
    
    # Detect architecture inside proot
    local arch=$(proot-distro login $DISTRO -- uname -m)
    if [[ "$arch" == "aarch64" ]]; then
        vscode_arch="arm64"
    else
        vscode_arch="armhf"
    fi
    
    run_in_proot "
        wget -q --show-progress -O /tmp/code.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$vscode_arch
        dpkg -i /tmp/code.deb || true
        apt install -f -y
        rm /tmp/code.deb
    " "Installing VS Code"
}

# ============== STEP 9: INSTALL PYTHON & FLASK DEMO ==============
step_python() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Python environment...${NC}\n"
    
    run_in_proot "apt install -y python3 python3-pip" "Installing Python"
    
    # Create Flask demo inside user's home
    proot-distro login $DISTRO --user $USERNAME -- bash -c "
        pip3 install flask >/dev/null 2>&1
        mkdir -p ~/demo_python
        cat > ~/demo_python/app.py << 'EOF'
from flask import Flask, render_template_string
app = Flask(__name__)
@app.route('/')
def hello():
    return render_template_string('''
    <html>
        <body style="background:#1e1e1e;color:#00ff00;font-family:monospace;text-align:center;padding:50px">
            <h1>Hardware Accelerated Linux</h1>
            <h3>This Python server runs inside proot on Android!</h3>
        </body>
    </html>
    ''')
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
    " > /dev/null 2>&1 &
    spinner $! "Creating Flask demo in ~/demo_python"
}

# ============== STEP 10: INSTALL WINE (OPTIONAL) ==============
step_wine() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Installing Windows compatibility (Wine/Box64)...${NC}\n"
    
    # Wine in Debian proot is tricky; use i386 architecture
    run_in_proot "
        dpkg --add-architecture i386
        apt update -qq
        apt install -y wine wine32 wine64
    " "Installing Wine (may take a while)"
}

# ============== STEP 11: CREATE LAUNCH SCRIPTS ==============
step_launchers() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating start/stop scripts...${NC}\n"
    
    # Determine desktop command
    case $DE_CHOICE in
        1) START_CMD="startxfce4" ;;
        2) START_CMD="startlxqt" ;;
        3) START_CMD="mate-session" ;;
        4) START_CMD="startplasma-x11" ;;
    esac
    
    # Start script
    cat > ~/start-linux.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash
echo ""
echo "[*] Starting ${DE_NAME} in proot..."
echo ""

# Kill old sessions
pkill -f termux-x11 2>/dev/null
pulseaudio --kill 2>/dev/null
sleep 1

# Start audio
pulseaudio --start --exit-idle-time=-1
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null
export PULSE_SERVER=127.0.0.1

# Start X11
termux-x11 :0 -ac &
sleep 3
export DISPLAY=:0

echo "-----------------------------------------------"
echo "  [*] Open Termux-X11 app to view desktop!"
echo "-----------------------------------------------"

# Launch proot with desktop
proot-distro login $DISTRO --user $USERNAME -- bash -c "
    export DISPLAY=:0
    export PULSE_SERVER=tcp:127.0.0.1:4713
    export MESA_NO_ERROR=1
    export MESA_GL_VERSION_OVERRIDE=4.6
    export GALLIUM_DRIVER=zink
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    dbus-launch --exit-with-session $START_CMD
"
EOF
    chmod +x ~/start-linux.sh
    
    # Stop script
    cat > ~/stop-linux.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping ${DE_NAME}..."
pkill -f termux-x11 2>/dev/null
pkill -f pulseaudio 2>/dev/null
proot-distro login $DISTRO -- pkill -u $USERNAME 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-linux.sh
    
    echo -e "  [+] Created ~/start-linux.sh and ~/stop-linux.sh"
}

# ============== STEP 12: CREATE DESKTOP SHORTCUTS (INSIDE PROOT) ==============
step_shortcuts() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Creating desktop shortcuts inside proot...${NC}\n"
    
    proot-distro login $DISTRO --user $USERNAME -- bash -c "
        mkdir -p ~/Desktop
        cat > ~/Desktop/Firefox.desktop << 'FIREFOX'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
FIREFOX
        cat > ~/Desktop/Chromium.desktop << 'CHROMIUM'
[Desktop Entry]
Name=Chromium
Exec=chromium
Icon=chromium
Type=Application
CHROMIUM
        cat > ~/Desktop/Opera.desktop << 'OPERA'
[Desktop Entry]
Name=Opera
Exec=opera
Icon=opera
Type=Application
OPERA
        cat > ~/Desktop/VS\ Code.desktop << 'VSCODE'
[Desktop Entry]
Name=VS Code
Exec=/usr/share/code/code
Icon=code
Type=Application
VSCODE
        cat > ~/Desktop/Terminal.desktop << 'TERM'
[Desktop Entry]
Name=Terminal
Exec=$(which xfce4-terminal 2>/dev/null || which qterminal 2>/dev/null || which mate-terminal 2>/dev/null || which konsole 2>/dev/null)
Icon=utilities-terminal
Type=Application
TERM
        chmod +x ~/Desktop/*.desktop 2>/dev/null
    " > /dev/null 2>&1 &
    spinner $! "Adding shortcuts to Desktop"
}

# ============== STEP 13: FINAL CLEANUP ==============
step_cleanup() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] Final cleanup...${NC}\n"
    
    run_in_proot "apt autoremove -y" "Removing unnecessary packages"
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    echo -e "${GREEN}"
    cat << 'COMPLETE'
    ---------------------------------------------------------------
             [*]  INSTALLATION COMPLETE!  [*]                      
    ---------------------------------------------------------------
COMPLETE
    echo -e "${NC}"
    
    echo -e "${WHITE}[*] Your ${DE_NAME} environment is ready inside a ${DISTRO^} proot.${NC}"
    echo -e "${CYAN}[*] Installed Software:${NC}"
    echo "    - VS Code, Firefox, Chromium, Opera"
    echo "    - Python (Flask demo in ~/demo_python)"
    echo "    - Wine (Windows app compatibility)"
    echo "    - GPU Hardware Acceleration (if supported)"
    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "${WHITE}[*] TO START THE DESKTOP:${NC}  ${GREEN}./start-linux.sh${NC}"
    echo -e "${WHITE}[*] TO STOP THE DESKTOP:${NC}   ${GREEN}./stop-linux.sh${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo ""
    echo -e "${BLUE}Note: Make sure you have the Termux:X11 app installed from GitHub/F-Droid.${NC}"
}

# ============== MAIN ==============
main() {
    show_banner
    setup_environment
    
    step_update
    step_deps
    step_proot
    step_user
    step_desktop
    step_gpu
    step_browsers
    step_vscode
    step_python
    step_wine
    step_launchers
    step_shortcuts
    step_cleanup
    
    show_completion
}

main
