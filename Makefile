TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

Spork_FILES = Tweak.xm SporkUI.m Executor.mm

# Flags for pure Objective-C files (SporkUI.m)
Spork_OBJCFLAGS = -fobjc-arc

# Flags for Objective-C++ files (Tweak.xm, Executor.mm)
# Added -Wno-error=c++17-extensions to suppress the static_assert warning
Spork_OBJCCFLAGS = -fobjc-arc -std=c++17 -Wno-error=c++17-extensions -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/luau/Common/include -I$(THEOS_PROJECT_DIR)/luau/Compiler/include -I$(THEOS_PROJECT_DIR)/luau/VM/include

Spork_LIBRARIES = substrate
Spork_LDFLAGS = $(THEOS_PROJECT_DIR)/libLuau.Compiler.a $(THEOS_PROJECT_DIR)/libLuau.VM.a

include $(THEOS_MAKE_PATH)/tweak.mk
