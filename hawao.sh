#!/usr/bin/env bash
# shellcheck disable=SC2199
# shellcheck source=/dev/null
#
# Copyright (C) 2020-22 UtsavBalar1231 <utsavbalar1231@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -

KBUILD_COMPILER_STRING=$($HOME/toolchains/proton-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
KBUILD_LINKER_STRING=$($HOME/toolchains/proton-clang/bin/ld.lld --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' | sed 's/(compatible with [^)]*)//')
export KBUILD_COMPILER_STRING
export KBUILD_LINKER_STRING

#
# Enviromental Variables
#

DATE=$(date '+%Y%m%d-%H%M')
DEVICE="RE54E4L1"

# Set our directory
OUT_DIR=out/

VERSION="AGNi-${DEVICE^^}-AOSP-${DATE}"

# Export Zip name
export ZIPNAME="${VERSION}.zip"

dts_source=arch/arm64/boot/dts/vendor/

START=$(date +"%s")

ARGS="ARCH=arm64 \
O=${OUT_DIR} \
CC=clang \
LD=ld.lld \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_COMPAT=arm-linux-gnueabi- "

# Set compiler Path
export PATH="$HOME/toolchains/proton-clang/bin:$PATH"
export LD_LIBRARY_PATH=${HOME}/toolchains/proton-clang/bin:$LD_LIBRARY_PATH

# Make defconfig
make O=${OUT_DIR} -j$(nproc --all) $ARGS vendor/ext_config/hawao-default.config
make -j$(nproc --all) ${ARGS}

#remove KSU from source after compiling
#git checkout drivers/Makefile &>/dev/null
#rm -rf KernelSU
#rm -rf drivers/kernelsu

git clone https://github.com/abhis699/AnyKernel3 AnyKernel3

find out/${dts_source} -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb.img

END=$(date +"%s")
DIFF=$((END - START))
zipname="$VERSION.zip"
if [ -f "out/arch/arm64/boot/Image" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb.img" ]; then
	cp out/arch/arm64/boot/Image AnyKernel3
	cp out/arch/arm64/boot/dtb.img AnyKernel3
	cp out/arch/arm64/boot/dtbo.img AnyKernel3
	rm -f *zip
	cd AnyKernel3
	sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
	zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo ""
	echo -e ${zipname} " is ready!"
	echo ""
else
	echo -e "\n Compilation Failed!"
fi
