ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:12.0
	ARCHS = x86_64
else
	TARGET = iphone:clang:latest:12.0
	ARCHS = arm64 arm64e
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SplitIt
SplitIt_FILES = Tweak.xm
SplitIt_LIBRARIES = Substitrate

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif