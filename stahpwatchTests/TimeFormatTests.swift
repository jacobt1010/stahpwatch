import XCTest
@testable import stahpwatch

final class TimeFormatTests: XCTestCase {
    func testUnderAnHour() {
        XCTAssertEqual(TimeFormat.readout(0), "00:00.00")
        XCTAssertEqual(TimeFormat.readout(462.187), "07:42.18")
        XCTAssertEqual(TimeFormat.readout(3599.999), "59:59.99")
    }

    func testHourSwitch() {
        XCTAssertEqual(TimeFormat.readout(3600), "1:00:00.00")
        XCTAssertEqual(TimeFormat.readout(3735.33), "1:02:15.33")
        XCTAssertEqual(TimeFormat.readout(36000), "10:00:00.00")
    }

    func testNegativeClampsToZero() {
        XCTAssertEqual(TimeFormat.readout(-5), "00:00.00")
    }
}
