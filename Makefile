APP_NAME = ReverseScrollCLI
BINARY_NAME = reverse-scroll-cli
VERSION = 0.1.1
MIN_MACOS = 13.0
BUNDLE_ID = com.dongzhenye.reverse-scroll-cli

BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources

.PHONY: all clean build bundle zip

all: bundle

build:
	@mkdir -p $(BUILD_DIR)
	swiftc Sources/main.swift \
		-o $(BUILD_DIR)/$(BINARY_NAME)-arm64 \
		-target arm64-apple-macos$(MIN_MACOS) \
		-O
	swiftc Sources/main.swift \
		-o $(BUILD_DIR)/$(BINARY_NAME)-x86 \
		-target x86_64-apple-macos$(MIN_MACOS) \
		-O
	lipo -create \
		$(BUILD_DIR)/$(BINARY_NAME)-arm64 \
		$(BUILD_DIR)/$(BINARY_NAME)-x86 \
		-output $(BUILD_DIR)/$(BINARY_NAME)

bundle: build
	@mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/
	cp Resources/Info.plist $(CONTENTS)/
	codesign --force --deep --sign - --identifier $(BUNDLE_ID) $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

zip: bundle
	@mkdir -p $(BUILD_DIR)/LaunchAgent
	cp LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist $(BUILD_DIR)/LaunchAgent/
	cd $(BUILD_DIR) && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Created $(BUILD_DIR)/$(APP_NAME).app.zip"

clean:
	rm -rf $(BUILD_DIR)
