# Release Checklist

The repository currently produces a local unsigned app bundle only. Do not describe that output as ready for public distribution or sale.

## Before a release

1. Confirm the target Mac models and macOS versions on real hardware; the sensor API is undocumented.
2. Run `swift test` and `bash scripts/package-app.sh` from a clean checkout.
3. Test action configuration, custom sound selection, delay persistence, calibration, menu-bar pause/resume, and shortcut behavior.
4. Review defaults and remove development URLs, test data, credentials, and local paths.
5. Update `CHANGELOG.md`, version values in `Resources/Info.plist`, and release notes.
6. Sign the app with an Apple Developer ID and enable the required hardened runtime settings.
7. Notarize the signed app with Apple and staple the notarization ticket. Verify the final artifact on a clean Mac.
8. Package the app as a versioned ZIP or DMG, publish it under GitHub Releases, and include checksums and known limitations.

## Distribution warning

Users should not be told to bypass Gatekeeper for an unsigned download. Ship a signed and notarized application before recommending installation to the general public. If future sensor access requires a privileged helper or additional entitlements, document and review that security boundary before release.
