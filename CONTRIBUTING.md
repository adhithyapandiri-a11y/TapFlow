# Contributing

Thanks for helping improve TapFlow. The project is a native macOS Swift package.

## Before opening a change

1. Open an issue for significant behavior changes so the expected behavior can be discussed first.
2. Keep changes focused and follow the existing SwiftUI and Swift conventions.
3. Do not commit generated app bundles, build output, personal settings, credentials, or private shortcut data.
4. Add or update tests for behavior that can be verified without physical sensor hardware.
5. Run `swift test` and `bash scripts/package-app.sh` before submitting.

## Pull requests

Include the user-visible behavior change, the hardware/macOS configurations tested, and any known limitations. UI changes should include screenshots in both light and dark appearances when practical. Sensor changes should describe the Mac model and macOS version used for validation.

## Scope and safety

The accelerometer interface is undocumented and hardware-dependent. Do not present experimental sensor behavior as supported on every Mac. TapFlow should only perform the actions explicitly configured by the user.
