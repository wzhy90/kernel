#!/bin/bash

# If you've got the toolchain in a non-standard location
# (e.g., youre using Linaro), uncomment the next line
# and specify the toolchain's root here
#CROSS_COMPILE=../linaro-toolchain

# Kernel tag/label. Mostly for showing off :P
LOCALVERSION="Kernel755-OpenSEMC-derived"

# ==================================
# Hands off from this point forward!
# ==================================

MKELF=scripts/mkelf.py

[ -z "$TOOLCHAIN_PATH" ] && TOOLCHAIN_PATH=/usr

export LOCALVERSION="-"`echo $LOCALVERSION`
export CROSS_COMPILE=$TOOLCHAIN_PATH/bin/arm-linux-gnueabihf-
export ARCH=arm

if [ ! -e ${CROSS_COMPILE}gcc ]; then
	echo "ARM(hf) GCC not found on the configured TOOLCHAIN PATH."
	echo "Make sure the you've installed the ARM GCC Cross-compiler"
	echo "on path: $TOOLCHAIN_PATH"
	echo "Bailing out..."
	echo
	exit 1;
fi

echo "LOCALVERSION="$LOCALVERSION
echo "CROSS_COMPILE="$CROSS_COMPILE
echo "ARCH="$ARCH

echo
echo "Building Kernel755..."

DATE_START=$(date +"%s")

rm -rf ./output
mkdir -p ./output/image-parts

if [ ! -e .config ]; then
	make defconfig opensemc_k755_defconfig
fi

echo
make -j3
brc=$?
echo

if [ $brc -ne 0 ]; then
	echo "Kernel build failed. Aborting..."
	echo
	exit 1;
fi

echo "Generating flashable boot image..."

cp arch/arm/boot/zImage output/image-parts/
cp firmware/qcom/RPM.bin output/image-parts/

cd opensemc-ramdisk
find . | cpio -o -H newc | gzip > ../output/image-parts/ramdisk.cpio.gz
cd ..

python $MKELF -o output/kernel.elf output/image-parts/zImage@0x40208000 output/image-parts/ramdisk.cpio.gz@0x41500000,ramdisk output/image-parts/RPM.bin@0x20000,rpm

DATE_END=$(date +"%s")
echo
DIFF=$(($DATE_END - $DATE_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
