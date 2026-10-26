TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# Find all Dobby C++ files, ignoring Windows/Intel/Linux
DOBBY_SRC = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux)/')
DOBBY_INCLUDES = $(addprefix -I, $(shell find Dobby/source Dobby/include Dobby/external -type d))

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)
Spork_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti $(DOBBY_INCLUDES)
Spork_OBJCFLAGS = -fobjc-arc $(DOBBY_INCLUDES)
Spork_OBJCCFLAGS = -fobjc-arc $(DOBBY_INCLUDES)

Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
