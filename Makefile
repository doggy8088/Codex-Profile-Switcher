PROJECT := Codex Profile Switcher.xcodeproj
SCHEME := CodexProfileSwitcher
CONFIGURATION ?= Debug
DERIVED_DATA_PATH ?= .build/DerivedData
XCODEBUILD := xcodebuild

.PHONY: help list build build-debug build-release build-unsigned test test-unsigned clean open

help:
	@printf '%s\n' 'Common tasks:'
	@printf '  %-16s %s\n' 'make list' 'List Xcode project targets, configurations, and schemes'
	@printf '  %-16s %s\n' 'make build' 'Build with CONFIGURATION, defaulting to Debug'
	@printf '  %-16s %s\n' 'make build-debug' 'Build the Debug configuration'
	@printf '  %-16s %s\n' 'make build-release' 'Build the Release configuration'
	@printf '  %-16s %s\n' 'make build-unsigned' 'Build without code signing for local verification'
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

test:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug -derivedDataPath "$(DERIVED_DATA_PATH)" test

test-unsigned:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug -derivedDataPath "$(DERIVED_DATA_PATH)" CODE_SIGNING_ALLOWED=NO test

clean:
	$(XCODEBUILD) -project "$(PROJECT)" -scheme "$(SCHEME)" -derivedDataPath "$(DERIVED_DATA_PATH)" clean
	rm -rf "$(DERIVED_DATA_PATH)"

open:
	open "$(PROJECT)"
