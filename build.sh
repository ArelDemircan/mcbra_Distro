#!/bin/bash
set -e

echo "=== mcbra_Distro Diyet Modu Basliyor ==="

# 1. Klasorleri hazırla
mkdir -p work/chroot work/iso/casper work/iso/boot/grub output

# 2. Temel sistemi indir
echo "Temel sistem indiriliyor..."
debootstrap --arch=amd64 noble work/chroot http://archive.ubuntu.com/ubuntu/

# 3. Chroot icinde hafif kurulum yap
echo "Sistem hafifletiliyor ve XFCE kuruluyor..."
cat <<EOF > work/chroot/install.sh
#!/bin/bash
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

# Depoları genişlet
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list

apt-get update

# Sadece EN GEREKLI paketler (--no-install-recommends boyutu cok dusurur)
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-generic casper xubuntu-core network-manager nano sudo

# Gereksiz dilleri ve dokumanları temizle
apt-get autoremove -y
apt-get clean
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
rm -rf /var/lib/apt/lists/*
umount /proc /sys /dev/pts
EOF

chmod +x work/chroot/install.sh
chroot work/chroot /install.sh
rm work/chroot/install.sh

# 4. Kernel kopyala
cp work/chroot/boot/vmlinuz-* work/iso/casper/vmlinuz
cp work/chroot/boot/initrd.img-* work/iso/casper/initrd

# 5. YUKSEK SIKISTIRMA (Dosyayı kuculten asıl sihir burası)
echo "XZ yontemiyle yuksek sikistirma yapiliyor (Bu biraz uzun surebilir ama dosya kuculecek)..."
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -comp xz -noappend

# 6. Boot ayarı
cat <<EOF > work/iso/boot/grub/grub.cfg
set timeout=5
menuentry "mcbra OS - Hafif Siklet" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
EOF

# 7. ISO olustur
grub-mkrescue -o output/mcbra-Distro.iso work/iso
