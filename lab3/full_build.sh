#!/bin/bash
set -euo pipefail
WORK=${WORK:-/work}
PROJECT=${PROJECT:-/project}
OUT=$PROJECT/out
SRC=$WORK/src
mkdir -p "$WORK/src" "$OUT"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates git vim tree curl wget ccache make bc bison flex \
  xz-utils file bzip2 kmod cpio build-essential gcc-9 g++-9 \
  libncurses-dev libssl-dev libgnutls28-dev libmpc-dev libmpfr-dev \
  libgmp-dev uuid-dev python3 python3-dev python3-setuptools \
  python3-pyelftools swig qemu-system-arm ipxe-qemu

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100

cd "$SRC"
if [ ! -d "/opt/gcc-arm-8.3-2019.03-x86_64-arm-eabi" ]; then
  curl -LO https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-eabi.tar.xz
  tar xJf gcc-arm-8.3-2019.03-x86_64-arm-eabi.tar.xz -C /opt/
  rm gcc-arm-8.3-2019.03-x86_64-arm-eabi.tar.xz
fi

if [ ! -d "/opt/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf" ]; then
  curl -LO https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
  tar xJf gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz -C /opt/
  rm gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
fi

[ ! -d "u-boot" ] && git clone --depth 1 --branch v2020.10 https://github.com/u-boot/u-boot.git u-boot
[ ! -d "linux-stable" ] && git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux-stable --depth 1 --branch linux-4.19.y
[ ! -d "busybox" ] && git clone https://git.busybox.net/busybox busybox --depth 1 --branch 1_31_stable

EABI=/opt/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin
GNU=/opt/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin
CORES=$(nproc)
export ARCH=arm

echo "=== 1. ЗБІРКА U-BOOT ==="
cd "$SRC/u-boot"
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make am335x_evm_defconfig
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make -j"$CORES"

echo "=== 2. ЗБІРКА LINUX KERNEL ==="
cd "$SRC/linux-stable"
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make multi_v7_defconfig
scripts/config --disable CONFIG_DRM_NOUVEAU
scripts/config --disable CONFIG_DRM_AMDGPU
scripts/config --disable CONFIG_DRM_RADEON
scripts/config --enable CONFIG_SERIAL_AMBA_PL011
scripts/config --enable CONFIG_SERIAL_AMBA_PL011_CONSOLE
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make HOSTCC=gcc-9 -j"$CORES" zImage am335x-boneblack.dtb

echo "=== 3. ЗБІРКА BUSYBOX ==="
cd "$SRC/busybox"
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make defconfig
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make -j"$CORES"
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make install

echo "=== 4. ФОРМУВАННЯ ROOTFS ==="
mkdir -p _install/{boot,dev,etc/init.d,lib,proc,root,sys/kernel/debug,tmp}
cat > _install/etc/init.d/rcS <<'RCSEOF'
#!/bin/sh
mount -t sysfs none /sys
mount -t proc none /proc
mount -t debugfs none /sys/kernel/debug
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
RCSEOF
chmod +x _install/etc/init.d/rcS
ln -sf bin/busybox _install/init 2>/dev/null || true
cp "$SRC/linux-stable/arch/arm/boot/zImage" _install/boot/
cp "$SRC/linux-stable/arch/arm/boot/dts/am335x-boneblack.dtb" _install/boot/

cd _install
find . | cpio -o -H newc | gzip > ../rootfs.cpio.gz
cd ..

cp "$SRC/linux-stable/arch/arm/boot/zImage" "$SRC/linux-stable/arch/arm/boot/dts/am335x-boneblack.dtb" "$SRC/busybox/rootfs.cpio.gz" "$OUT/"
echo "=== ЗБІРКА УСПІШНО ЗАВЕРШЕНА ==="
