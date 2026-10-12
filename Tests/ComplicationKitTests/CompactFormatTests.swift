import Foundation
import Testing
@testable import ComplicationKit

@Suite("CompactNumber")
struct CompactNumberTests {
    @Test func smallNumbersStayWhole() {
        #expect(CompactNumber.string(0) == "0")
        #expect(CompactNumber.string(7) == "7")
        #expect(CompactNumber.string(950) == "950")
        #expect(CompactNumber.string(999) == "999")
    }

    @Test func fractionsBelowTen() {
        #expect(CompactNumber.string(0.75) == "0.8")
        #expect(CompactNumber.string(1.2) == "1.2")
        #expect(CompactNumber.string(2.0) == "2")
        #expect(CompactNumber.string(9.96) == "10")
        #expect(CompactNumber.string(1.25, maximumFractionDigits: 2) == "1.25")
        #expect(CompactNumber.string(1.5, maximumFractionDigits: 0) == "2")
    }

    @Test func suffixes() {
        #expect(CompactNumber.string(1_000) == "1K")
        #expect(CompactNumber.string(1_234) == "1.2K")
        #expect(CompactNumber.string(12_480) == "12K")
        #expect(CompactNumber.string(2_500_000) == "2.5M")
        #expect(CompactNumber.string(3_100_000_000) == "3.1B")
        #expect(CompactNumber.string(1_500_000_000_000) == "1.5T")
    }

    @Test func roundingMovesToTheNextUnit() {
        #expect(CompactNumber.string(999_600) == "1M")
        #expect(CompactNumber.string(999_499) == "999K")
    }

    @Test func negativeValues() {
        #expect(CompactNumber.string(-1_234) == "-1.2K")
        #expect(CompactNumber.string(-0.01) == "0")
    }

    @Test func specialValues() {
        #expect(CompactNumber.string(.nan) == "--")
        #expect(CompactNumber.string(.infinity) == "∞")
        #expect(CompactNumber.string(-.infinity) == "-∞")
    }
}

@Suite("CompactTime")
struct CompactTimeTests {
    @Test func abbreviated() {
        #expect(CompactTime.abbreviated(0) == "0s")
        #expect(CompactTime.abbreviated(45) == "45s")
        #expect(CompactTime.abbreviated(59.9) == "59s")
        #expect(CompactTime.abbreviated(720) == "12m")
        #expect(CompactTime.abbreviated(3_900) == "1h 5m")
        #expect(CompactTime.abbreviated(7_200) == "2h")
        #expect(CompactTime.abbreviated(86_400) == "1d")
        #expect(CompactTime.abbreviated(3 * 86_400 + 4 * 3_600 + 59) == "3d 4h")
    }

    @Test func shortest() {
        #expect(CompactTime.shortest(45) == "45s")
        #expect(CompactTime.shortest(754) == "12m")
        #expect(CompactTime.shortest(5_400) == "1h")
        #expect(CompactTime.shortest(3 * 86_400 + 5) == "3d")
    }

    @Test func clock() {
        #expect(CompactTime.clock(45) == "0:45")
        #expect(CompactTime.clock(754) == "12:34")
        #expect(CompactTime.clock(3_900) == "1:05:00")
        #expect(CompactTime.clock(59.99) == "0:59")
    }

    @Test func invalidDurations() {
        #expect(CompactTime.abbreviated(-30) == "0s")
        #expect(CompactTime.clock(-30) == "0:00")
        #expect(CompactTime.abbreviated(.nan) == "--")
        #expect(CompactTime.shortest(.nan) == "--")
        #expect(CompactTime.clock(.nan) == "--:--")
        #expect(CompactTime.shortest(.infinity) == "36500d")
    }
}
