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

# Developer ID Application identity (full common name with team ID in parens).
# Override with: make bundle SIGN_IDENTITY="..."
SIGN_IDENTITY ?= $(shell security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)".*/\1/')

# Keychain profile for notarytool (set via `xcrun notarytool store-credentials`).
# Override with: make notarize NOTARY_PROFILE="..."
NOTARY_PROFILE ?= notarytool-profile

.PHONY: all clean build bundle zip notarize version test

all: bundle

test: version
	swift test

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
	cp Resources/AppIcon.icns $(RESOURCES_DIR)/
	codesign --force --deep --options runtime --timestamp \
		--sign "$(SIGN_IDENTITY)" \
		--identifier $(BUNDLE_ID) \
		$(APP_BUNDLE)
	codesign --verify --deep --strict --verbose=2 $(APP_BUNDLE)
	@echo "Built and signed $(APP_BUNDLE)"

zip: bundle
	@mkdir -p $(BUILD_DIR)/LaunchAgent
	cp LaunchAgent/com.dongzhenye.reverse-scroll-cli.plist $(BUILD_DIR)/LaunchAgent/
	cd $(BUILD_DIR) && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Created $(BUILD_DIR)/$(APP_NAME).app.zip"

notarize: zip
	xcrun notarytool submit $(BUILD_DIR)/$(APP_NAME).app.zip \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	xcrun stapler staple $(APP_BUNDLE)
	cd $(BUILD_DIR) && rm -f $(APP_NAME).app.zip && zip -r $(APP_NAME).app.zip $(APP_NAME).app LaunchAgent/
	@echo "Notarized and stapled — $(BUILD_DIR)/$(APP_NAME).app.zip ready for release"

clean:
	rm -rf $(BUILD_DIR) .build
