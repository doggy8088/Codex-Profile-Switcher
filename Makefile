PROJECT := Codex Profile Switcher.xcodeproj
SCHEME := CodexProfileSwitcher
APP_DISPLAY_NAME := Codex Profile Swicher
APP_BUNDLE_NAME := CodexProfileSwitcher
DMG_BASENAME ?= CodexProfilesSwitcher
CONFIGURATION ?= Debug
DERIVED_DATA_PATH ?= .build/DerivedData
XCODEBUILD := xcodebuild
BUILD_DIR ?= build
ARCHIVE_PATH ?= $(BUILD_DIR)/$(APP_BUNDLE_NAME).xcarchive
EXPORT_PATH ?= $(BUILD_DIR)/export
EXPORT_OPTIONS_PLIST ?= $(BUILD_DIR)/ExportOptions.plist
DMG_ROOT ?= $(BUILD_DIR)/dmg-root
DMG_PATH ?= $(BUILD_DIR)/$(DMG_BASENAME).dmg
UNSIGNED_DMG_PATH ?= $(BUILD_DIR)/$(DMG_BASENAME)-unsigned.dmg
UNSIGNED_DMG_RW_PATH ?= $(BUILD_DIR)/$(DMG_BASENAME)-unsigned-rw.dmg
DMG_RW_PATH ?= $(BUILD_DIR)/$(DMG_BASENAME)-rw.dmg
DMG_VOLUME_NAME ?= $(APP_DISPLAY_NAME)
DMG_FORMAT ?= UDZO
DMG_WINDOW_BOUNDS ?= 140, 140, 680, 500
DMG_ICON_SIZE ?= 88
DMG_APP_ICON_POSITION ?= 160, 140
DMG_APPLICATIONS_ICON_POSITION ?= 380, 140
NOTARY_SUBMIT_LOG ?= $(BUILD_DIR)/notarytool-submit.log
NOTARY_RESULT_LOG ?= $(BUILD_DIR)/notarytool-result.json
APPLE_CREDENTIALS_DIR ?= $(HOME)/Documents/AppleCodeSigningCredentials
APPLE_TEAM_ID ?= XKF69LC6US
APPLE_SIGNING_IDENTITY ?= Developer ID Application: Duotify Inc. (XKF69LC6US)
NOTARY_KEY ?= $(APPLE_CREDENTIALS_DIR)/AuthKey_3X5KRBCA78.p8
NOTARY_KEY_ID ?= 3X5KRBCA78
NOTARY_ISSUER_ID ?= 69a6de82-cece-47e3-e053-5b8c7c11a4d1
NOTARY_TIMEOUT ?= 1h

.PHONY: help list build build-debug build-release build-unsigned dmg dmg-unsigned test test-unsigned clean open

help:
	@printf '%s\n' 'Common tasks:'
	@printf '  %-16s %s\n' 'make list' 'List Xcode project targets, configurations, and schemes'
	@printf '  %-16s %s\n' 'make build' 'Build with CONFIGURATION, defaulting to Debug'
	@printf '  %-16s %s\n' 'make build-debug' 'Build the Debug configuration'
	@printf '  %-16s %s\n' 'make build-release' 'Build the Release configuration'
	@printf '  %-16s %s\n' 'make build-unsigned' 'Build without code signing for local verification'
	@printf '  %-16s %s\n' 'make dmg' 'Build, sign, notarize, staple, and verify a Developer ID DMG'
	@printf '  %-16s %s\n' 'make dmg-unsigned' 'Build an unsigned DMG with the same Finder layout'
	@printf '  %-16s %s\n' 'make test' 'Run the XCTest suite'
	@printf '  %-16s %s\n' 'make test-unsigned' 'Run tests without code signing for local verification'
	@printf '  %-16s %s\n' 'make clean' 'Remove build products and intermediate files'
	@printf '  %-16s %s\n' 'make open' 'Open the Xcode project'

list:
	$(XCODEBUILD) -list -project "$(PROJECT)"

build:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -derivedDataPath "$(DERIVED_DATA_PATH)" build

build-debug:
	$(MAKE) build CONFIGURATION=Debug

build-release:
	$(MAKE) build CONFIGURATION=Release

build-unsigned:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -derivedDataPath "$(DERIVED_DATA_PATH)" CODE_SIGNING_ALLOWED=NO build

dmg-unsigned:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Release -derivedDataPath "$(DERIVED_DATA_PATH)" CODE_SIGNING_ALLOWED=NO build
	@set -euo pipefail; \
	APP_PATH="$(DERIVED_DATA_PATH)/Build/Products/Release/$(APP_BUNDLE_NAME).app"; \
	test -d "$$APP_PATH" || { printf '%s\n' "Missing built app: $$APP_PATH" >&2; exit 1; }; \
	rm -rf "$(DMG_ROOT)" "$(UNSIGNED_DMG_PATH)" "$(UNSIGNED_DMG_RW_PATH)"; \
	if [ -d "/Volumes/$(DMG_VOLUME_NAME)" ]; then hdiutil detach "/Volumes/$(DMG_VOLUME_NAME)" || true; fi; \
	if [ -d "/Volumes/$(DMG_VOLUME_NAME) 1" ]; then hdiutil detach "/Volumes/$(DMG_VOLUME_NAME) 1" || true; fi; \
	mkdir -p "$(BUILD_DIR)" "$(DMG_ROOT)"; \
	cp -R "$$APP_PATH" "$(DMG_ROOT)/"; \
	ln -s /Applications "$(DMG_ROOT)/Applications"; \
	hdiutil create -volname "$(DMG_VOLUME_NAME)" -srcfolder "$(DMG_ROOT)" -ov -format UDRW "$(UNSIGNED_DMG_RW_PATH)"; \
	MOUNT_POINT="$$(hdiutil attach "$(UNSIGNED_DMG_RW_PATH)" -readwrite -noverify -noautoopen | awk -F '\t' '/\/Volumes\// { print $$NF; exit }')"; \
	test -n "$$MOUNT_POINT" || { printf '%s\n' 'Failed to mount unsigned DMG layout image.' >&2; exit 1; }; \
	osascript -e 'tell application "Finder"' \
		-e 'tell disk "$(DMG_VOLUME_NAME)"' \
		-e 'open' \
		-e 'set current view of container window to icon view' \
		-e 'set toolbar visible of container window to false' \
		-e 'set statusbar visible of container window to false' \
		-e 'set bounds of container window to {$(DMG_WINDOW_BOUNDS)}' \
		-e 'set arrangement of icon view options of container window to not arranged' \
		-e 'set icon size of icon view options of container window to $(DMG_ICON_SIZE)' \
		-e 'set position of item "$(APP_BUNDLE_NAME).app" of container window to {$(DMG_APP_ICON_POSITION)}' \
		-e 'set position of item "Applications" of container window to {$(DMG_APPLICATIONS_ICON_POSITION)}' \
		-e 'close' \
		-e 'open' \
		-e 'update without registering applications' \
		-e 'delay 1' \
		-e 'end tell' \
		-e 'end tell'; \
	sync; \
	hdiutil detach "$$MOUNT_POINT"; \
	hdiutil convert "$(UNSIGNED_DMG_RW_PATH)" -format "$(DMG_FORMAT)" -o "$(UNSIGNED_DMG_PATH)"; \
	shasum -a 256 "$(UNSIGNED_DMG_PATH)" | tee "$(UNSIGNED_DMG_PATH).sha256"; \
	printf 'Created unsigned DMG: %s\n' "$(UNSIGNED_DMG_PATH)"

dmg:
	@set -euo pipefail; \
	test -d "$(APPLE_CREDENTIALS_DIR)" || { printf '%s\n' 'Missing Apple credentials directory: $(APPLE_CREDENTIALS_DIR)' >&2; exit 1; }; \
	test -f "$(NOTARY_KEY)" || { printf '%s\n' 'Missing notarization API key: $(NOTARY_KEY)' >&2; exit 1; }; \
	security find-identity -v -p codesigning | grep -F "$(APPLE_SIGNING_IDENTITY)" >/dev/null || { printf '%s\n' 'Missing signing identity in Keychain: $(APPLE_SIGNING_IDENTITY)' >&2; exit 1; }; \
	rm -rf "$(ARCHIVE_PATH)" "$(EXPORT_PATH)" "$(EXPORT_OPTIONS_PLIST)" "$(DMG_ROOT)" "$(DMG_PATH)" "$(DMG_RW_PATH)"; \
	mkdir -p "$(BUILD_DIR)"; \
	{ \
		printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'; \
		printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'; \
		printf '%s\n' '<plist version="1.0">'; \
		printf '%s\n' '<dict>'; \
		printf '%s\n' '	<key>destination</key>'; \
		printf '%s\n' '	<string>export</string>'; \
		printf '%s\n' '	<key>method</key>'; \
		printf '%s\n' '	<string>developer-id</string>'; \
		printf '%s\n' '	<key>signingCertificate</key>'; \
		printf '%s\n' '	<string>Developer ID Application</string>'; \
		printf '%s\n' '	<key>signingStyle</key>'; \
		printf '%s\n' '	<string>manual</string>'; \
		printf '%s\n' '	<key>stripSwiftSymbols</key>'; \
		printf '%s\n' '	<true/>'; \
		printf '%s\n' '	<key>teamID</key>'; \
		printf '%s\n' '	<string>$(APPLE_TEAM_ID)</string>'; \
		printf '%s\n' '</dict>'; \
		printf '%s\n' '</plist>'; \
	} > "$(EXPORT_OPTIONS_PLIST)"
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Release -derivedDataPath "$(DERIVED_DATA_PATH)" -archivePath "$(ARCHIVE_PATH)" archive CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$(APPLE_TEAM_ID)" CODE_SIGN_IDENTITY="$(APPLE_SIGNING_IDENTITY)" OTHER_CODE_SIGN_FLAGS="--timestamp"
	$(XCODEBUILD) -exportArchive -archivePath "$(ARCHIVE_PATH)" -exportPath "$(EXPORT_PATH)" -exportOptionsPlist "$(EXPORT_OPTIONS_PLIST)"
	@set -euo pipefail; \
	APP_PATH="$(EXPORT_PATH)/$(APP_BUNDLE_NAME).app"; \
	test -d "$$APP_PATH" || { printf '%s\n' "Missing exported app: $$APP_PATH" >&2; exit 1; }; \
	codesign --force --deep --options runtime --timestamp --sign "$(APPLE_SIGNING_IDENTITY)" "$$APP_PATH"; \
	codesign --verify --deep --strict --verbose=4 "$$APP_PATH"; \
	if [ -d "/Volumes/$(DMG_VOLUME_NAME)" ]; then hdiutil detach "/Volumes/$(DMG_VOLUME_NAME)" || true; fi; \
	if [ -d "/Volumes/$(DMG_VOLUME_NAME) 1" ]; then hdiutil detach "/Volumes/$(DMG_VOLUME_NAME) 1" || true; fi; \
	mkdir -p "$(DMG_ROOT)"; \
	cp -R "$$APP_PATH" "$(DMG_ROOT)/"; \
	ln -s /Applications "$(DMG_ROOT)/Applications"; \
	hdiutil create -volname "$(DMG_VOLUME_NAME)" -srcfolder "$(DMG_ROOT)" -ov -format UDRW "$(DMG_RW_PATH)"; \
	MOUNT_POINT="$$(hdiutil attach "$(DMG_RW_PATH)" -readwrite -noverify -noautoopen | awk -F '\t' '/\/Volumes\// { print $$NF; exit }')"; \
	test -n "$$MOUNT_POINT" || { printf '%s\n' 'Failed to mount DMG layout image.' >&2; exit 1; }; \
	osascript -e 'tell application "Finder"' \
		-e 'tell disk "$(DMG_VOLUME_NAME)"' \
		-e 'open' \
		-e 'set current view of container window to icon view' \
		-e 'set toolbar visible of container window to false' \
		-e 'set statusbar visible of container window to false' \
		-e 'set bounds of container window to {$(DMG_WINDOW_BOUNDS)}' \
		-e 'set arrangement of icon view options of container window to not arranged' \
		-e 'set icon size of icon view options of container window to $(DMG_ICON_SIZE)' \
		-e 'set position of item "$(APP_BUNDLE_NAME).app" of container window to {$(DMG_APP_ICON_POSITION)}' \
		-e 'set position of item "Applications" of container window to {$(DMG_APPLICATIONS_ICON_POSITION)}' \
		-e 'close' \
		-e 'open' \
		-e 'update without registering applications' \
		-e 'delay 1' \
		-e 'end tell' \
		-e 'end tell'; \
	sync; \
	hdiutil detach "$$MOUNT_POINT"; \
	hdiutil convert "$(DMG_RW_PATH)" -format "$(DMG_FORMAT)" -o "$(DMG_PATH)"; \
	codesign --force --timestamp --sign "$(APPLE_SIGNING_IDENTITY)" "$(DMG_PATH)"; \
	codesign --verify --verbose=4 "$(DMG_PATH)"; \
	xcrun notarytool submit "$(DMG_PATH)" --key "$(NOTARY_KEY)" --key-id "$(NOTARY_KEY_ID)" --issuer "$(NOTARY_ISSUER_ID)" --wait --timeout "$(NOTARY_TIMEOUT)" 2>&1 | tee "$(NOTARY_SUBMIT_LOG)"; \
	if ! grep -q 'status: Accepted' "$(NOTARY_SUBMIT_LOG)"; then \
		submission_id="$$(awk '/^[[:space:]]*id:/ { print $$2; exit }' "$(NOTARY_SUBMIT_LOG)")"; \
		if [ -n "$$submission_id" ]; then \
			xcrun notarytool log "$$submission_id" --key "$(NOTARY_KEY)" --key-id "$(NOTARY_KEY_ID)" --issuer "$(NOTARY_ISSUER_ID)" | tee "$(NOTARY_RESULT_LOG)" >&2; \
		fi; \
		printf '%s\n' 'Notarization did not return status: Accepted.' >&2; \
		exit 1; \
	fi; \
	xcrun stapler staple "$(DMG_PATH)"; \
	xcrun stapler validate "$(DMG_PATH)"; \
	spctl -a -vvv -t open --context context:primary-signature "$(DMG_PATH)"; \
	shasum -a 256 "$(DMG_PATH)" | tee "$(DMG_PATH).sha256"; \
	printf 'Created signed and notarized DMG: %s\n' "$(DMG_PATH)"

test:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug -derivedDataPath "$(DERIVED_DATA_PATH)" test

test-unsigned:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug -derivedDataPath "$(DERIVED_DATA_PATH)" CODE_SIGNING_ALLOWED=NO test

clean:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -derivedDataPath "$(DERIVED_DATA_PATH)" clean
	rm -rf "$(DERIVED_DATA_PATH)"
	rm -rf "$(BUILD_DIR)"

open:
	open "$(PROJECT)"
