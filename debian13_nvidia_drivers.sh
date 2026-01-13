#!/usr/bin/env bash

# exit on non 0 status code
set -e

# an nvidia GPU is going to be crucial
if ! lspci | grep -i nvidia > /dev/null; then
    echo "ERROR: No NVIDIA GPU detected."
    exit 1
fi

# prompt for sudo password
sudo -v

# best practice is everything shouldn't have root priviledges
# this ensures sudo is kept alive until the script is done
cleanup() {
    # kill the background sudo keep-alive process
    if [[ -n "$sudo_pid" ]]; then
        kill "$sudo_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# start sudo keep-alive in background
while true; do 
    sudo -n true 2>/dev/null
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done &
sudo_pid=$!

while true; do
    echo "1) Rebuild drivers after kernel update"
    echo "2) Install NVIDIA drivers"
    read -p "Enter choice (1-2): " mode_choice
    
    case $mode_choice in
        1|2)
            break
            ;;
        *)
            echo "-----"
            echo "Invalid choice. Try again. To exit press ctrl + c"
            echo "-----"
            ;;
    esac
done

rebuild_drivers() {
    echo "Installing headers for current kernel and rebuilding NVIDIA drivers..."
    sudo apt install linux-headers-$(uname -r) -y
    sudo dpkg-reconfigure nvidia-kernel-dkms
    echo "Driver rebuild complete. Reboot to use the new kernel with NVIDIA drivers."
}

install_drivers() {
# ask if user wants to replace sources.list
echo "-------------------"
echo "/etc/apt/sources.list may not have contrib, non-free, and non-free-firmware already"
echo "These are necessary for NVIDIA drivers to be installed properly"
echo "If you would like to overwrite /etc/apt/sources.list with a the default"
echo "version with only those addition, you may do so using the following prompt"
echo "-------------------"
read -p "Replace /etc/apt/sources.list with known working version? (y/N): " sources_choice

if [[ "$sources_choice" =~ ^[Yy]$ ]]; then
    echo "Backing up and replacing /etc/apt/sources.list"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
    
    sudo tee /etc/apt/sources.list > /dev/null <<'EOF'
#deb cdrom:[Debian GNU/Linux 13.1.0 _Trixie_ - Official amd64 NETINST with firmware 20250906-10:22]/ trixie contrib main non-free-firmware

deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

# trixie-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware

# This system was installed using removable media other than
# CD/DVD/BD (e.g. USB stick, SD card, ISO image file).
# The matching "deb cdrom" entries were disabled at the end
# of the installation process.
# For information about how to configure apt package sources,
# see the sources.list(5) manual.
EOF
    
    echo "sources.list updated"
else
    echo "Skipping sources.list replacement"
fi

# install linux-headers
echo "installing linux-headers"
sudo apt install linux-headers-$(uname -r) -y
echo "linux headers installed"

# needs to send the wget command with $distro as debian12
# why doesn't nvidia do more to ensure that the company with the vast market share of
# GPUs (and, at present, the largest market cap in the world) doesn't make a priority of 
# ensuring it's easy to get drivers for a foundational distro? Couldn't tell ya.
echo "setting distro=debian12"
distro="debian12"
echo "distro set to $distro"

# get keyring, then add it, then update
echo "wget keyring"
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/cuda-keyring_1.1-1_all.deb
echo "dpkg keyring.deb"
sudo dpkg -i cuda-keyring_1.1-1_all.deb
echo "sudo apt updating"
sudo apt update

# 590 drivers broke things
echo "pinning to 580 drivers, 590 drivers resulted in meaningful issues"
sudo apt install nvidia-driver-pinning-580 -y

echo ""
echo "-------------------"
echo "Choose installation type:"
echo "1) Full CUDA drivers"
echo "2) Server/compute only (CUDA drivers only)"
echo "3) Desktop system (full drivers)"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "Installing full CUDA drivers..."
        sudo apt -V install cuda-drivers -y
        ;;
        
    2)
        echo "Installing compute-only drivers..."
        sudo apt -V install nvidia-driver-cuda nvidia-kernel-dkms -y
        ;;
    3)
      echo "Installing desktop drivers..."
        sudo apt -V install nvidia-driver nvidia-kernel-dkms -y
        ;;  
    *)
        echo "Invalid choice. Defaulting to full drivers."
        sudo apt -V install cuda-drivers -y
        ;;
esac

# need a reboot
echo "Installation complete!"
echo "---------------------------------------"
echo "IMPORTANT NOTE!"
echo "If you update your Linux Kernel - Rerun the script and use Option 1)"
echo "If you do not do this and you reboot your system, the nvidia-drivers"
echo "will not be built for your current/new kernel, and it will cause you a headache."
echo "---------------------------------------"
echo "A reboot is required to load the new drivers."
echo "After reboot, run 'nvidia-smi' to verify the installation."
echo ""
read -p "Reboot now? (y/N): " reboot_choice

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "rebooting in 5 seconds (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    echo "reboot manually to complete the process"
    echo "run 'sudo reboot' or restart your system."
fi
}

if [[ $mode_choice == "1" ]]; then
    rebuild_drivers
else
    install_drivers
fi