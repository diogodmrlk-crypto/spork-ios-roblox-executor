TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = Spork

# Compila os arquivos do projeto e do Luau
Spork_FILES = Tweak.xm SporkUI.mm exploit.mm hooks.mm memory.cpp execution.cpp
Spork_FILES += $(wildcard VM/src/*.cpp) $(wildcard Compiler/src/*.cpp)

# Aponta os includes para as pastas corretas, incluindo a subpasta Luau do Compiler
Spork_CFLAGS = -fobjc-arc -std=c++17 \
               -I$(THEOS_PROJECT_DIR)/VM/include \
               -I$(THEOS_PROJECT_DIR)/Compiler/include \
               -I$(THEOS_PROJECT_DIR)/Compiler/include/Luau \
               -I$(THEOS_PROJECT_DIR)/Common/include \
               -I$(THEOS_PROJECT_DIR)

# Linka o Dobby
Spork_LDFLAGS = -undefined dynamic_lookup -L$(THEOS_PROJECT_DIR)/lib -lDobby
Spork_FRAMEWORKS = UIKit Foundation Security

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
