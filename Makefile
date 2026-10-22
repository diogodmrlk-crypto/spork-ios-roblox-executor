TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Changed SporkUI.m to SporkUI.mm
Spork_FILES = Tweak.xm SporkUI.mm Executor.mm

# Flags for pure Objective-C files (if any)
Spork_OBJCFLAGS = -fobjc-arc

# Flags for Objective-C++ files (Tweak.xm, SporkUI.mm, Executor.mm)
Spork_OBJCCFLAGS = -fobjc-arc -std=c++17 -Wno-error=c++17-extensions -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/luau/Common/include -I$(THEOS_PROJECT_DIR)/luau/Compiler/include -I$(THEOS_PROJECT_DIR)/luau/VM/include

Spork_LIBRARIES = substrate
Spork_LDFLAGS = $(THEOS_PROJECT_DIR)/libLuau.Compiler.a $(THEOS_PROJECT_DIR)/libLuau.VM.a

include $(THEOS_MAKE_PATH)/tweak.mk
