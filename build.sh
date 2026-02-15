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

# Depoları güncelle ve eski PC'ler için hafif paketleri kur
apt-get update
# casper: Canlı USB'den calistirmak icin sart
# xubuntu-core: XFCE'nin en hafif, gereksiz programlardan arindirilmis hali
# network-manager: Wi-Fi ve internet baglantisi icin
DEBIAN_FRONTEND=noninteractive apt-get install -y linux-generic casper xubuntu-core network-manager nano

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

# 5. Sistemi SquashFS ile sıkıştır (Bu işlem biraz sürer)
echo "Dosya sistemi sikistiriliyor..."
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -noappend

# 6. Başlatıcı (GRUB) ayarlarını yap
echo "Boot menusu ayarlaniyor..."
cat <<EOF > work/iso/boot/grub/grub.cfg
menuentry "mcbra OS - Eski PC'leri Ucuran Sistem" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
EOF

# 7. Her şeyi bir ISO dosyasına dönüştür
echo "ISO Dosyasi olusturuluyor..."
grub-mkrescue -o output/mcbra-Distro.iso work/iso

echo "=== Derleme Basariyla Tamamlandi! ==="
