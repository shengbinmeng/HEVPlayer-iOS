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
    --cpu=cortex-a9 \
    --enable-cross-compile \
    --cross-prefix=${TOOLCHAIN}/usr/bin/ \
    --cc=${TOOLCHAIN}/usr/bin/cc \
    --sysroot=${SYSROOT} \
    --extra-cflags="-O2 -I. -fno-PIC -arch ${IOS_ARCH} -mfpu=neon" \
    --extra-ldflags="-L. -arch ${IOS_ARCH} -isysroot ${SYSROOT}" \
    --enable-static \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --enable-ffmpeg \
    --disable-ffplay \
    --disable-ffserver \
    --disable-ffprobe \
    --disable-zlib \
    --disable-bzlib \
    --disable-iconv \
    --disable-avdevice \
    --disable-postproc \
    --disable-avresample \
    --disable-encoders \
    --disable-muxers \
    --disable-devices \
    --disable-filters \
    --disable-bsfs \
    --enable-liblenthevcdec \
    --enable-decoder=liblenthevchm91 \
    --enable-decoder=liblenthevchm10 \
    --enable-decoder=liblenthevc \