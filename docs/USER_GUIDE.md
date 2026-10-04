# User Guide

## Requirements

- A Mac running macOS 14 or later.
- A supported MacBook with motion hardware exposed through the sensor interface used by TapFlow. This is experimental and is not guaranteed on every model.
- For building from source: Swift 5.9 or later and Apple's macOS SDK. Xcode or Xcode Command Line Tools provide these tools.

## Download and install

### From a published release

No signed public release is published yet. When one is available, download the macOS archive from the project's GitHub **Releases** page, extract `TapFlow.app`, and move it to `/Applications`. Open TapFlow from Applications. Only install a release published by the project owner.

### Build from source

Clone the repository URL shown by GitHub's **Code** button, then run:

```sh
git clone <repository-url>
cd TapFlow
swift package resolve
bash scripts/package-app.sh
open "outputs/TapFlow.app"
```

The script builds the Swift package, creates the macOS icon, and writes the app bundle to `outputs/TapFlow.app`. This local development bundle is unsigned; it is not the same as a signed/notarized public release.

To open the package in Xcode, choose **File > Open** and select `Package.swift`. Select the `TapFlow` scheme and **My Mac**, then press **Run**. You can also build/package from Terminal using the commands above.

## First run

1. Open **Tap actions**.
2. Choose an action for Single tap, Double tap, or Triple tap.
3. Turn on only the gestures you want TapFlow to perform. New installations start with actions disabled.
4. For **Open webpage**, enter a complete URL such as `https://www.apple.com`.
5. For **Launch app**, enter an application name or choose an `.app` from the file picker.
6. For **Play sound**, select a built-in macOS sound or choose **Choose Sound File…**. TapFlow remembers the selected file's path, so keep the file in place and accessible.
7. For **Run Shortcut**, enter the shortcut's exact name as it appears in the Shortcuts app.

## Adjust tap detection

- **Sensitivity** controls how strong a motion pulse must be before it counts as a tap. Move toward *Gentler taps* for softer taps, or *Firmer taps* to ignore more movement.
- **Calibrate** samples the Mac while it is still. Set the Mac on a stable surface and do not touch it until calibration finishes.
- **Tap sequence delay** is the quiet period TapFlow waits after an impact to decide whether more taps are coming. A shorter delay responds faster but gives less time to complete a double or triple tap. A longer delay gives more time but makes single taps take longer to fire. The value is saved locally.
- **Test double tap** runs the configured double-tap action without touching the Mac.

## Menu bar and shortcuts

TapFlow runs as a menu-bar app and does not show a Dock icon. Closing its settings window leaves tap detection running; use the hand icon in the menu bar to reopen settings, pause/resume listening, or quit. Enable **Open at Login** in Settings to have macOS start TapFlow quietly in the background when you sign in. Keep TapFlow in `/Applications` and at the same location after enabling this option. If macOS asks for approval, allow it under **System Settings > General > Login Items**.

Shortcuts are invoked through macOS's `/usr/bin/shortcuts run` command. A shortcut that asks for input, requests confirmation, or otherwise needs user interaction may show a macOS/Shortcuts prompt. TapFlow cannot suppress interaction required by the shortcut itself.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Sensor says unavailable | Confirm macOS version and MacBook model; the sensor interface is undocumented and not universal. Restart TapFlow after changing hardware/system state. |
| Small touches trigger actions | Move sensitivity toward *Firmer taps*, calibrate on a stable surface, or pause listening from the menu bar. |
| Gentle taps are missed | Move sensitivity toward *Gentler taps* and recalibrate while the Mac is still. |
| Double/triple taps become separate actions | Increase tap-sequence delay and tap within that window. |
| Single action feels slow | Decrease tap-sequence delay; this reduces the time reserved for additional taps. |
| Custom sound does not play | Re-select a supported audio file and leave it at the selected location. |
| Shortcut opens a prompt | The shortcut likely contains an Ask for Input, confirmation, or other interactive action. Edit that shortcut if it should run unattended. |
| Website or app does not open | Verify the URL/app selection and check that the target app is installed. |

## Data and permissions

TapFlow stores gesture settings locally in macOS preferences. It does not upload settings or audio files to a TapFlow server. A configured action can still open a network URL or invoke another app/shortcut by design. The sensor uses an undocumented IOKit HID interface; availability may be restricted on some systems. Do not use hard impacts; TapFlow is designed for gentle taps.
