#!/bin/bash

#
# Set the CPU architecture you want to build for.
#
IOS_ARCH=arm64

PREFIX=./ios-player/${IOS_ARCH}
TOOLCHAIN=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
if [ "$IOS_ARCH" = "i386" -o "$IOS_ARCH" = "x86_64" ]
then
	SYSROOT=$(xcrun -sdk iphonesimulator --show-sdk-path)
else
	SYSROOT=$(xcrun -sdk iphoneos --show-sdk-path)
fi

#
# Read the configure help carefully before you want to change the following options.
#
./configure \
	--prefix=${PREFIX} \
	--target-os=darwin \
	--arch=${IOS_ARCH} \
	--enable-cross-compile \
	--cross-prefix=${TOOLCHAIN}/usr/bin/ \
	--cc=${TOOLCHAIN}/usr/bin/cc \
	--sysroot=${SYSROOT} \
	--extra-cflags="-O2 -arch ${IOS_ARCH}" \
	--extra-ldflags="-arch ${IOS_ARCH} -isysroot ${SYSROOT} -L./qy265 -framework Foundation -framework UIKit -lqycommon -lqydecoder -lc++" \
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
	--enable-decoder=libqy265
