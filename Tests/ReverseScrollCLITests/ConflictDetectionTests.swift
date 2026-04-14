import XCTest

@testable import ReverseScrollCLI

final class ConflictDetectionTests: XCTestCase {
    func test_allToolsHaveAtLeastOneBundleIdentifier() {
        for tool in knownConflictingTools {
            XCTAssertFalse(tool.bundleIdentifiers.isEmpty, "\(tool.displayName) has no bundle IDs")
            XCTAssertFalse(tool.displayName.isEmpty, "A ConflictingTool entry has empty displayName")
        }
    }

    /// Structural reverse-DNS check: ≥2 dot-separated segments, no empty or 1-char segments.
    /// Note: this cannot catch factual errors (e.g., `cn.caldis.Mos` vs `com.caldis.Mos` both pass);
    /// bundle ID correctness is guarded by evidence in the commit that introduced each entry.
    func test_bundleIdentifiersAreWellFormedReverseDNS() {
        for tool in knownConflictingTools {
            for bid in tool.bundleIdentifiers {
                let components = bid.split(separator: ".", omittingEmptySubsequences: false)
                XCTAssertGreaterThanOrEqual(
                    components.count, 2,
                    "\(bid) needs ≥2 DNS segments"
                )
                XCTAssertTrue(
                    components.allSatisfy { $0.count >= 2 },
                    "\(bid) has an empty or 1-char segment"
                )
            }
        }
    }
}
