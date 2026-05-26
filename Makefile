# Define a directory for dependencies in the user's home folder
DEPS_DIR := $(HOME)/VoiceInk-Dependencies
WHISPER_CPP_DIR := $(DEPS_DIR)/whisper.cpp
FRAMEWORK_PATH := $(WHISPER_CPP_DIR)/build-apple/whisper.xcframework
LOCAL_DERIVED_DATA := $(CURDIR)/.local-build
APP_NAME := RawSpeech
APP_BUNDLE_ID := com.carbon400.RawSpeech
DIST_DIR := $(CURDIR)/dist

.PHONY: all clean whisper setup build local package ci check healthcheck help dev run

# Default target
all: check build

# Development workflow
dev: build run

# Prerequisites
check:
	@echo "Checking prerequisites..."
	@command -v git >/dev/null 2>&1 || { echo "git is not installed"; exit 1; }
	@xcodebuild -version >/dev/null 2>&1 || { echo "xcodebuild is not available. Install Xcode and select it with xcode-select."; exit 1; }
	@command -v swift >/dev/null 2>&1 || { echo "swift is not installed"; exit 1; }
	@command -v cmake >/dev/null 2>&1 || { echo "cmake is not installed (brew install cmake)"; exit 1; }
	@echo "Prerequisites OK"

healthcheck: check

# Build process
whisper:
	@mkdir -p $(DEPS_DIR)
	@if [ ! -d "$(FRAMEWORK_PATH)" ]; then \
		echo "Building whisper.xcframework in $(DEPS_DIR)..."; \
		if [ ! -d "$(WHISPER_CPP_DIR)" ]; then \
			git clone https://github.com/ggerganov/whisper.cpp.git $(WHISPER_CPP_DIR); \
		else \
			(cd $(WHISPER_CPP_DIR) && git pull); \
		fi; \
		cd $(WHISPER_CPP_DIR) && ./build-xcframework.sh; \
	else \
		echo "whisper.xcframework already built in $(DEPS_DIR), skipping build"; \
	fi

setup: whisper
	@echo "Whisper framework is ready at $(FRAMEWORK_PATH)"
	@echo "Please ensure your Xcode project references the framework from this new location."

build: setup
	xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Debug CODE_SIGN_IDENTITY="" build

# Build for local use without Apple Developer certificate
local: check setup
	@echo "Building $(APP_NAME) for local use (no Apple Developer certificate required)..."
	@rm -rf "$(LOCAL_DERIVED_DATA)"
	xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Debug \
		-derivedDataPath "$(LOCAL_DERIVED_DATA)" \
		-xcconfig LocalBuild.xcconfig \
		INFOPLIST_KEY_CFBundleDisplayName="$(APP_NAME)" \
		PRODUCT_BUNDLE_IDENTIFIER="$(APP_BUNDLE_ID)" \
		-resolvePackageDependencies
	xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Debug \
		-derivedDataPath "$(LOCAL_DERIVED_DATA)" \
		-xcconfig LocalBuild.xcconfig \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=YES \
		DEVELOPMENT_TEAM="" \
		CODE_SIGN_ENTITLEMENTS="$(CURDIR)/VoiceInk/VoiceInk.local.entitlements" \
		INFOPLIST_KEY_CFBundleDisplayName="$(APP_NAME)" \
		PRODUCT_BUNDLE_IDENTIFIER="$(APP_BUNDLE_ID)" \
		SWIFT_ACTIVE_COMPILATION_CONDITIONS='$$(inherited) LOCAL_BUILD' \
		build
	@APP_PATH="$(LOCAL_DERIVED_DATA)/Build/Products/Debug/VoiceInk.app" && \
	if [ -d "$$APP_PATH" ]; then \
		echo "Copying $(APP_NAME).app to ~/Downloads..."; \
		rm -rf "$$HOME/Downloads/$(APP_NAME).app"; \
		ditto "$$APP_PATH" "$$HOME/Downloads/$(APP_NAME).app"; \
		xattr -cr "$$HOME/Downloads/$(APP_NAME).app"; \
		echo ""; \
		echo "Build complete! App saved to: ~/Downloads/$(APP_NAME).app"; \
		echo "Run with: open ~/Downloads/$(APP_NAME).app"; \
		echo ""; \
		echo "Limitations of local builds:"; \
		echo "  - No iCloud dictionary sync"; \
		echo "  - No automatic updates"; \
	else \
		echo "Error: Could not find built $(APP_NAME).app at $$APP_PATH"; \
		exit 1; \
	fi

package: local
	@echo "Packaging $(APP_NAME).dmg..."
	@rm -rf "$(DIST_DIR)"
	@mkdir -p "$(DIST_DIR)/dmg-root"
	@ditto "$$HOME/Downloads/$(APP_NAME).app" "$(DIST_DIR)/dmg-root/$(APP_NAME).app"
	@ln -s /Applications "$(DIST_DIR)/dmg-root/Applications"
	@hdiutil create -volname "$(APP_NAME)" -srcfolder "$(DIST_DIR)/dmg-root" -ov -format UDZO "$(DIST_DIR)/$(APP_NAME).dmg"
	@rm -rf "$(DIST_DIR)/dmg-root"
	@echo "DMG ready: $(DIST_DIR)/$(APP_NAME).dmg"

ci: package

# Run application
run:
	@if [ -d "$$HOME/Downloads/$(APP_NAME).app" ]; then \
		echo "Opening ~/Downloads/$(APP_NAME).app..."; \
		open "$$HOME/Downloads/$(APP_NAME).app"; \
	else \
		echo "Looking for $(APP_NAME).app in DerivedData..."; \
		APP_PATH=$$(find "$$HOME/Library/Developer/Xcode/DerivedData" -name "$(APP_NAME).app" -type d | head -1) && \
		if [ -n "$$APP_PATH" ]; then \
			echo "Found app at: $$APP_PATH"; \
			open "$$APP_PATH"; \
		else \
			echo "$(APP_NAME).app not found. Please run 'make local' first."; \
			exit 1; \
		fi; \
	fi

# Cleanup
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(DEPS_DIR)
	@echo "Clean complete"

# Help
help:
	@echo "Available targets:"
	@echo "  check/healthcheck  Check if required CLI tools are installed"
	@echo "  whisper            Clone and build whisper.cpp XCFramework"
	@echo "  setup              Copy whisper XCFramework to VoiceInk project"
	@echo "  build              Build the VoiceInk Xcode project"
	@echo "  local              Build for local use (no Apple Developer certificate needed)"
	@echo "  package            Build local app and create dist/RawSpeech.dmg"
	@echo "  ci                 Alias for package, used by GitHub Actions"
	@echo "  run                Launch the built RawSpeech app"
	@echo "  dev                Build and run the app (for development)"
	@echo "  all                Run full build process (default)"
	@echo "  clean              Remove build artifacts"
	@echo "  help               Show this help message"
