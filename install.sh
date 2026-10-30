#!/bin/bash
set -e

install_arch() {
	# Instalacija osnovnog sustava
	pacstrap -K /mnt base linux linux-firmware nvim networkmanager intel-ucode sudo

	# Generiranje fstab
	genfstab -U /mnt >> /mnt/etc/fstab

	# Konfiguracija instaliranog sustava
	arch-chroot /mnt /bin/bash <<'EOF'

	systemctl enable NetworkManager

	ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
	hwclock --systohc

	sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
	locale-gen

	echo "LANG=en_US.UTF-8" > /etc/locale.conf 
	
	echo "KEYMAP=croat" > /etc/vconsole.conf

	echo "arch" > /etc/hostname

	useradd -m -G wheel -s /bin/bash boris
EOF
		
	# Ovo je interaktivno pa treba biti izvan EOF
	arch-chroot /mnt passwd boris
	arch-chroot /mnt env EDITOR=nano visudo

	# systemdboot
	arch-chroot -S /mnt bootctl install
	
	# Root UUID
	ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)

	# Loader confiuration
	cat > /mnt/boot/loader/loader.conf <<EOF
	default arch.conf
	timeout 3
	editor no
EOF

	# Arch linux boot entry
	mkdir -p /mnt/boot/loader/entries

	cat > /mnt/boot/loader/entries/arch.conf <<EOF
	title Arch Linux
	linux /vmlinuz-linux
	initrd /initramfs-linux.img
	options root=UUID=$ROOT_UUID rw
EOF
}

install_arch
