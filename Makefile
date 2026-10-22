TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

Spork_FILES = Tweak.xm SporkUI.m Executor.mm
# -I. tells the compiler to look in the current directory
Spork_CFLAGS = -fobjc-arc -std=c++17 -I. -Iluau/Common/include -Iluau/Compiler/include -Iluau/VM/include
Spork_LIBRARIES = substrate
Spork_LDFLAGS = ./libLuau.Compiler.a ./libLuau.VM.a

include $(THEOS_MAKE_PATH)/tweak.mk
