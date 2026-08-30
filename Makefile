# frontmost -- a theos tool. See README.md beside this file.
#
# Built for the jailbreak the device runs; the scheme is the one thing that
# changes between rootful, rootless and roothide, so it is overridable:
#
#   make package THEOS_PACKAGE_SCHEME=rootless
TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e
THEOS_PACKAGE_SCHEME ?= roothide

include $(THEOS)/makefiles/common.mk

TOOL_NAME := frontmost
frontmost_FILES := main.m
frontmost_CFLAGS := -fobjc-arc
frontmost_FRAMEWORKS := Foundation
frontmost_PRIVATE_FRAMEWORKS := SpringBoardServices
frontmost_INSTALL_PATH := /usr/bin

include $(THEOS_MAKE_PATH)/tool.mk
