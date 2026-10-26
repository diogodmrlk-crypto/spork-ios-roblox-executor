TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Compile Dobby's core source files, ignoring Windows/Intel
DOBBY_SRC = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux)/')

# Find EVERY directory in the Dobby folder and add them all as include paths
DOBBY_INCLUDES = $(addprefix -I, $(shell find Dobby -type d))

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)

# Add all Dobby includes and suppress the Xcode 26 module error
Spork_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti $(DOBBY_INCLUDES) -Wno-module-import-in-extern-c
Spork_OBJCFLAGS = -fobjc-arc $(DOBBY_INCLUDES) -Wno-module-import-in-extern-c
Spork_OBJCCFLAGS = -fobjc-arc $(DOBBY_INCLUDES) -Wno-module-import-in-extern-c

# Link the C++ standard library
Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
