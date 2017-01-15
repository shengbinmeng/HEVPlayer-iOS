#!/bin/bash

#
# Change these variables according to your system.
#
SDK_VERSION=8.3
IOS_ARCH=armv7
TOOLCHAIN=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk
PREFIX=./ios/${IOS_ARCH}
LENTHEVCDEC=./thirdparty/lenthevcdec

#
# Read the configure help carefully before you want to change the following options.
#
./configure \
	--prefix=${PREFIX} \
	--target-os=darwin \
	--arch=arm \
	--cpu=armv7-a \
	--enable-cross-compile \
	--cross-prefix=${TOOLCHAIN}/usr/bin/ \
	--cc=${TOOLCHAIN}/usr/bin/cc \
	--sysroot=${SYSROOT} \
	--extra-cflags="-O2 -I$LENTHEVCDEC/include -arch ${IOS_ARCH} -mfpu=neon -mfloat-abi=softfp" \
	--extra-ldflags="-L$LENTHEVCDEC/lib -arch ${IOS_ARCH} -isysroot ${SYSROOT}" \
	--enable-gpl \
	--enable-version3 \
	--enable-nonfree \
	--disable-doc \
	--disable-programs \
	--disable-debug \
	--enable-ffmpeg \
	--disable-avdevice \
	--disable-postproc \
	--disable-devices \
	--disable-filters \
	--disable-bsfs \
	--disable-zlib \
	--disable-bzlib \
	--disable-encoders \
	--disable-muxers \
	--enable-liblenthevcdec \