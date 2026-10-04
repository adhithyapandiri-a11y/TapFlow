# TapFlow

TapFlow is an experimental native macOS utility that turns one, two, or three gentle taps on a supported MacBook into actions you choose.

> **Status:** source and local development build. The current `.app` is unsigned, no public release is published, and sensor compatibility is not guaranteed across Mac models. See [known limitations](#known-limitations) before relying on it.

## Features

- Configure separate actions for single, double, and triple taps.
- Open a webpage, launch an app, play a built-in sound or a sound file, or run a macOS Shortcut.
- Tune tap sensitivity, calibrate while the Mac is still, and adjust the sequence delay.
- Pause listening or open settings from the menu bar.
- Keep preferences local to this Mac.

## Requirements

- macOS 14 or later.
- A MacBook whose motion sensor is accessible through the HID interface used by TapFlow. This experimental interface is undocumented; not all models and macOS releases are confirmed to work.
- To build from source: Xcode or Xcode Command Line Tools with Swift 5.9+ and the macOS SDK.

## Download and install

There is not yet a signed public TapFlow release. For now, build it from source using the steps below. A local build is for development and should not be redistributed as a trusted consumer download.

After a public repository and signed release are published, use that repository's GitHub **Releases** page, download the macOS archive, extract `TapFlow.app`, and move it to `/Applications`.

## Build from source

Clone TapFlow and build the local app:

```sh
git clone https://github.com/adhithyapandiri-a11y/TapFlow.git
cd TapFlow
swift package resolve
bash scripts/package-app.sh
open "outputs/TapFlow.app"
```

The packaging script builds a release executable, generates the macOS app icon, and assembles `outputs/TapFlow.app`. The output directory is intentionally excluded from Git.

To run from Xcode, choose **File > Open**, select `Package.swift`, select the `TapFlow` scheme and **My Mac**, then press **Run**.

## First-time setup

Fresh installs start with all gesture actions disabled to avoid unexpected launches. Open **Tap actions**, choose an action for each gesture, and enable only the gestures you want.

For detailed setup and troubleshooting, see the [User Guide](docs/USER_GUIDE.md). Developers can start with [Development](docs/DEVELOPMENT.md) and [Architecture](docs/ARCHITECTURE.md).

## Known limitations

- TapFlow reads motion through undocumented Apple HID/IOKit interfaces. Availability, permissions, and sample behavior can vary by Mac and macOS version.
- The local app bundle is unsigned. Public distribution requires Apple Developer signing, hardened runtime configuration, notarization, and clean-machine verification.
- Shortcuts that request input or confirmation can show their own dialogs.
- A custom sound is stored as a local file path; moving or deleting that file will break the selection.
- The source code is licensed under the MIT License; see [LICENSE](LICENSE). The app is experimental and provided without warranty.

## Repository map

| Path | Purpose |
| --- | --- |
| `Package.swift` | Swift package, executable, and test target definitions |
| `Sources/TapFlow/UI` | App entry point and SwiftUI screens |
| `Sources/TapFlow/Actions` | User action models, preferences, and action launching |
| `Sources/TapFlow/Detection` | Tap recognition, calibration, and sequence timing |
| `Sources/TapFlow/Hardware` | IOKit motion-sensor discovery and report decoding |
| `Resources` | App metadata and source/generated icon assets |
| `Tests/TapFlowTests` | Hardware-independent unit tests |
| `scripts` | Icon generation and local app packaging |
| `docs` | User, architecture, development, QA, and release documentation |

## Privacy

TapFlow has no TapFlow-operated server, analytics, or account system. Preferences are stored locally by macOS. Configured actions can open websites, launch applications, play local audio, or invoke Shortcuts. Review those actions before enabling them. Read the [privacy and data notes](docs/USER_GUIDE.md#data-and-permissions).

## Contributing and contact

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [CHANGELOG.md](CHANGELOG.md). Developer: Adhithya Pandiri, [adhithyapandiri@gmail.com](mailto:adhithyapandiri@gmail.com).
