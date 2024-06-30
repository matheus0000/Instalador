#!/bin/bash

############################################################  
# 1  # loadkeys br-abnt2                       # sda1 boot #
# 2  # locale-gen                              # sda2 swap #
# 3  # export LANG=pt_BR.UTF-8                 # sda3 ext4 #
############################################################

# Formatação e montagem das partições
# Formatar /boot, /swap, /ext4, etc....

mkfs.fat -F32 /dev/sda1  # BIOS boot partition
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
mount /dev/sda3 /mnt
ls /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mkdir /mnt/home  # opcional

# Montar partições formatadas
mount /dev/sda1 /mnt/boot/efi
mount /dev/sda3 /mnt/home

# Instalação básica do sistema
pacstrap /mnt base linux linux-firmware
echo "Installation will take approximately 10 minutes."
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab  # Verificar UUIDs
arch-chroot /mnt

########################################################################
# Configurações após chroot

# Configurar fuso horário
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Configurar localização e idioma
echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=pt_BR.UTF-8' > /etc/locale.conf
cat /etc/locale.conf  # Verificar arquivo de configuração

# Configurar layout do teclado
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf

##########################################################################
# Configurações de rede e hostname

echo 'pc01' > /etc/hostname

cat <<EOF >> /etc/hosts
127.0.0.1 localhost.localdomain localhost
::1 localhost.localdomain localhost
127.0.0.1 pc01.localdomain pc01
::1 pc01.localdomain pc01
EOF

############################################################################
# Configuração de usuário

passwd  # Defina uma senha para o usuário root
useradd -m -g users -G wheel nome_do_usuario  # Substitua "nome_do_usuario" pelo desejado
passwd nome_do_usuario  # Defina uma senha para o novo usuário

##############################################################################
# Instalação de pacotes adicionais

pacman -S dosfstools os-prober mtools
pacman -S network-manager-applet networkmanager
pacman -S wpa_supplicant wireless_tools dialog
pacman -S sudo

##############################################################################
# Configuração do sudo

EDITOR=nano visudo

##############################################################################
# Instalação do bootloader (UEFI)

pacman -S grub-efi-x86_64 efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=linux_grub_ufi --recheck
cp /usr/share/locale/en@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg

##############################################################################
# Finalização

exit
umount -R /mnt
reboot
