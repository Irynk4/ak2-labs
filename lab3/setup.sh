#!/bin/bash
set -euo pipefail
WORK=${WORK:-/work}
PROJECT=${PROJECT:-/project}
LOGS=$PROJECT/logs
mkdir -p "$WORK/src" "$LOGS"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates git vim tree curl wget ccache make bc bison flex \
  xz-utils file bzip2 kmod cpio build-essential gcc-9 g++-9 \
  libncurses-dev libssl-dev libgnutls28-dev libmpc-dev libmpfr-dev \
  libgmp-dev uuid-dev python3 python3-dev python3-setuptools \
  python3-pyelftools swig qemu-system-arm

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 100
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 100
update-alternatives --set gcc /usr/bin/gcc-9
update-alternatives --set g++ /usr/bin/g++-9

cd "$WORK/src"
wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-eabi.tar.xz | tar xJ -C /opt/
wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz | tar xJ -C /opt/

git clone https://source.denx.de/u-boot/u-boot.git u-boot
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux-stable --depth 1 --branch linux-4.19.y
git clone https://git.busybox.net/busybox busybox --depth 1 --branch 1_31_stable
