TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = libdobby
# Filter out the broken deprecated folder and non-iOS architectures
libdobby_FILES = $(shell find Dobby/source -name '*.cc' -o -name '*.c' | grep -v -E '/(x64|x86|Windows|Linux|deprecated)')

# Use ABSOLUTE paths for all include directories to fix Theos changing directories
DOBBY_INCLUDES = $(addprefix -I$(THEOS_PROJECT_DIR)/, $(shell find Dobby -type d | grep -v "/TINYSTL" | grep -v "/deprecated"))

libdobby_CCFLAGS = -std=c++14 -fno-exceptions -fno-rtti -fno-modules $(DOBBY_INCLUDES) -Wno-module-import-in-extern-c -Wno-error

include $(THEOS_MAKE_PATH)/library.mk

TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm
Spork_OBJCFLAGS = -fobjc-arc
Spork_OBJCCFLAGS = -fobjc-arc
Spork_LIBRARIES = libdobby c++

include $(THEOS_MAKE_PATH)/tweak.mk
