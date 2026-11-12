#!/bin/bash
PROJECT=${PROJECT:-/project}
OUT=$PROJECT/out

qemu-system-arm \
  -kernel "$OUT/zImage" \
  -initrd "$OUT/rootfs.cpio.gz" \
  -machine virt \
  -net none \
  -nographic \
  -m 512 \
  -append "root=/dev/ram0 rw console=ttyAMA0,115200 earlycon"
