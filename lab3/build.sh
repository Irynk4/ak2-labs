#!/bin/bash
set -euo pipefail
WORK=${WORK:-/work}
PROJECT=${PROJECT:-/project}
OUT=$PROJECT/out
SRC=$WORK/src
BB=$SRC/busybox
KERNEL=$SRC/linux-stable
EABI=/opt/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin
GNU=/opt/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin
CORES=$(nproc)

mkdir -p "$OUT"
export ARCH=arm

echo "=== 1. ЗБІРКА U-BOOT ==="
cd "$SRC/u-boot"
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make am335x_evm_defconfig
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make -j"$CORES"

echo "=== 2. ЗБІРКА LINUX KERNEL (Прискорена) ==="
cd "$KERNEL"
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make omap2plus_defconfig
PATH=$EABI:$PATH CROSS_COMPILE='ccache arm-eabi-' make HOSTCC=gcc-9 -j"$CORES" zImage am335x-boneblack.dtb

echo "=== 3. ЗБІРКА BUSYBOX ==="
cd "$BB"
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make defconfig
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make -j"$CORES"
PATH=$GNU:$PATH CROSS_COMPILE='ccache arm-linux-gnueabihf-' make install

echo "=== 4. ФОРМУВАННЯ ТА ПАКУВАННЯ ROOTFS ==="
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
ln -sf bin/busybox _install/init
cp "$KERNEL/arch/arm/boot/zImage" _install/boot/
cp "$KERNEL/arch/arm/boot/dts/am335x-boneblack.dtb" _install/boot/

cd _install
find . | cpio -o -H newc | gzip > ../rootfs.cpio.gz
cd ..

cp "$KERNEL/arch/arm/boot/zImage" "$KERNEL/arch/arm/boot/dts/am335x-boneblack.dtb" "$BB/rootfs.cpio.gz" "$OUT/"
echo "=== ЗБІРКА УСПІШНО ЗАВЕРШЕНА ==="
