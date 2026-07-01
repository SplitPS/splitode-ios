ARCHS := arm64
TARGET := iphone:clang:16.5:15.0
PACKAGE_FORMAT = deb
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TailsDrop
TailsDrop_FILES = Tweak.x TDDevicePicker.m TDServiceBrowser.m TDSender.m
TailsDrop_CFLAGS = -fobjc-arc
TailsDrop_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
