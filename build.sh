#!/bin/bash
set -e

echo "=== mcbra_Distro Derlemesi Basliyor ==="

# 1. Gerekli klasörleri oluştur
mkdir -p work/chroot
mkdir -p work/iso/casper
mkdir -p work/iso/boot/grub
mkdir -p output

# 2. Ubuntu'nun temel sistemini (24.04 Noble) indir
echo "Temel sistem indiriliyor..."
debootstrap --arch=amd64 noble work/chroot http://archive.ubuntu.com/ubuntu/

# 3. Sistemin içine (chroot) girip hafif arayüzü ve programları kur
echo "Eski PC'ler icin hafif paketler (XFCE) kuruluyor..."
cat <<EOF > work/chroot/install.sh
#!/bin/bash
# Sistemin sanal dizinlerini bagla
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

# DEPOLARI GENISLET (xubuntu-core'un bulunmasi icin Universe sart)
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list

apt-get update

# Paketleri kur (Eski PC'ler icin en hafif set)
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    linux-generic \
    casper \
    xubuntu-core \
    network-manager \
    net-tools \
    nano \
    sudo

# Temizlik yap (ISO boyutu kucuk olsun)
apt-get clean
rm -rf /var/lib/apt/lists/*
umount /proc /sys /dev/pts
EOF

# Hazirladigimiz scripti sistemin icinde calistir
chmod +x work/chroot/install.sh
chroot work/chroot /install.sh
rm work/chroot/install.sh

# 4. Çekirdek dosyalarını (Kernel) ISO klasörüne kopyala
echo "Kernel kopyalaniyor..."
cp work/chroot/boot/vmlinuz-* work/iso/casper/vmlinuz
cp work/chroot/boot/initrd.img-* work/iso/casper/initrd

# 5. Sistemi SquashFS ile sıkıştır
echo "Dosya sistemi sikistiriliyor (Bu vakit alabilir)..."
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -noappend

# 6. Başlatıcı (GRUB) ayarlarını yap
echo "Boot menusu ayarlaniyor..."
cat <<EOF > work/iso/boot/grub/grub.cfg
set default=0
set timeout=5

menuentry "mcbra OS - Eski PC Canavari" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}
EOF

# 7. Her şeyi bir ISO dosyasına dönüştür
echo "ISO Dosyasi olusturuluyor..."
grub-mkrescue -o output/mcbra-Distro.iso work/iso

echo "=== DERLEME BASARIYLA TAMAMLANDI! ==="
