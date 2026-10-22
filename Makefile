TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

Spork_FILES = Tweak.xm SporkUI.mm Executor.mm

# Flags for pure Objective-C files
Spork_OBJCFLAGS = -fobjc-arc

# Include paths for the Compiler and VM (headers only)
Spork_OBJCCFLAGS = -fobjc-arc -std=c++17 -Wno-error=c++17-extensions -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/luau/Ast/include -I$(THEOS_PROJECT_DIR)/luau/Common/include -I$(THEOS_PROJECT_DIR)/luau/Compiler/include -I$(THEOS_PROJECT_DIR)/luau/Bytecode/include -I$(THEOS_PROJECT_DIR)/luau/VM/include

Spork_LIBRARIES = substrate

# Link ONLY the compiler libraries. NO VM.
Spork_LDFLAGS = -Wl,-undefined,dynamic_lookup $(THEOS_PROJECT_DIR)/libLuau.Compiler.a $(THEOS_PROJECT_DIR)/libLuau.Ast.a $(THEOS_PROJECT_DIR)/libLuau.Bytecode.a $(THEOS_PROJECT_DIR)/libLuau.Common.a

include $(THEOS_MAKE_PATH)/tweak.mk
