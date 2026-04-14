APP_NAME = ReverseScrollCLI
BINARY_NAME = reverse-scroll-cli
VERSION = 0.2.0
MIN_MACOS = 13.0
BUNDLE_ID = com.dongzhenye.reverse-scroll-cli

BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources

.PHONY: all clean build bundle zip version

all: bundle

version:
	@mkdir -p $(BUILD_DIR)
	@sed 's/__VERSION__/$(VERSION)/g' Sources/ReverseScrollCLI/Version.swift.in > Sources/ReverseScrollCLI/Version.swift
	@sed 's/__VERSION__/$(VERSION)/g' Resources/Info.plist > $(BUILD_DIR)/Info.plist

build: version
	@mkdir -p $(BUILD_DIR)
	swift build -c release --arch arm64 --arch x86_64
	cp .build/apple/Products/Release/$(APP_NAME) $(BUILD_DIR)/$(BINARY_NAME)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/
	cp $(BUILD_DIR)/Info.plist $(CONTENTS)/
	codesign --force --deep --sign - --identifier $(BUNDLE_ID) $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

zip: bundle
	@mkdir -p $(BUILD_DIR)/LaunchAgent
	cp LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist $(BUILD_DIR)/LaunchAgent/
	cd $(BUILD_DIR) && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Created $(BUILD_DIR)/$(APP_NAME).app.zip"

clean:
	rm -rf $(BUILD_DIR) .build
