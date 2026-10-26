TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# 1. Find all Dobby C++ files, ignoring Windows/Intel/Linux
DOBBY_SRC = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux)/')

# 2. Include Dobby source and external folders (TINYSTL lives in external)
DOBBY_INCLUDES = $(addprefix -I, $(shell find Dobby/source Dobby/include Dobby/external -type d))

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)
# 3. Suppress the Xcode 26 module import error
Spork_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti -Wno-module-import-in-extern-c $(DOBBY_INCLUDES)
Spork_OBJCFLAGS = -fobjc-arc -Wno-module-import-in-extern-c $(DOBBY_INCLUDES)
Spork_OBJCCFLAGS = -fobjc-arc -Wno-module-import-in-extern-c $(DOBBY_INCLUDES)

# Link the C++ standard library
Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
