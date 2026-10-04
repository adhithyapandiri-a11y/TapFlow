import XCTest
@testable import TapFlow

final class TapActionSettingsTests: XCTestCase {
    func testDefaultActionsCoverEachSupportedGesture() {
        XCTAssertEqual(TapGestureAction.defaults.map(\.tapCount), [1, 2, 3])
    }

    func testFreshInstallDefaultsDoNotRunActionsWithoutSetup() {
        XCTAssertTrue(TapGestureAction.defaults.allSatisfy { !$0.isEnabled })
        XCTAssertEqual(TapGestureAction.defaults.first(where: { $0.tapCount == 2 })?.value, "")
    }

    func testGestureTitlesMatchTapCounts() {
        XCTAssertEqual(TapGestureAction(tapCount: 1, kind: .playSound, value: "Glass", isEnabled: false).gestureTitle, "Single tap")
        XCTAssertEqual(TapGestureAction(tapCount: 2, kind: .playSound, value: "Glass", isEnabled: false).gestureTitle, "Double tap")
        XCTAssertEqual(TapGestureAction(tapCount: 3, kind: .playSound, value: "Glass", isEnabled: false).gestureTitle, "Triple tap")
    }

    func testBuiltInSoundListExcludesRemovedCustomSound() {
        XCTAssertFalse(TapGestureAction.soundNames.contains("Mourn"))
        XCTAssertTrue(TapGestureAction.soundNames.contains("Glass"))
    }
}
