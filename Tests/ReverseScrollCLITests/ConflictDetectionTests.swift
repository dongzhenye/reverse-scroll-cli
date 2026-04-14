import XCTest

@testable import ReverseScrollCLI

final class ConflictDetectionTests: XCTestCase {
    func test_allToolsHaveAtLeastOneBundleIdentifier() {
        for tool in knownConflictingTools {
            XCTAssertFalse(tool.bundleIdentifiers.isEmpty, "\(tool.displayName) has no bundle IDs")
            XCTAssertFalse(tool.displayName.isEmpty)
        }
    }

    func test_bundleIdentifiersAreReverseDNS() {
        for tool in knownConflictingTools {
            for bid in tool.bundleIdentifiers {
                XCTAssertTrue(bid.contains("."), "\(bid) does not look like reverse-DNS")
            }
        }
    }
}
