# QA Checklist

Use this checklist before tagging a release. Sensor checks require supported physical MacBook hardware.

## Automated

- [ ] `swift test`
- [ ] `bash scripts/package-app.sh`
- [ ] `plutil -lint outputs/TapFlow.app/Contents/Info.plist`
- [ ] Confirm the generated `.app` contains its executable and `AppIcon.icns`.

## Manual UI

- [ ] Launch the app and open each sidebar section.
- [ ] Configure and disable each action kind; verify the action value stays associated with the correct gesture.
- [ ] Choose a custom sound, restart the app, and verify the selection persists and plays.
- [ ] Adjust sensitivity and sequence delay, restart, and verify both values persist.
- [ ] Check the menu-bar pause/resume and quit controls.
- [ ] Confirm closing the settings window leaves TapFlow running in the menu bar.
- [ ] Enable/disable Open at Login and verify its state in System Settings > General > Login Items and after signing out/in.
- [ ] On a fresh user profile, confirm Open at Login registers on first launch and can be disabled.
- [ ] Check light and dark system appearances, long file names/URLs, and window resizing.

## Hardware and OS

- [ ] Record Mac model, chip, and macOS version.
- [ ] Confirm sensor status, calibration, and deliberately gentle single/double/triple taps.
- [ ] Verify the configured website, app, sound, and shortcut actions independently.
- [ ] Test at least one shortcut with no interaction and one that requires input; note that interactive shortcuts may present UI.
