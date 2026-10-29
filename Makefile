TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm exploit.mm hooks.mm memory.cpp execution.cpp

# Luau upstream (compile dentro do tweak)
Luau_FILES = $(wildcard luau/VM/src/*.cpp) $(wildcard luau/Compiler/src/*.cpp)
Spork_FILES += $(Luau_FILES)

Spork_CFLAGS = -fobjc-arc -std=c++17 \
               -I$(THEOS_PROJECT_DIR)/luau \
               -I$(THEOS_PROJECT_DIR)/luau/VM/include \
               -I$(THEOS_PROJECT_DIR)/luau/Compiler/include

Spork_LDFLAGS = -undefined dynamic_lookup -L$(THEOS_PROJECT_DIR)/lib -lDobby
Spork_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
