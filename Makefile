# frontmost -- a theos tool. See README.md beside this file.
#
# Built the way geoshim's CLI is built, for the same devices: RootHide is the
# scheme, arm64 the slice, and the binary carries the entitlements that keep
# it out of a container. `?=` so a `make package THEOS_PACKAGE_SCHEME=rootless`
# from the command line still wins.
export THEOS_PACKAGE_SCHEME ?= roothide

TARGET = iphone:latest:15.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = frontmost
frontmost_FILES = main.m
frontmost_CFLAGS = -fobjc-arc -Wall
# MobileCoreServices for LSApplicationWorkspace, looked up at run time.
frontmost_FRAMEWORKS = Foundation MobileCoreServices
# SpringBoardServices for the direct question; BackBoardServices for the
# application-state route. Both private, declared by hand in main.m.
frontmost_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices
frontmost_INSTALL_PATH = /usr/local/bin

# RootHide runs a binary without the base entitlements sandboxed and
# containerized, and SpringBoard answers the frontmost question only to a
# caller carrying its own. ldid -S embeds them; see entitlements.plist.
frontmost_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
