TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spork

# ONLY compile the core Dobby source files, ignoring Windows/Linux plugins
DOBBY_SRC = $(shell find Dobby/source -name '*.cc' -o -name '*.c')

Spork_FILES = Tweak.xm SporkUI.mm $(DOBBY_SRC)
Spork_CCFLAGS = -std=c++11 -fno-exceptions -fno-rtti -I./Dobby/include -I./Dobby/source
Spork_OBJCFLAGS = -fobjc-arc -I./Dobby/include
Spork_OBJCCFLAGS = -fobjc-arc -I./Dobby/include

# Link the C++ standard library
Spork_LIBRARIES = c++

include $(THEOS_MAKE_PATH)/tweak.mk
