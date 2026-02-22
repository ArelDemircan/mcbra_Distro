#!/bin/bash
set -e

echo "=== mcbra_Distro ULTIMATE (Installable Edition) Derleniyor ==="

# 1. Klasör Hazırlığı
mkdir -p work/chroot work/iso/casper work/iso/boot/grub output

# 2. Temel Sistem
debootstrap --arch=amd64 noble work/chroot http://archive.ubuntu.com/ubuntu/

# 3. Chroot Özelleştirme
cat << 'EOF' > work/chroot/install.sh
#!/bin/bash
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

# Depoları Güncelle
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list
apt-get update

# Firefox PPA Hazırlığı
DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
add-apt-repository -y ppa:mozillateam/ppa

# --- KRİTİK: KURULUM ARAÇLARI ---
# ubiquity: Kurulum sihirbazı, gparted: Disk bölümlendirme
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-generic casper xubuntu-core network-manager nano sudo curl \
    htop vlc mousepad plymouth plymouth-theme-ubuntu-text \
    ubiquity ubiquity-frontend-gtk ubiquity-slideshow-xubuntu gparted \
    locales keyboard-configuration tzdata firefox

# 1. Masaüstüne "Sistemi Kur" İkonu Ekleme
mkdir -p /etc/skel/Desktop
cat << 'UIEOF' > /etc/skel/Desktop/install.desktop
[Desktop Entry]
Name=mcbra OS'u Diske Kur
Comment=Sistemi HDD veya SSD'ye kalıcı olarak yükle
Exec=sudo ubiquity gtk_ui
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;
UIEOF
chmod +x /etc/skel/Desktop/install.desktop

# 2. MCBRA Logosu Ayarı (Plymouth)
update-alternatives --set default.plymouth /usr/share/plymouth/themes/ubuntu-text/ubuntu-text.plymouth
find /usr/share/plymouth/themes/ubuntu-text/ -type f -exec sed -i 's/Ubuntu/MCBRA/g' {} +
find /usr/share/plymouth/themes/ubuntu-text/ -type f -exec sed -i 's/ubuntu/mcbra/g' {} +
update-initramfs -u

# 3. Türkçe Dil ve Klavye
locale-gen tr_TR.UTF-8
update-locale LANG=tr_TR.UTF-8
ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

# Temizlik
apt-get autoremove -y && apt-get clean
rm -rf /var/lib/apt/lists/*
umount /proc /sys /dev/pts
EOF

chmod +x work/chroot/install.sh
chroot work/chroot /install.sh
rm work/chroot/install.sh

# 4. Kernel ve Sıkıştırma (XZ)
cp $(ls work/chroot/boot/vmlinuz-* | sort -V | tail -n 1) work/iso/casper/vmlinuz
cp $(ls work/chroot/boot/initrd.img-* | sort -V | tail -n 1) work/iso/casper/initrd
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -comp xz -noappend

# 5. GRUB Menüsü
cat << 'EOF' > work/iso/boot/grub/grub.cfg
set timeout=5
menuentry "mcbra OS - Kurulum ve Canli Mod" {
    linux /casper/vmlinuz boot=casper quiet splash locale=tr_TR.UTF-8 kbd-chooser/method=tr ---
    initrd /casper/initrd
}
EOF

# 6. ISO Oluştur
grub-mkrescue -o output/mcbra-Distro.iso work/iso
