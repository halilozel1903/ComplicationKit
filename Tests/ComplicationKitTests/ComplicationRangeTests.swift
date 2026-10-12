import Foundation
import Testing
@testable import ComplicationKit

@Suite("ComplicationRange")
struct ComplicationRangeTests {
    let range = ComplicationRange(40...200)

    @Test func boundsAreSortedAndFinite() {
        let swapped = ComplicationRange(10, 0)
        #expect(swapped.lowerBound == 0)
        #expect(swapped.upperBound == 10)
        let broken = ComplicationRange(.nan, .infinity)
        #expect(broken.lowerBound == 0)
        #expect(broken.upperBound == 1)
        #expect(ComplicationRange.unit.closedRange == 0...1)
    }

    @Test func clamp() {
        #expect(range.clamp(260) == 200)
        #expect(range.clamp(10) == 40)
        #expect(range.clamp(120) == 120)
        #expect(range.clamp(.nan) == 40)
        #expect(range.clamp(.infinity) == 200)
    }

    @Test func fraction() {
        #expect(range.fraction(of: 40) == 0)
        #expect(range.fraction(of: 120) == 0.5)
        #expect(range.fraction(of: 200) == 1)
        #expect(range.fraction(of: 500) == 1)
        #expect(range.fraction(of: -5) == 0)
        #expect(range.fraction(of: .nan) == 0)
    }

    @Test func emptyRange() {
        let empty = ComplicationRange(5, 5)
        #expect(empty.span == 0)
        #expect(empty.fraction(of: 5) == 1)
        #expect(empty.fraction(of: 4) == 0)
        #expect(empty.value(atFraction: 0.7) == 5)
    }

    @Test func valueAtFraction() {
        #expect(range.value(atFraction: 0.25) == 80)
        #expect(range.value(atFraction: 2) == 200)
        #expect(range.value(atFraction: -1) == 40)
        #expect(range.value(atFraction: .nan) == 40)
    }

    @Test func ticks() {
        let expected: [Double] = [0, 5, 10]
        #expect(ComplicationRange(0, 10).ticks(count: 3) == expected)
        #expect(ComplicationRange(0, 10).ticks(count: 0).isEmpty)
        #expect(ComplicationRange(0, 10).ticks(count: 1).count == 1)
        let thirds = ComplicationRange(0, 1).ticks(count: 4)
        #expect(thirds.count == 4)
        #expect(thirds.last == 1)
    }
}

@Suite("ComplicationValue")
struct ComplicationValueTests {
    @Test func clamp() {
        #expect(ComplicationValue.clamp(1.4, to: 0...1) == 1)
        #expect(ComplicationValue.clamp(-3, to: 0...1) == 0)
        #expect(ComplicationValue.clamp(.nan, to: 2...4) == 2)
    }

    @Test func progress() {
        #expect(isClose(ComplicationValue.progress(1.2, goal: 2), 0.6))
        #expect(ComplicationValue.progress(3, goal: 2) == 1)
        #expect(ComplicationValue.progress(-1, goal: 2) == 0)
        #expect(ComplicationValue.progress(1, goal: 0) == 1)
        #expect(ComplicationValue.progress(0, goal: 0) == 0)
        #expect(ComplicationValue.progress(.nan, goal: 2) == 0)
        #expect(ComplicationValue.progress(1, goal: .nan) == 0)
    }
}

@Suite("ComplicationChart")
struct ComplicationChartTests {
    @Test func relativeToTheLargestValue() {
        let fractions = ComplicationChart.barFractions([0, 1, 2, 4])
        let expected: [Double] = [0, 0.25, 0.5, 1]
        #expect(isClose(fractions, expected))
    }

    @Test func smallValuesStayVisible() {
        let fractions = ComplicationChart.barFractions([1, 100])
        let expected: [Double] = [0.06, 1]
        #expect(isClose(fractions, expected))
    }

    @Test func explicitMaximum() {
        let fractions = ComplicationChart.barFractions([2, 8, 16], maximum: 8, minimumFraction: 0)
        let expected: [Double] = [0.25, 1, 1]
        #expect(isClose(fractions, expected))
    }

    @Test func invalidValuesDrawNoBar() {
        let fractions = ComplicationChart.barFractions([-2, .nan, .infinity, 4])
        let expected: [Double] = [0, 0, 0, 1]
        #expect(isClose(fractions, expected))
        let zeros = ComplicationChart.barFractions([0, 0])
        let expectedZeros: [Double] = [0, 0]
        #expect(zeros == expectedZeros)
        #expect(ComplicationChart.barFractions([]).isEmpty)
    }
}
