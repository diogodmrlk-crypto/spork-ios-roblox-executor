TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = Roblox

include $(THEOS)/makefiles/common.mk

# Dobby is built as a static library by the CMake step in the workflow
# (Dobby/build/universal/libdobby.a), then linked straight into the tweak.
DOBBY_DIR = $(THEOS_PROJECT_DIR)/Dobby

TWEAK_NAME = Spork
Spork_FILES = Tweak.xm SporkUI.mm
Spork_CFLAGS = -fobjc-arc -I$(DOBBY_DIR)/include
Spork_CCFLAGS = -std=c++17 -I$(DOBBY_DIR)/include
Spork_LDFLAGS = $(DOBBY_DIR)/build/universal/libdobby.a
Spork_LIBRARIES = c++
Spork_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
