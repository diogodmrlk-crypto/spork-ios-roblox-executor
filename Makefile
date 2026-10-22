TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

Spork_FILES = Tweak.xm SporkUI.m Executor.mm
Spork_CFLAGS = -fobjc-arc -std=c++17 -I.
Spork_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
