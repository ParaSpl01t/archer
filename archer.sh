#!/bin/bash

# Basic Variables
VERSION=0.0.1
BOOTMODE='bios'
[[ -d /sys/firmware/efi ]] && BOOTMODE='uefi'
CHROOT='arch-chroot /mnt'

# Base packages list
BASEPKGSLIST=(\
	'base on'\
	'base-devel on'\
	'git on'\
	'linux-zen on'\
	'linux-zen-headers on'\
	'linux-firmware on'\
	'linux off'\
	'linux-headers off'\
)

BASEPKGSLISTVAR=''

for i in ${!BASEPKGSLIST[@]}; do
  BASEPKGSLISTVAR+="$(($i+1)) ${BASEPKGSLIST[$i]} "
done

# GUI packages list
MAINPKGSLIST=(\
	'gnome-shell on'\
	'gdm on'\
	'nautilus on'\
	'kitty on'\
	'gnome-tweak-tool on'\
	'gnome-control-center on'\
	'xdg-user-dirs on'\
	'gnome-calculator on'\
	'gnome-keyring on'\
	'gnome-menus on'\
	'networkmanager on'\
	'file-roller on'\
	'eog on'\
	'nano on'\
)

MAINPKGSLISTVAR=''

for i in ${!MAINPKGSLIST[@]}; do
  MAINPKGSLISTVAR+="$(($i+1)) ${MAINPKGSLIST[$i]} "
done

# extra packages list
EXTRAPKGSLIST=(\
	'htop on'\
	'micro on'\
	'xclip on'\
	'reflector on'\
	'mpv on'\
	'gparted on'\
	'zip on'\
	'exa on'\
	'atool on'\
	'zsh on'\
	'zsh-autosuggestions on'\
	'zsh-syntax-highlighting on'\
	'grub on'\
	'grub-customizer on'\
	'dconf-editor on'\
	'noto-fonts on'\
	'noto-fonts-cjk on'\
	'noto-fonts-emoji on'\
	'noto-fonts-extra on'\
	'telegram-desktop on'\
	'firefox on'\
	'filemanager-actions on'\
	'gimp on'\
	'gtk-engine-murrine on'\
	'nvidia-prime on'\
	'npm on'\
	'nodejs on'\
	'broadcom-wl-dkms on'\
	'broadcom-wl off'\
	'jq on'\
	'fzf on'\
	'wget on'\
)

EXTRAPKGSLISTVAR=''

for i in ${!EXTRAPKGSLIST[@]}; do
  EXTRAPKGSLISTVAR+="$(($i+1)) ${EXTRAPKGSLIST[$i]} "
done

# AUR packages list
AURPKGSLIST=(\
	'visual-studio-code-bin on'\
	'google-chrome on'\
	'pfetch on'\
	'advcp on'\
	'xcursor-breeze on'\
	'pamac-aur on'\
	'archlinux-appstream-data-pamac on'\
)

AURPKGSLISTVAR=''

for i in ${!AURPKGSLIST[@]}; do
  AURPKGSLISTVAR+="$(($i+1)) ${AURPKGSLIST[$i]} "
done

# Install Dependencies
pacman -Sy dialog --noconfirm

# Welcome dialog
dialog --backtitle "archer.sh $VERSION" --title "ARCHER INSTALLATION" --msgbox "\nThis script will install a minimal GNOME setup with essential tools.\n\nBoot Mode : $BOOTMODE\n\nBefore Installation, make sure to partition and mount the disks and connect to Internet" 20 40
clear

# Enable parallel downloads
sed -i '/Parallel/s/^#//g' /etc/pacman.conf

# NTP
timedatectl set-ntp true

# Install base packages dialog
BASEPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Base Packages" --checklist "\nChoose base packages to install:" 20 40 6 $BASEPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a BASEPKGSARR <<< $BASEPKGS
BASEPKGSTOINSTALL=''
for element in "${BASEPKGSARR[@]}"
do
	IFS=' ' read -r -a basepgksfinal <<< ${BASEPKGSLIST[$(($element-1))]}
	BASEPKGSTOINSTALL+="${basepgksfinal[0]} "
done
clear

# Start base package installation
pacstrap /mnt $BASEPKGSTOINSTALL

#genfstab
genfstab -U /mnt >> /mnt/etc/fstab

# Enable paraller downloads in installation
sed -i '/Parallel/s/^#//g' /mnt/etc/pacman.conf

# Timezone dialog
TIMEZONE=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Timezone" --inputbox "\nEnter Timezone in Region/City format." 10 40 "Asia/Kolkata" --output-fd 1)
clear

# Set timezone
$CHROOT timedatectl set-timezone $TIMEZONE

# hwclock
$CHROOT hwclock --systohc

# Set language to en_US.utf-8
cp /etc/locale* /mnt/etc/

# Generate locale
$CHROOT locale-gen

# Hostname dialog
HOSTNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Hostname" --inputbox "\nEnter the name of this machine." 10 40 "archer" --output-fd 1)
clear

# Set hostname
echo $HOSTNAME > /mnt/etc/hostname
echo "127.0.0.1\tlocalhost\n::1\t\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /mnt/etc/hosts

# Username dialog
USERNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Username" --inputbox "\nEnter your username to login in this machine." 10 40 --output-fd 1)
clear

# Add user with wheel group
$CHROOT useradd -mG wheel $USERNAME

# Fetch paru-bin
$CHROOT git clone https://aur.archlinux.org/paru-bin.git /home/$USERNAME/paru

echo "Waiting for keypress..."
read

# Paru installation script
echo "#!/bin/bash" > install.sh
echo "cd /home/$USERNAME/paru" >> install.sh
echo "chown -R $USERNAME:$USERNAME /home/$USERNAME/paru" >> install.sh
echo "su $USERNAME -c 'makepkg -s'" >> install.sh
echo 'pacman -U $(\ls paru-bin*)' >> install.sh
cp install.sh /mnt/home/$USERNAME/paru/
$CHROOT chmod +x /home/$USERNAME/paru/install.sh
$CHROOT /home/$USERNAME/paru/install.sh


echo "Waiting..."
read

# Install GUI package dialog
MAINPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "GUI Packages" --checklist "\nChoose GUI packages to install:" 20 40 6 $MAINPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a MAINPKGSARR <<< $MAINPKGS
MAINPKGSTOINSTALL=''
for element in "${MAINPKGSARR[@]}"
do
	IFS=' ' read -r -a mainpgksfinal <<< ${MAINPKGSLIST[$(($element-1))]}
	MAINPKGSTOINSTALL+="${mainpgksfinal[0]} "
done
clear

# Start GUI package installation
$CHROOT pacman -S $MAINPKGSTOINSTALL

# Install extra package dialog
EXTRAPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Extra Packages" --checklist "\nChoose extra packages to install:" 20 40 6 $EXTRAPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a EXTRAPKGSARR <<< $EXTRAPKGS
EXTRAPKGSTOINSTALL=''
for element in "${EXTRAPKGSARR[@]}"
do
	IFS=' ' read -r -a extrapgksfinal <<< ${EXTRAPKGSLIST[$(($element-1))]}
	EXTRAPKGSTOINSTALL+="${extrapgksfinal[0]} "
done
clear

# Start extra package installation
$CHROOT pacman -S $EXTRAPKGSTOINSTALL

# Clenup paru
$CHROOT rm -rf /home/$USERNAME/paru

# Install AUR package dialog
AURPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "AUR Packages" --checklist "\nChoose AUR packages to install:" 20 40 6 $AURPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a AURPKGSARR <<< $AURPKGS
AURPKGSTOINSTALL=''
for element in "${AURPKGSARR[@]}"
do
	IFS=' ' read -r -a aurpgksfinal <<< ${AURPKGSLIST[$(($element-1))]}
	AURPKGSTOINSTALL+="${aurpgksfinal[0]} "
done
clear

# Create a script(run manually) to install selected AUR packages
echo "#!/bin/bash" > aur.sh
echo "kitty paru -S --skipreview $AURPKGSTOINSTALL" >> aur.sh
echo "rm /home/$USERNAME/aur.sh" >> aur.sh
cp aur.sh /mnt/home/$USERNAME/
$CHROOT chmod +x /home/$USERNAME/aur.sh

# AUR packages manual dialog
dialog --backtitle "archer.sh $VERSION" --title "AUR Packages" --msgbox "\nPlease manually run ~/aur.sh to install AUR packages on system reboot." 10 40
clear

# Create root password
$CHROOT echo "Create root password."
$CHROOT passwd
clear

# Create user password
$CHROOT echo "Create password for $USERNAME."
$CHROOT passwd $USERNAME
clear

# /etc/sudoers file edit dialog
dialog --backtitle "archer.sh $VERSION" --title "Edit /etc/sudoers" --yesno "\nPlease manually uncomment the '%wheel ALL=(ALL) ALL' line.\nDo you want to open the /etc/sudoers file?" 10 40
response=$?
clear
case $response in
   0)
      echo "EDITOR=nano visudo" > /mnt/visudotmp
	  $CHROOT /mnt bash visudotmp
	  rm /mnt/visudotmp
   ;;
esac

# GRUB disk location
GRUBDISK=$(dialog --backtitle "archer.sh $VERSION" --title "Install GRUB" --inputbox "\nEnter the disk to install grub on." 10 40 "/dev/sda" --output-fd 1)
clear

# Start GRUB installation
$CHROOT grub-install --target=i386-pc $GRUBDISK
$CHROOT grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
$CHROOT systemctl enable bluetooth
$CHROOT systemctl enable gdm
$CHROOT systemctl enable NetworkManager

# final dialog
dialog --backtitle "archer.sh $VERSION" --title "INSTALLATION FINISHED" --msgbox "\nYou can now reboot the machine." 10 40
