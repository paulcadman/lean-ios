.DEFAULT_GOAL := all

LEAN_SRC_DIR := lean4
LEAN_PREFIX := $(shell lean --print-prefix)
IOS_SDK ?= iphonesimulator
IOS_DEPLOYMENT_TARGET ?= 16.0
IOS_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)
SDK_TAG := $(subst -,_,$(subst .,_,$(IOS_TARGET)))
SIMULATOR_SDK ?= iphonesimulator
SIMULATOR_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)-simulator
SIMULATOR_SDK_TAG := $(subst -,_,$(subst .,_,$(SIMULATOR_TARGET)))
SIMULATOR_DEVICE ?= iPhone 16
APP_BUNDLE_ID ?= dev.paulcadman.LeanIOSExample

BUILD_DIR := build
LEAN_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SDK_TAG)-runtime
IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SDK_TAG)
LIB_DIR := $(IOS_BUILD_DIR)/lib
SIM_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SIMULATOR_SDK_TAG)-runtime
SIM_IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SIMULATOR_SDK_TAG)
SIM_LIB_DIR := $(SIM_IOS_BUILD_DIR)/lib
SIM_RUNTIME_LIB := $(SIM_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
SIM_STDLIB_INIT_LIB := $(SIM_LIB_DIR)/libInit.a
APP_BUILD_DIR := $(BUILD_DIR)/ios-sim-app
APP_GEN_DIR := $(APP_BUILD_DIR)/generated
APP_OBJ_DIR := $(APP_BUILD_DIR)/obj
APP_MODULE_CACHE_DIR := $(APP_BUILD_DIR)/module-cache
APP_DIR := $(APP_BUILD_DIR)/LeanIOSExample.app
APP_BIN := $(APP_DIR)/LeanIOSExample
APP_INFO_PLIST := $(APP_DIR)/Info.plist
EXAMPLE_APP_DIR := example-app
APP_LEAN_DIR := $(EXAMPLE_APP_DIR)/lean
APP_NATIVE_DIR := $(EXAMPLE_APP_DIR)/native
APP_MODULE_NAME := Example
APP_MODULE := $(APP_LEAN_DIR)/$(APP_MODULE_NAME).lean
APP_MODULE_C := $(APP_GEN_DIR)/$(APP_MODULE_NAME).c
APP_MODULE_OLEAN := $(APP_GEN_DIR)/$(APP_MODULE_NAME).olean
APP_MODULE_ILEAN := $(APP_GEN_DIR)/$(APP_MODULE_NAME).ilean
APP_MODULE_OBJ := $(APP_OBJ_DIR)/$(APP_MODULE_NAME).o
APP_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanIOSBridge.cpp
APP_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanIOSBridge.h
APP_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanIOSBridge.o
APP_MAIN_SRC := $(APP_NATIVE_DIR)/App/main.swift
APP_INFO_PLIST_SRC := $(APP_NATIVE_DIR)/App/Info.plist
SIMULATOR_SDK_PATH := $(shell xcrun --sdk $(SIMULATOR_SDK) --show-sdk-path)

RUNTIME_LIB := $(LEAN_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
STAGE0_STDLIB_DIR := $(LEAN_SRC_DIR)/stage0/stdlib
STDLIB_INIT_LIB_LEANMAKE := $(LIB_DIR)/libInit.a

AR := xcrun --sdk $(IOS_SDK) ar
IOS_LEANC := $(abspath scripts/ios-leanc.sh)

.PHONY: all runtime stdlib-init sim-runtime sim-app run-sim-app clean

all: runtime stdlib-init

runtime: $(RUNTIME_LIB)

stdlib-init: $(STDLIB_INIT_LIB_LEANMAKE)

$(RUNTIME_LIB):
	cmake -S $(LEAN_SRC_DIR)/src -B $(LEAN_RUNTIME_BUILD_DIR) -G "Unix Makefiles" \
		-DSTAGE=0 \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_OSX_SYSROOT=$(IOS_SDK) \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=$(IOS_DEPLOYMENT_TARGET) \
		-DCMAKE_BUILD_TYPE=Release \
		-DUSE_MIMALLOC=OFF \
		-DUSE_LIBUV=OFF \
		-DUSE_GMP=OFF
	cmake --build $(LEAN_RUNTIME_BUILD_DIR) --target leanrt -j4

$(STDLIB_INIT_LIB_LEANMAKE): $(RUNTIME_LIB) $(IOS_LEANC)
	mkdir -p $(LIB_DIR)
	cd $(STAGE0_STDLIB_DIR) && \
	IOS_SDK="$(IOS_SDK)" \
	IOS_TARGET="$(IOS_TARGET)" \
	IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" \
	LEAN_RUNTIME_INCLUDE="$(abspath $(LEAN_RUNTIME_BUILD_DIR))/include" \
	LEAN_STAGE0_INCLUDE="$(abspath $(LEAN_SRC_DIR))/stage0/src/include" \
	LEAN_SRC_INCLUDE="$(abspath $(LEAN_SRC_DIR))/src/include" \
	$(LEAN_PREFIX)/bin/leanmake \
	  lib \
		-j8 \
	  LEANC="$(IOS_LEANC)" \
	  LEAN_AR="$(AR)" \
	  PKG=Init \
	  C_ONLY=1 \
	  C_OUT=. \
	  OUT="$(abspath $(IOS_BUILD_DIR))/leanmake" \
	  TEMP_OUT="$(abspath $(IOS_BUILD_DIR))/leanmake/temp" \
	  LIB_OUT="$(abspath $(LIB_DIR))"

sim-runtime:
	$(MAKE) IOS_SDK="$(SIMULATOR_SDK)" IOS_TARGET="$(SIMULATOR_TARGET)" IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" runtime stdlib-init

$(APP_MODULE_C): $(APP_MODULE)
	mkdir -p $(APP_GEN_DIR)
	lean -R $(APP_LEAN_DIR) \
	  -o $(APP_MODULE_OLEAN) \
	  -i $(APP_MODULE_ILEAN) \
	  -c $(APP_MODULE_C) \
	  $(APP_MODULE)

$(APP_MODULE_OBJ): $(APP_MODULE_C)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -c $(APP_MODULE_C) \
	  -o $(APP_MODULE_OBJ)

$(APP_BRIDGE_OBJ): $(APP_BRIDGE_SRC) $(APP_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang++ \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -c $(APP_BRIDGE_SRC) \
	  -o $(APP_BRIDGE_OBJ)

$(APP_BIN): sim-runtime $(APP_MODULE_OBJ) $(APP_BRIDGE_OBJ) $(APP_MAIN_SRC)
	mkdir -p $(APP_DIR) $(APP_MODULE_CACHE_DIR)
	xcrun --sdk $(SIMULATOR_SDK) swiftc \
	  -parse-as-library \
	  -target $(SIMULATOR_TARGET) \
	  -sdk $(SIMULATOR_SDK_PATH) \
	  -module-cache-path $(APP_MODULE_CACHE_DIR) \
	  -import-objc-header $(APP_BRIDGE_HEADER) \
	  $(APP_MAIN_SRC) \
	  $(APP_MODULE_OBJ) \
	  $(APP_BRIDGE_OBJ) \
	  $(SIM_STDLIB_INIT_LIB) \
	  $(SIM_RUNTIME_LIB) \
	  -framework UIKit \
	  -framework Foundation \
	  -Xlinker -lc++ \
	  -o $(APP_BIN)

$(APP_INFO_PLIST): $(APP_INFO_PLIST_SRC)
	mkdir -p $(APP_DIR)
	cp $(APP_INFO_PLIST_SRC) $(APP_INFO_PLIST)

sim-app: $(APP_BIN) $(APP_INFO_PLIST)

run-sim-app: sim-app
	if ! xcrun simctl list devices booted | grep -q "Booted"; then \
	  xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	  open -a Simulator; \
	  xcrun simctl bootstatus "$(SIMULATOR_DEVICE)" -b; \
	fi
	xcrun simctl install booted $(APP_DIR)
	xcrun simctl launch booted $(APP_BUNDLE_ID)

clean:
	rm -rf $(BUILD_DIR)
