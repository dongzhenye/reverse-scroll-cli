import XCTest

@testable import ReverseScrollCLI

// Placeholder to satisfy SwiftPM's declared test target until real tests land
// (ConflictDetectionTests in Task 5, VersionTests in Task 6).
final class PlaceholderTests: XCTestCase {
    func test_packageCompiles() {
        XCTAssertFalse(ReverseScrollCLI.version.isEmpty)
    }
}
