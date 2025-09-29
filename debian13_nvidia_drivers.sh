#!/usr/bin/env bash

# exit on non 0 status code
set -e

# prompt for sudo password
sudo -v

# best practice is everything shouldn't have root priviledges
# this ensures sudo is kept alive until the script is done
cleanup() {
    # Kill the background sudo keep-alive process
    if [[ -n "$sudo_pid" ]]; then
        kill "$sudo_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Start sudo keep-alive in background
while true; do 
    sudo -n true 2>/dev/null
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done &
sudo_pid=$!

# need "contrib" and "non-free" in sources.list
echo "adding contrib and non-free to sources.list"
sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
echo "contrib and non-free successfully added"

# install linux-headers
echo "installing linux-headers"
sudo apt install linux-headers-$(uname -r)
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
echo "Choose installation type:"
echo "1) Desktop system (full drivers)"
echo "2) Server/compute only (CUDA drivers only)"
echo "3) Full CUDA toolkit and drivers"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "Installing desktop drivers..."
        sudo apt -V install nvidia-driver nvidia-kernel-dkms -y
        ;;
    2)
        echo "Installing compute-only drivers..."
        sudo apt -V install nvidia-driver-cuda nvidia-kernel-dkms -y
        ;;
    3)
        echo "Installing full CUDA drivers..."
        sudo apt -V install cuda-drivers -y
        ;;
    *)
        echo "Invalid choice. Defaulting to desktop drivers."
        sudo apt -V install nvidia-driver nvidia-kernel-dkms -y
        ;;
esac

# need a reboot
echo "Installation complete!"
echo "A reboot is required to load the new drivers."
echo "After reboot, run 'nvidia-smi' to verify the installation."
echo ""
read -p "Reboot now? (y/N): " reboot_choice

if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    echo "Please reboot manually when convenient."
    echo "Run 'sudo reboot' or restart your system."
fi