TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Compile Dobby's core source files
DOBBY_SRC = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux)/')

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)
Spork_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti -I./Dobby/include -I./Dobby/source -I./Dobby/external
Spork_OBJCFLAGS = -fobjc-arc -I./Dobby/include -I./Dobby/source -I./Dobby/external
Spork_OBJCCFLAGS = -fobjc-arc -I./Dobby/include -I./Dobby/source -I./Dobby/external
Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
