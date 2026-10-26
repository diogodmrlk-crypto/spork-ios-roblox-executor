TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Find all Dobby C++ and C files recursively
DOBBY_SRC = $(shell find Dobby -name '*.cc' -o -name '*.c')

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)
Spork_CCFLAGS = -std=c++11 -fno-exceptions -fno-rtti -I./Dobby/include
Spork_OBJCFLAGS = -fobjc-arc -I./Dobby/include
Spork_OBJCCFLAGS = -fobjc-arc -I./Dobby/include

# Link the C++ standard library for Dobby
Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
