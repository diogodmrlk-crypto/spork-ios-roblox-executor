# ============================================================
# Spork iOS Executor — Makefile
# ============================================================

TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

# ============================================================
# Fontes do tweak
# ============================================================
TWEAK_NAME = Spork

Spork_FILES = Tweak.xm \
              SporkUI.mm \
              exploit.mm \
              hooks.mm \
              memory.cpp \
              execution.cpp

Spork_CFLAGS = -fobjc-arc \
               -std=c++17 \
               -I$(THEOS_PROJECT_DIR)/vendor/luau/include \
               -I$(THEOS_PROJECT_DIR)/vendor/luau/include/luaconf \
               -I$(THEOS_PROJECT_DIR)/include

Spork_LDFLAGS = -undefined dynamic_lookup

# Bibliotecas necessárias
Spork_FRAMEWORKS = UIKit Foundation
Spork_PRIVATE_FRAMEWORKS = 

# ============================================================
# Headers do Luau (se não estiverem em vendor/luau)
# ============================================================
# Se você colocou os headers em outro lugar, ajusta o -I acima.
# Os headers necessários são:
#   lua.h
#   luacode.h
#   luaconf.h
#   lualib.h
#   llimits.h

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
