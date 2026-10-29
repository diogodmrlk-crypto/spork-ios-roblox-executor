TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm exploit.mm hooks.mm memory.cpp execution.cpp

# Adicionado Security (usado pelo Luau) e a pasta do Luau para compilar o luau_compile
Spork_CFLAGS = -fobjc-arc -std=c++17 \
               -I$(THEOS_PROJECT_DIR)/luau \
               -I$(THEOS_PROJECT_DIR)

# Linka o Dobby da pasta lib
Spork_LDFLAGS = -undefined dynamic_lookup -L$(THEOS_PROJECT_DIR)/lib -lDobby
Spork_FRAMEWORKS = UIKit Foundation Security

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
