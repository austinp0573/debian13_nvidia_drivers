#!/usr/bin/env bash

# exit on non 0 status code
set -e

# prompt for sudo password
sudo -v

# best practice is everything shouldn't have root priviledges
# this ensures sudo is kept alive until the script is done
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &

# need "contrib" and "non-free" in sources.list
echo "adding contrib and non-free to sources.list"
sudo sed -i 's/ main$/ main contrib non-free/' /etc/apt/sources.list
echo "contrib and non-free successfully added"

# install linux-headers
echo "installing linux-headers"
sudo apt install linux-headers-'$(uname -r)'
echo "linux headers installed"

# needs to send the wget command with $distro as debian12
# why doesn't nvidia do more to ensure that the company with the vast market share of
# GPUs (and, at present, the largest market cap in the world) doesn't make a priority of 
# ensuring it's easy to get drivers for a foundational distro? Couldn't tell ya.
echo "setting $distro to debian12"
export distro="debian12"
echo "set"

# get keyring, then add it, then update
echo "wget keyring"
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/x86_64/cuda-keyring_1.1-1_all.deb
echo "dpkg keyring.deb"
sudo dpkg -i cuda-keyring_1.1-1_all.deb
echo "sudo apt updating"
sudo apt update
echo "installing cuda-drivers"
# compute only system would use the following
# sudo apt -V install nvidia-driver-cuda nvidia-kernel-dkms -y

# desktop only system
# sudo apt -V install nvidia-driver nvidia-kernel-dkms -y

sudo apt -V install cuda-drivers -y
echo "you're in business"

# need a reboot
echo "need a reboot, when you're back, run nvidia-smi, and if it works, fonzi-be-praised"
sleep 5s
sudo reboot