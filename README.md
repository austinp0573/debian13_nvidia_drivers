# Debian13 Nvidia Proprietary Driver install script

 - quick script to get latest proprietary drivers on a fresh debian13 install
 - mostly adapted from [nvidia documentation](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/#debian)
- there is only an install method officially for debian12
-- this does install the debian12 version, I have run it like this since shortly after trixie was released without issue, however since this is technically the debian12 driver it could break something in someway, if you make money with the computer in question, you probably shouldn't do this

## Use

1. quick use
- copy and paste this in the terminal, press enter, enjoy

```bash
sudo wget -O - https://raw.githubusercontent.com/austinp0573/debian13_nvidia_drivers/main/debian13_nvidia_drivers.sh | bash
```

2. clone repo or wget

 ```bash
 git clone https://github.com/austinp0573/debian13_nvidia_drivers.git
 ```

 ```bash
 wget https://raw.githubusercontent.com/austinp0573/debian13_nvidia_drivers/main/debian13_nvidia_drivers.sh
 ```

3. change permissions

```bash
sudo chmod +x debian13_nvidia_drivers
```

4. run it

```bash
./debian13_nvidia_drivers
```

## Tested & Working
- at least as of this moment, it works
- I use proprietary drivers and I do lots of fresh debian installs, so I will update this if that changes

![nvidia-smi terminal output](./nvidia-smi.png)

&nbsp;

**466f724a616e6574**