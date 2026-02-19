#!/bin/bash
set -e

echo "=== mcbra_Distro ULTIMATE Surum Derleniyor ==="

# 1. Klasörler
mkdir -p work/chroot work/iso/casper work/iso/boot/grub output

# 2. Temel Sistem (Noble)
echo "1. Temel Sistem Indiriliyor..."
debootstrap --arch=amd64 noble work/chroot http://archive.ubuntu.com/ubuntu/

# 3. Chroot İçinde Özelleştirme ve Kurulum
echo "2. Sistem icine giriliyor, programlar ve gorseller ekleniyor..."
cat << 'EOF' > work/chroot/install.sh
#!/bin/bash
mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

# Depolar
echo "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list

apt-get update

# Temel XFCE + AĞ + EKSTRA PROGRAMLAR + DİL PAKETLERİ EKLENDİ
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-generic casper xubuntu-core network-manager nano sudo curl \
    htop vlc mousepad ristretto pavucontrol thunar-archive-plugin xz-utils \
    locales keyboard-configuration tzdata

# --- TÜRKÇE DİL, SAAT VE KLAVYE AYARLARI ---
locale-gen tr_TR.UTF-8
update-locale LANG=tr_TR.UTF-8 LC_ALL=tr_TR.UTF-8
ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

cat << 'KEYEOF' > /etc/default/keyboard
XKBMODEL="pc105"
XKBLAYOUT="tr"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
KEYEOF

# --- KİŞİSELLEŞTİRME BAŞLANGICI ---

# 1. Renkli Terminal Karşılama Mesajı
cat << 'INNEREOF' >> /etc/skel/.bashrc
echo -e "\e[1;36m====================================================\e[0m"
echo -e "\e[1;32m      mcbra OS - Eski PC Canavari (Ultimate v1)\e[0m"
echo -e "\e[1;36m====================================================\e[0m"
INNEREOF

# 2. Havalı Duvar Kağıdı İndirme ve XFCE Varsayılanı Yapma
mkdir -p /usr/share/backgrounds/mcbra
mkdir -p /usr/share/xfce4/backdrops/
curl -o /usr/share/backgrounds/mcbra/wallpaper.jpg https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop

# İndirdiğimiz duvar kağıdını Xubuntu'nun varsayılan dosyası gibi gösteriyoruz
ln -sf /usr/share/backgrounds/mcbra/wallpaper.jpg /usr/share/xfce4/backdrops/xubuntu-wallpaper.png

# --- KİŞİSELLEŞTİRME BİTİŞİ ---

# Temizlik (ISO boyutunu şişirmemek için)
apt-get autoremove -y
apt-get clean
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
rm -rf /var/lib/apt/lists/*
umount /proc /sys /dev/pts
EOF

chmod +x work/chroot/install.sh
chroot work/chroot /install.sh
rm work/chroot/install.sh

# 4. Kernel kopyala (Daha güvenli yöntem)
echo "3. Kernel kopyalaniyor..."
cp $(ls work/chroot/boot/vmlinuz-* | sort -V | tail -n 1) work/iso/casper/vmlinuz
cp $(ls work/chroot/boot/initrd.img-* | sort -V | tail -n 1) work/iso/casper/initrd

# 5. Yüksek Sıkıştırma (XZ)
echo "4. Maksimum Sikistirma Uygulaniyor (Sabriniz icin tesekkurler)..."
mksquashfs work/chroot work/iso/casper/filesystem.squashfs -comp xz -noappend

# 6. Boot ayarı (Kullanıcı adı, dil ve auto-login parametreleri eklendi)
echo "5. GRUB Boot Ayarlari Yapilandiriliyor..."
cat << 'EOF' > work/iso/boot/grub/grub.cfg
set timeout=5
menuentry "mcbra OS - Ultimate Edition (Live)" {
    linux /casper/vmlinuz boot=casper username=mcbra hostname=mcbra-os locale=tr_TR.UTF-8 kbd-chooser/method=tr console-setup/layoutcode=tr quiet splash ---
    initrd /casper/initrd
}
EOF

# 7. ISO oluştur
echo "6. ISO Dosyasi Birlestiriliyor..."
grub-mkrescue -o output/mcbra-Distro.iso work/iso
echo "=== ISLEM BASARIYLA TAMAMLANDI ==="
