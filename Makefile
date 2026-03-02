APP_NAME = ReverseScrollCLI
BINARY_NAME = reverse-scroll-cli
VERSION = 0.1.0
MIN_MACOS = 13.0

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
	@echo "Built $(APP_BUNDLE)"

zip: bundle
	cd $(BUILD_DIR) && zip -r $(APP_NAME).app.zip $(APP_NAME).app
	@echo "Created $(BUILD_DIR)/$(APP_NAME).app.zip"

clean:
	rm -rf $(BUILD_DIR)
