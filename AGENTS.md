# Repository Guidelines

## Project Structure & Module Organization

This repository contains a small macOS menu bar app built with SwiftUI and an Xcode project.

- `CodexProfileSwitcher/ContentView.swift` contains the application UI, profile store, file persistence, and Codex restart logic.
- `CodexProfileSwitcher/Assets.xcassets/` contains app icon assets.
- `Assets/Screenshots/` stores README screenshots.
- `Casks/codex-profile-switcher.rb` contains the Homebrew cask definition.
- `Codex Profile Switcher.xcodeproj/` contains the Xcode project and scheme metadata.
- `Makefile` wraps common local development commands.

There is currently no dedicated test target or test directory.

## Build, Test, and Development Commands

- `make help` lists available repository tasks.
- `make list` prints Xcode targets, configurations, and schemes.
- `make build` builds the default `Debug` configuration.
- `make build-debug` builds the Debug configuration explicitly.
- `make build-release` builds the Release configuration.
- `make build-unsigned` builds with `CODE_SIGNING_ALLOWED=NO`, useful on machines without the project signing certificate.
- `make clean` removes Xcode build products under `.build/DerivedData`.
- `make open` opens the Xcode project.

Equivalent direct build example:

```sh
xcodebuild -project "Codex Profile Switcher.xcodeproj" -scheme CodexProfileSwitcher -configuration Debug build
```

## Coding Style & Naming Conventions

Use Swift and SwiftUI conventions already present in `ContentView.swift`: 4-space indentation, descriptive type names, lowerCamelCase properties and methods, and UpperCamelCase structs/classes. Keep persistence helpers scoped inside `ProfileStore` unless they become reusable across files. Avoid broad refactors when making targeted behavior changes.

## Testing Guidelines

No automated test suite is currently configured. For changes to app logic, run `make build-unsigned` at minimum. For UI or profile-management changes, also verify the relevant workflow manually in Xcode or the built app. If adding tests later, prefer a standard Xcode test target and name tests after behavior, for example `testRenamingProfileAvoidsFileNameCollision`.

## Commit & Pull Request Guidelines

Prefer Conventional Commits, for example `fix(profile): avoid filename collisions`. Keep the subject concise and use the body to explain motivation, impact, and verification. Pull requests should include a summary, testing notes, linked issues when applicable, and screenshots for visible UI changes.

## Security & Configuration Tips

Profile and Codex configuration files may contain sensitive provider settings. Preserve private file permissions when changing persistence code, and avoid logging profile contents, auth snapshots, or token-bearing paths.
