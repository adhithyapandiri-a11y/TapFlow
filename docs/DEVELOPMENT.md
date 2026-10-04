# Development

## Repository layout

```text
TapFlow/
|-- Package.swift
|-- Sources/TapFlow/
|   |-- Actions/
|   |-- Detection/
|   |-- Hardware/
|   `-- UI/
|-- Tests/TapFlowTests/
|-- Resources/
|-- scripts/
|-- docs/
|-- README.md
|-- CONTRIBUTING.md
|-- CHANGELOG.md
`-- SECURITY.md
```

Generated `.build`, `.swiftpm`, Xcode state, `outputs`, and distribution archives are ignored by Git.

## Build and test

```sh
swift package resolve
swift test
bash scripts/package-app.sh
```

Run the app from `outputs/TapFlow.app`. The package uses the native macOS SDK and has no third-party package dependencies.

`swift test` needs Xcode's XCTest framework. If Xcode is installed but the active developer directory is only Command Line Tools and XCTest cannot be found, run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

This selects Xcode for that command only; it does not change the system-wide `xcode-select` setting.

## Editing notes

- Keep hardware interaction in `Hardware` and gesture recognition in `Detection` so they can be reasoned about separately.
- Keep stored user choices backward-compatible where practical. The app's bundle identifier is intentionally stable because macOS uses it to scope saved preferences.
- `scripts/make-app-icon.swift` crops the supplied square source artwork and creates all iconset sizes. `scripts/package-app.sh` converts the iconset to `.icns`, builds the release executable, and assembles the `.app` bundle.
- The sensor implementation cannot be fully exercised by ordinary unit tests. Validate on supported physical MacBook hardware and record the model and macOS version when reporting results.
- Before sharing changes, run `swift test` and build the app. For UI changes, check both macOS light and dark appearances and confirm long URLs, custom file names, and small window sizes remain usable.
