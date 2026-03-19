.DEFAULT_GOAL := sim-app

ROOT_DIR := ..
CORE_MAKE := $(ROOT_DIR)/Makefile

LEAN_SRC_DIR := $(ROOT_DIR)/lean4
SIMULATOR_SDK ?= iphonesimulator
IOS_DEPLOYMENT_TARGET ?= 16.0
SIMULATOR_TARGET ?= arm64-apple-ios$(IOS_DEPLOYMENT_TARGET)-simulator
SIMULATOR_SDK_TAG := $(subst -,_,$(subst .,_,$(SIMULATOR_TARGET)))
SIMULATOR_DEVICE ?= iPhone 16
SDL_APP_BUNDLE_ID ?= dev.paulcadman.LeanSDLExample

BUILD_DIR := $(ROOT_DIR)/build
SIM_RUNTIME_BUILD_DIR := $(BUILD_DIR)/lean4-$(SIMULATOR_SDK_TAG)-runtime
SIM_IOS_BUILD_DIR := $(BUILD_DIR)/ios-lean-$(SIMULATOR_SDK_TAG)
SIM_RUNTIME_LIB := $(SIM_RUNTIME_BUILD_DIR)/lib/lean/libleanrt.a
SIM_STDLIB_INIT_LIB := $(SIM_IOS_BUILD_DIR)/lib/libInit.a
SIMULATOR_SDK_PATH := $(shell xcrun --sdk $(SIMULATOR_SDK) --show-sdk-path)

SDL_XCODE_DIR := $(ROOT_DIR)/third-party/SDL/Xcode/SDL
SDL_XCODE_PROJECT := $(SDL_XCODE_DIR)/SDL.xcodeproj
SDL_BUILD_DIR := $(BUILD_DIR)/sdl3
SDL_MODULE_CACHE_DIR := $(SDL_BUILD_DIR)/ModuleCache
SDL_BUILD_HOME := $(SDL_BUILD_DIR)/home
SDL_SIM_ARCHIVE := $(SDL_BUILD_DIR)/SDL3-iphonesimulator.xcarchive
SDL_DEVICE_ARCHIVE := $(SDL_BUILD_DIR)/SDL3-iphoneos.xcarchive
SDL_XCFRAMEWORK := $(SDL_BUILD_DIR)/SDL3.xcframework
SDL_XCFRAMEWORK_INFO := $(SDL_XCFRAMEWORK)/Info.plist
SDL_SIM_FRAMEWORK := $(SDL_XCFRAMEWORK)/ios-arm64_x86_64-simulator/SDL3.framework
SDL_SIM_HEADERS_DIR := $(SDL_SIM_FRAMEWORK)/Headers

APP_LEAN_DIR := lean
APP_NATIVE_DIR := native
APP_BUILD_DIR := $(BUILD_DIR)/ios-sdl-sim-app
APP_GEN_DIR := $(APP_BUILD_DIR)/generated
APP_OBJ_DIR := $(APP_BUILD_DIR)/obj
APP_DIR := $(APP_BUILD_DIR)/LeanSDLExample.app
APP_BIN := $(APP_DIR)/LeanSDLExample
APP_INFO_PLIST := $(APP_DIR)/Info.plist
APP_FRAMEWORKS_DIR := $(APP_DIR)/Frameworks
APP_SDL_FRAMEWORK := $(APP_FRAMEWORKS_DIR)/SDL3.framework
APP_MODULE_NAME := ExampleSDL
APP_MODULE := $(APP_LEAN_DIR)/$(APP_MODULE_NAME).lean
APP_MODULE_C := $(APP_GEN_DIR)/$(APP_MODULE_NAME).c
APP_MODULE_OLEAN := $(APP_GEN_DIR)/$(APP_MODULE_NAME).olean
APP_MODULE_ILEAN := $(APP_GEN_DIR)/$(APP_MODULE_NAME).ilean
APP_MODULE_OBJ := $(APP_OBJ_DIR)/$(APP_MODULE_NAME).o
APP_BINDINGS_SRC := $(APP_NATIVE_DIR)/LeanSDLBindings.c
APP_BINDINGS_HEADER := $(APP_NATIVE_DIR)/LeanSDLBindings.h
APP_BINDINGS_OBJ := $(APP_OBJ_DIR)/LeanSDLBindings.o
APP_RUNTIME_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanRuntimeBridge.c
APP_RUNTIME_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanRuntimeBridge.h
APP_RUNTIME_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanRuntimeBridge.o
APP_BRIDGE_SRC := $(APP_NATIVE_DIR)/LeanSDLAppBridge.c
APP_BRIDGE_HEADER := $(APP_NATIVE_DIR)/LeanSDLAppBridge.h
APP_BRIDGE_OBJ := $(APP_OBJ_DIR)/LeanSDLAppBridge.o
APP_REGISTRATION_SRC := $(APP_NATIVE_DIR)/LeanSDLModuleRegistration.c
APP_REGISTRATION_HEADER := $(APP_NATIVE_DIR)/LeanSDLModuleRegistration.h
APP_REGISTRATION_OBJ := $(APP_OBJ_DIR)/LeanSDLModuleRegistration.o
APP_MAIN_SRC := $(APP_NATIVE_DIR)/App/main.c
APP_MAIN_OBJ := $(APP_OBJ_DIR)/main.o
APP_INFO_PLIST_SRC := $(APP_NATIVE_DIR)/App/Info.plist

.PHONY: sim-runtime sdl3-xcframework sim-app run-sim-app clean

sim-runtime:
	$(MAKE) -C $(ROOT_DIR) IOS_SDK="$(SIMULATOR_SDK)" IOS_TARGET="$(SIMULATOR_TARGET)" IOS_DEPLOYMENT_TARGET="$(IOS_DEPLOYMENT_TARGET)" runtime stdlib-init

$(SDL_XCFRAMEWORK_INFO):
	rm -rf $(SDL_SIM_ARCHIVE) $(SDL_DEVICE_ARCHIVE) $(SDL_XCFRAMEWORK)
	mkdir -p $(SDL_MODULE_CACHE_DIR) $(SDL_BUILD_HOME)
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild archive \
	  -project $(SDL_XCODE_PROJECT) \
	  -scheme SDL3 \
	  -configuration Release \
	  -archivePath $(abspath $(SDL_SIM_ARCHIVE)) \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath $(abspath $(SDL_BUILD_DIR))/DerivedData \
	  CLANG_MODULE_CACHE_PATH=$(abspath $(SDL_MODULE_CACHE_DIR)) \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild archive \
	  -project $(SDL_XCODE_PROJECT) \
	  -scheme SDL3 \
	  -configuration Release \
	  -archivePath $(abspath $(SDL_DEVICE_ARCHIVE)) \
	  -destination 'generic/platform=iOS' \
	  -derivedDataPath $(abspath $(SDL_BUILD_DIR))/DerivedData \
	  CLANG_MODULE_CACHE_PATH=$(abspath $(SDL_MODULE_CACHE_DIR)) \
	  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	  SKIP_INSTALL=NO
	HOME=$(abspath $(SDL_BUILD_HOME)) xcodebuild -create-xcframework \
	  -framework $(abspath $(SDL_SIM_ARCHIVE))/Products/Library/Frameworks/SDL3.framework \
	  -framework $(abspath $(SDL_DEVICE_ARCHIVE))/Products/Library/Frameworks/SDL3.framework \
	  -output $(abspath $(SDL_XCFRAMEWORK))

sdl3-xcframework: $(SDL_XCFRAMEWORK_INFO)

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
	  -I$(SDL_SIM_HEADERS_DIR) \
	  -c $(APP_MODULE_C) \
	  -o $(APP_MODULE_OBJ)

$(APP_BINDINGS_OBJ): $(APP_BINDINGS_SRC) $(APP_BINDINGS_HEADER) $(SDL_XCFRAMEWORK_INFO)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  -c $(APP_BINDINGS_SRC) \
	  -o $(APP_BINDINGS_OBJ)

$(APP_RUNTIME_BRIDGE_OBJ): $(APP_RUNTIME_BRIDGE_SRC) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -c $(APP_RUNTIME_BRIDGE_SRC) \
	  -o $(APP_RUNTIME_BRIDGE_OBJ)

$(APP_BRIDGE_OBJ): $(APP_BRIDGE_SRC) $(APP_BRIDGE_HEADER) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -c $(APP_BRIDGE_SRC) \
	  -o $(APP_BRIDGE_OBJ)

$(APP_REGISTRATION_OBJ): $(APP_REGISTRATION_SRC) $(APP_REGISTRATION_HEADER) $(APP_RUNTIME_BRIDGE_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -c $(APP_REGISTRATION_SRC) \
	  -o $(APP_REGISTRATION_OBJ)

$(APP_MAIN_OBJ): $(APP_MAIN_SRC) $(SDL_XCFRAMEWORK_INFO) $(APP_REGISTRATION_HEADER)
	mkdir -p $(APP_OBJ_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -I$(SIM_RUNTIME_BUILD_DIR)/include \
	  -I$(LEAN_SRC_DIR)/stage0/src/include \
	  -I$(LEAN_SRC_DIR)/src/include \
	  -I$(APP_NATIVE_DIR) \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  -c $(APP_MAIN_SRC) \
	  -o $(APP_MAIN_OBJ)

$(APP_SDL_FRAMEWORK): $(SDL_XCFRAMEWORK_INFO)
	mkdir -p $(APP_FRAMEWORKS_DIR)
	rm -rf $(APP_SDL_FRAMEWORK)
	cp -R $(SDL_SIM_FRAMEWORK) $(APP_SDL_FRAMEWORK)

$(APP_BIN): sim-runtime $(SDL_XCFRAMEWORK_INFO) $(APP_MODULE_OBJ) $(APP_BINDINGS_OBJ) $(APP_RUNTIME_BRIDGE_OBJ) $(APP_BRIDGE_OBJ) $(APP_REGISTRATION_OBJ) $(APP_MAIN_OBJ)
	mkdir -p $(APP_DIR)
	xcrun --sdk $(SIMULATOR_SDK) clang++ \
	  -target $(SIMULATOR_TARGET) \
	  -isysroot $(SIMULATOR_SDK_PATH) \
	  -mios-simulator-version-min=$(IOS_DEPLOYMENT_TARGET) \
	  -F$(dir $(SDL_SIM_FRAMEWORK)) \
	  $(APP_MAIN_OBJ) \
	  $(APP_MODULE_OBJ) \
	  $(APP_BINDINGS_OBJ) \
	  $(APP_RUNTIME_BRIDGE_OBJ) \
	  $(APP_BRIDGE_OBJ) \
	  $(APP_REGISTRATION_OBJ) \
	  $(SIM_STDLIB_INIT_LIB) \
	  $(SIM_RUNTIME_LIB) \
	  -framework SDL3 \
	  -framework UIKit \
	  -framework Foundation \
	  -Xlinker -rpath -Xlinker @executable_path/Frameworks \
	  -o $(APP_BIN)

$(APP_INFO_PLIST): $(APP_INFO_PLIST_SRC)
	mkdir -p $(APP_DIR)
	cp $(APP_INFO_PLIST_SRC) $(APP_INFO_PLIST)

sim-app: $(APP_BIN) $(APP_INFO_PLIST) $(APP_SDL_FRAMEWORK)

run-sim-app: sim-app
	if ! xcrun simctl list devices booted | grep -q "Booted"; then \
	  xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	  open -a Simulator; \
	  xcrun simctl bootstatus "$(SIMULATOR_DEVICE)" -b; \
	fi
	xcrun simctl install booted $(APP_DIR)
	xcrun simctl launch booted $(SDL_APP_BUNDLE_ID)

clean:
	rm -rf $(APP_BUILD_DIR) $(SDL_BUILD_DIR)
