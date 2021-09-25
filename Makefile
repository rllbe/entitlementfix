DEBUG = 0
FINALPACKAGE = 1
GO_EASY_ON_ME = 1
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += _gamed
SUBPROJECTS += _nehelper
SUBPROJECTS += _analyticsd

include $(THEOS_MAKE_PATH)/aggregate.mk