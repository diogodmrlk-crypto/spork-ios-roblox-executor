TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

Spork_FILES = Tweak.xm SporkUI.m Executor.mm
Spork_CFLAGS = -fobjc-arc -std=c++17 -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/luau/Common/include -I$(THEOS_PROJECT_DIR)/luau/Compiler/include -I$(THEOS_PROJECT_DIR)/luau/VM/include
Spork_LIBRARIES = substrate
Spork_LDFLAGS = ./libLuau.Compiler.a ./libLuau.VM.a

include $(THEOS_MAKE_PATH)/tweak.mk
