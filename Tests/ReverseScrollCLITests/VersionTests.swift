import XCTest

@testable import ReverseScrollCLI

final class VersionTests: XCTestCase {
    func test_versionIsSemver() {
        let pattern = #"^\d+\.\d+\.\d+(-[a-z0-9.]+)?$"#
        let value = ReverseScrollCLI.version
        XCTAssertNotNil(
            value.range(of: pattern, options: .regularExpression),
            "version '\(value)' is not semver-shaped"
        )
    }
}
