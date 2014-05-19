#!/bin/bash

#
# change these variables according to your system
#
SDK_VERSION=7.0
IOS_ARCH=armv7

TOOLCHAIN=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk
PREFIX=./ios/${IOS_ARCH}

./configure \
    --prefix=${PREFIX} \
    --target-os=darwin \
    --arch=arm \
    --cpu=armv7-a \
    --enable-cross-compile \
    --cross-prefix=${TOOLCHAIN}/usr/bin/ \
    --cc=${TOOLCHAIN}/usr/bin/cc \
    --sysroot=${SYSROOT} \
    --extra-cflags="-O2 -I. -fno-PIC -arch ${IOS_ARCH} -mfpu=neon -mfloat-abi=softfp" \
    --extra-ldflags="-L. -arch ${IOS_ARCH} -isysroot ${SYSROOT}" \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --disable-doc \
    --disable-programs \
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