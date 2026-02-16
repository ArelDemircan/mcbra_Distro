#!/bin/bash
set -e

echo "=== mcbra_Distro Kişiselleştirme Başlıyor ==="

# 1. Klasörler
mkdir -p work/chroot work/iso/casper work/iso/boot/grub output

# 2. Temel Sistem (Noble)
debootstrap --arch=amd64 noble work/chroot http://archive.ubuntu.com/ubuntu/

# 3. Chroot İçinde Özelleştirme
cat <<EOF > work/chroot/install.sh
#!/bin/bash
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

# Depolar
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-generic casper xubuntu-core network-manager nano sudo curl

# --- KIŞISELLEŞTIRME BAŞLANGICI ---

# 1. Terminal Karşılama Mesajı (MOTD)
echo "echo '======================================'" >> /etc/skel/.bashrc
echo "echo '   mcbra OS - Eski PC Canavarı v1.0   '" >> /etc/skel/.bashrc
echo "echo '   Hoş geldin! Sistem Kullanıma Hazır. '" >> /etc/skel/.bashrc
echo "echo '======================================'" >> /etc/skel/.bashrc

# 2. Varsayılan Duvar Kağıdını Değiştirmek İçin Hazırlık
mkdir -p /usr/share/backgrounds/mcbra
# Buraya internetten örnek bir teknoloji resmi çekelim (Sen sonra değiştirebilirsin)
curl -o /usr/share/backgrounds/mcbra/wallpaper.jpg https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1000&auto=format&fit=crop

# --- KIŞISELLEŞTIRME BITIŞI ---

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
umount /proc /sys /dev/pts
EOF

chmod +x work/chroot/install.sh
chroot work/chroot /install.sh
rm work/chroot/install.sh

# 4. Kernel ve ISO Oluşturma (Aynı adımlar)
cp work/chroot/boot/vmlinuz-* work/iso/casper/vmlinuz
cp work/chroot/boot/initrd.img-* work/iso/casper/initrd
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -comp xz -noappend

cat <<EOF > work/iso/boot/grub/grub.cfg
set timeout=5
menuentry "mcbra OS - Ozel Surum" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
EOF

grub-mkrescue -o output/mcbra-Distro.iso work/iso
