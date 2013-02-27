# Makefile

#toolchain
CC = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc
LD = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ld
AS = "gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc"

#config
ARCH = ARM
SYSROOT = /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk
LENT_SRC_ROOT = .
CFLAGS = -I$(LENT_SRC_ROOT) --sysroot=$(SYSROOT) -w -O2 -arch armv7 -mfpu=neon -mfloat-abi=softfp
LDFLAGS = -arch armv7 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk

#source files
SRCS =  $(LENT_SRC_ROOT)/decoder/cabac.c \
		$(LENT_SRC_ROOT)/decoder/codec.c \
		$(LENT_SRC_ROOT)/decoder/dsp.c \
		$(LENT_SRC_ROOT)/decoder/hevc_cabac.c \
		$(LENT_SRC_ROOT)/decoder/hevc_deblock.c \
		$(LENT_SRC_ROOT)/decoder/hevc_frame.c \
		$(LENT_SRC_ROOT)/decoder/hevc_mvpred.c \
		$(LENT_SRC_ROOT)/decoder/hevc_pred.c \
		$(LENT_SRC_ROOT)/decoder/hevc_ref.c \
		$(LENT_SRC_ROOT)/decoder/hevc_refs.c \
		$(LENT_SRC_ROOT)/decoder/hevc_sao.c \
		$(LENT_SRC_ROOT)/decoder/hevc_thread.c \
		$(LENT_SRC_ROOT)/decoder/hevc.c \
		$(LENT_SRC_ROOT)/utils/mem.c \
		$(LENT_SRC_ROOT)/utils/log.c \
		$(LENT_SRC_ROOT)/utils/math.c \
		$(LENT_SRC_ROOT)/utils/sink.c
		 
ifeq ($(ARCH), X86)
SRCS += $(LENT_SRC_ROOT)/decoder/arch/x86/dsp_x86.c \
		$(LENT_SRC_ROOT)/decoder/arch/x86/deblock_x86.c \
		$(LENT_SRC_ROOT)/decoder/arch/x86/pred_x86.c
endif
ifeq ($(ARCH), ARM)
SRCS +=
endif

#object files
OBJS += $(SRCS:%.c=%.o)

#targets
default:lib-static

lib-static:$(OBJS)
	$(AR) crv liblentoid-dec.a $(OBJS)

.PHONY: clean
clean:
	rm -f $(LENT_SRC_ROOT)/decoder/*.o $(LENT_SRC_ROOT)/utils/*.o *.a