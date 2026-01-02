import XCTest
@testable import ScaleUI

final class ScaleUITests: XCTestCase {
    func testSpacingValues() throws {
        XCTAssertEqual(ScaleSpacing.xs, 4)
        XCTAssertEqual(ScaleSpacing.sm, 8)
        XCTAssertEqual(ScaleSpacing.md, 12)
        XCTAssertEqual(ScaleSpacing.lg, 16)
        XCTAssertEqual(ScaleSpacing.xl, 24)
    }

    func testRadiusValues() throws {
        XCTAssertEqual(ScaleRadius.sm, 8)
        XCTAssertEqual(ScaleRadius.md, 12)
        XCTAssertEqual(ScaleRadius.lg, 16)
    }

    func testSizeValues() throws {
        XCTAssertEqual(ScaleSizes.minTouchTarget, 44)
        XCTAssertEqual(ScaleSizes.buttonHeight, 50)
    }
}
