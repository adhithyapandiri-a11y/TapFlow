# Architecture

## Runtime flow

1. `TapFlowApp` creates the settings store and tap detector, connects persisted actions to the detector, and exposes the main window and menu-bar extra.
2. `AccelerometerReader` opens the Apple Silicon motion-sensor HID interface through IOKit and delivers accelerometer samples from its worker run loop.
3. `TapDetector` follows the slow gravity baseline, measures the remaining motion impulse, applies the configured sensitivity threshold and retrigger guard, and groups impacts until the configured sequence delay expires.
4. The detector dispatches the one-, two-, or three-tap action configured in `TapActionSettings`.
5. `BrowserOpener` performs the selected external action: open a webpage, launch an app, or run a named macOS Shortcut. Sound actions use `NSSound` for a system sound or a user-selected audio-file path.

## Main modules

- `Sources/TapFlow/UI`: SwiftUI app entry point, navigation, action editor, settings, and About view.
- `Sources/TapFlow/Actions`: action model, persisted user preferences, file pickers, and external action launching.
- `Sources/TapFlow/Detection`: motion sample filtering, tap recognition, calibration, and action dispatch.
- `Sources/TapFlow/Hardware`: IOKit HID sensor discovery, lifecycle, and raw report decoding.
- `Resources`: app bundle metadata and source/generated app-icon artwork.
- `scripts`: app-icon generation and local `.app` packaging.
- `Tests/TapFlowTests`: hardware-independent unit tests.

## Settings and privacy

Action choices, sensitivity, and sequence delay are stored locally in `UserDefaults` under TapFlow's bundle identifier (`com.taptrigger.app`). A custom sound is stored as a file path; the audio file is not copied into TapFlow. The app does not implement analytics or a TapFlow-operated backend. Configured webpage, app, and shortcut actions are passed to their respective macOS applications/services.

## Sensor compatibility

The current sensor reader matches undocumented Apple HID service and usage identifiers associated with Apple Silicon motion hardware. Apple does not publish this interface as a stable third-party API. Availability and behavior can change by Mac model and macOS version; unsupported systems display an unavailable status instead of recognizing taps.
