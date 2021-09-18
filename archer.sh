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
	'xdg-user-dirs'\
)

MAINPKGSLISTVAR=''

for i in ${!MAINPKGSLIST[@]}; do
  MAINPKGSLISTVAR+="$(($i+1)) ${MAINPKGSLIST[$i]} "
done

#welcome dialog
dialog --backtitle "archer.sh $VERSION" --title "ARCHER INSTALLATION" --msgbox "\nThis script will install a minimal GNOME setup with essential tools.\n\nBoot Mode : $BOOTMODE\n\nBefore Installation, make sure to partition and mount the disks and connect to Internet" 20 40


timedatectl set-ntp true

BASEPKGS=$(dialog --backtitle "archer.sh $VERSION" --title "Base Packages" --checklist "\nChoose base packages to install:" 20 40 6 $BASEPKGSLISTVAR --output-fd 1)
IFS=' ' read -r -a BASEPKGSARR <<< $BASEPKGS
BASEPKGSTOINSTALL=''
for element in "${BASEPKGSARR[@]}"
do
	IFS=' ' read -r -a basepgksfinal <<< ${BASEPKGSLIST[$(($element-1))]}
	BASEPKGSTOINSTALL+="${basepgksfinal[0]} "
done
pacstrap /mnt base $BASEPKGSTOINSTALL git

genfstab -U /mnt >> /mnt/etc/fstab

TIMEZONE=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Timezone" --inputbox "\nEnter Timezone in Region/City format." 10 40 "Asia/Kolkata" --output-fd 1)
$CHROOT timedatectl set-timezone $TIMEZONE

$CHROOT hwclock --systohc
cp /etc/locale* /mnt/etc/
$CHROOT locale-gen


HOSTNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Hostname" --inputbox "\nEnter the name of this machine." 10 40 "archer" --output-fd 1)
echo $HOSTNAME > /mnt/etc/hostname
echo "127.0.0.1\tlocalhost\n::1\t\t\tlocalhost\n127.0.1.1\t$HOSTNAME.localdomain\t$HOSTNAME" > /mnt/etc/hosts

USERNAME=$(dialog --backtitle "archer.sh $VERSION" --title "Enter Username" --inputbox "\nEnter your username to login in this machine." 10 40 --output-fd 1)

$CHROOT useradd $USERNAME

$CHROOT git clone https://aur.archlinux.org/paru-bin.git /home/$USERNAME/paru
echo "#!/bin/bash" > install.sh
echo "cd /home/$USERNAME/paru" >> install.sh
echo "chown -R $USERNAME:$USERNAME /home/$USERNAME/paru" >> install.sh
echo "su paradox -c 'makepkg -s'" >> install.sh
echo 'pacman -U $(\ls paru-bin*)' >> install.sh
cp install.sh /mnt/home/$USERNAME/paru/
$CHROOT chmod +x /home/$USERNAME/paru/install.sh
$CHROOT /home/$USERNAME/paru/install.sh
# $CHROOT clear
# $CHROOT passwd
# $CHROOT paswd $USERNAME

#GRUBDISK=$(dialog --backtitle "archer.sh $VERSION" --title "Install GRUB" --inputbox "\nEnter the disk to install grub on." 10 40 "/dev/sda" --output-fd 1)

#$CHROOT grub-install --target=i386-pc $GRUBDISK
#$CHROOT grub-mkconfig -o /boot/grub/grub.cfg
