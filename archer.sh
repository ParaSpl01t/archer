#!/bin/bash
VERSION=0.0.1
BOOTMODE='bios'
[[ -d /sys/firmware/efi ]] && BOOTMODE='uefi'
CHROOT='arch-chroot /mnt'
BASEPKGSLIST=(\
	'base on'\
	'base-devel on'\
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
	'nano on'\
)

MAINPKGSLISTVAR=''

for i in ${!MAINPKGSLIST[@]}; do
  MAINPKGSLISTVAR+="$(($i+1)) ${MAINPKGSLIST[$i]} "
done


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


AURPKGSLIST=(\
	'visual-studio-code-bin on'\
	'google-chrome on'\
	'pfetch on'\
	'advcp on'\
)

AURPKGSLISTVAR=''

for i in ${!AURPKGSLIST[@]}; do
  AURPKGSLISTVAR+="$(($i+1)) ${AURPKGSLIST[$i]} "
done

#welcome dialog
dialog --backtitle "archer.sh $VERSION" --title "ARCHER INSTALLATION" --msgbox "\nThis script will install a minimal GNOME setup with essential tools.\n\nBoot Mode : $BOOTMODE\n\nBefore Installation, make sure to partition and mount the disks and connect to Internet" 20 40

sed -i '/Parallel/s/^#//g' /etc/pacman.conf
timedatectl set-ntp true

BASEPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Base Packages" --checklist "\nChoose base packages to install:" 20 40 6 $BASEPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a BASEPKGSARR <<< $BASEPKGS
BASEPKGSTOINSTALL=''
for element in "${BASEPKGSARR[@]}"
do
	IFS=' ' read -r -a basepgksfinal <<< ${BASEPKGSLIST[$(($element-1))]}
	BASEPKGSTOINSTALL+="${basepgksfinal[0]} "
done
pacstrap /mnt $BASEPKGSTOINSTALL git

genfstab -U /mnt >> /mnt/etc/fstab

sed -i '/Parallel/s/^#//g' /mnt/etc/pacman.conf

TIMEZONE=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Timezone" --inputbox "\nEnter Timezone in Region/City format." 10 40 "Asia/Kolkata" --output-fd 1)
$CHROOT timedatectl set-timezone $TIMEZONE

$CHROOT hwclock --systohc
cp /etc/locale* /mnt/etc/
$CHROOT locale-gen


HOSTNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Hostname" --inputbox "\nEnter the name of this machine." 10 40 "archer" --output-fd 1)
echo $HOSTNAME > /mnt/etc/hostname
echo "127.0.0.1\tlocalhost\n::1\t\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /mnt/etc/hosts

USERNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Username" --inputbox "\nEnter your username to login in this machine." 10 40 --output-fd 1)

$CHROOT useradd -mG wheel $USERNAME

$CHROOT git clone https://aur.archlinux.org/paru-bin.git /home/$USERNAME/paru
echo "#!/bin/bash" > install.sh
echo "cd /home/$USERNAME/paru" >> install.sh
echo "chown -R $USERNAME:$USERNAME /home/$USERNAME/paru" >> install.sh
echo "su paradox -c 'makepkg -s'" >> install.sh
echo 'pacman -U $(\ls paru-bin*)' >> install.sh
cp install.sh /mnt/home/$USERNAME/paru/
$CHROOT chmod +x /home/$USERNAME/paru/install.sh
$CHROOT /home/$USERNAME/paru/install.sh

MAINPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Base Packages" --checklist "\nChoose base packages to install:" 20 40 6 $MAINPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a MAINPKGSARR <<< $MAINPKGS
MAINPKGSTOINSTALL=''
for element in "${MAINPKGSARR[@]}"
do
	IFS=' ' read -r -a mainpgksfinal <<< ${MAINPKGSLIST[$(($element-1))]}
	MAINPKGSTOINSTALL+="${mainpgksfinal[0]} "
done
$CHROOT su $USERNAME -c "paru -S --noconfirm --skipreview $MAINPKGSTOINSTALL"


EXTRAPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Base Packages" --checklist "\nChoose base packages to install:" 20 40 6 $EXTRAPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a EXTRAPKGSARR <<< $EXTRAPKGS
EXTRAPKGSTOINSTALL=''
for element in "${EXTRAPKGSARR[@]}"
do
	IFS=' ' read -r -a extrapgksfinal <<< ${EXTRAPKGSLIST[$(($element-1))]}
	EXTRAPKGSTOINSTALL+="${extrapgksfinal[0]} "
done
$CHROOT paru -S --noconfirm --skipreview $EXTRAPKGSTOINSTALL

$CHROOT echo "Create root password."
$CHROOT passwd
$CHROOT echo "Create password for $USERNAME."
$CHROOT passwd $USERNAME

GRUBDISK=$(dialog --backtitle "archer.sh $VERSION" --title "Install GRUB" --inputbox "\nEnter the disk to install grub on." 10 40 "/dev/sda" --output-fd 1)

$CHROOT grub-install --target=i386-pc $GRUBDISK
$CHROOT grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable bluetooth
systemctl enable gdm
systemctl enable NetworkManager

dialog --backtitle "archer.sh $VERSION" --title "INSTALLATION FINISHED" --msgbox "\nYou can now reboot the machine." 10 40
