TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libdobby
libdobby_FILES = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux|deprecated)')

# Explicitly list every directory Dobby's includes rely on using absolute paths
libdobby_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti -fno-modules \
-I$(THEOS_PROJECT_DIR)/Dobby/include \
-I$(THEOS_PROJECT_DIR)/Dobby/source \
-I$(THEOS_PROJECT_DIR)/Dobby/source/core \
-I$(THEOS_PROJECT_DIR)/Dobby/source/core/arch \
-I$(THEOS_PROJECT_DIR)/Dobby/source/dobby \
-I$(THEOS_PROJECT_DIR)/Dobby/source/common \
-I$(THEOS_PROJECT_DIR)/Dobby/source/MemoryAllocator \
-I$(THEOS_PROJECT_DIR)/Dobby/source/InterceptRouting \
-I$(THEOS_PROJECT_DIR)/Dobby/source/TrampolineBridge \
-I$(THEOS_PROJECT_DIR)/Dobby/source/TrampolineBridge/ClosureTrampolineBridge \
-I$(THEOS_PROJECT_DIR)/Dobby/source/Backend/UserMode/ExecMemory \
-I$(THEOS_PROJECT_DIR)/Dobby/external \
-I$(THEOS_PROJECT_DIR)/Dobby/external/logging \
-Wno-module-import-in-extern-c \
-Wno-error

include $(THEOS_MAKE_PATH)/library.mk

TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm
Spork_OBJCFLAGS = -fobjc-arc
Spork_OBJCCFLAGS = -fobjc-arc
Spork_LIBRARIES = libdobby c++

include $(THEOS_MAKE_PATH)/tweak.mk
