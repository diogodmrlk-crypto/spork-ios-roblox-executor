TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

# 1. Compile Dobby as a separate library (prevents TINYSTL from breaking UIKit)
LIBRARY_NAME = libdobby
libdobby_FILES = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux)/')
libdobby_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti -I./Dobby/include -I./Dobby/source -I./Dobby/external -Wno-module-import-in-extern-c
include $(THEOS_MAKE_PATH)/library.mk

# 2. Compile the Tweak and link the Dobby library
TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm
Spork_OBJCFLAGS = -fobjc-arc
Spork_OBJCCFLAGS = -fobjc-arc

# Link against our newly built libdobby and the C++ standard library
Spork_LIBRARIES = libdobby c++

include $(THEOS_MAKE_PATH)/tweak.mk
