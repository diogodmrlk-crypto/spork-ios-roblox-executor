TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Updated hooks.mm and exploit.mm
Spork_FILES = Tweak.xm SporkUI.mm memory.cpp hooks.mm exploit.mm

Spork_OBJCFLAGS = -fobjc-arc -I. -I./src
Spork_OBJCCFLAGS = -fobjc-arc -I. -I./src
Spork_CFLAGS = -fobjc-arc -I. -I./src

Spork_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
