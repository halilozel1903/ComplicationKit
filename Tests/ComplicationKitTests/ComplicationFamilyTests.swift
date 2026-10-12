import CoreGraphics
import Foundation
import Testing
@testable import ComplicationKit

@Suite("ComplicationFamily")
struct ComplicationFamilyTests {
    @Test func resolveOrder() {
        #expect(ComplicationFamily.resolve(explicit: .inline, override: .corner, widget: .rectangular) == .inline)
        #expect(ComplicationFamily.resolve(explicit: nil, override: .corner, widget: .rectangular) == .corner)
        #expect(ComplicationFamily.resolve(explicit: nil, override: nil, widget: .rectangular) == .rectangular)
        #expect(ComplicationFamily.resolve(explicit: nil, override: nil, widget: nil) == .circular)
    }

    @Test func names() {
        #expect(ComplicationFamily.allCases.map(\.displayName) == ["Circular", "Corner", "Rectangular", "Inline"])
    }
}

@Suite("ComplicationMetrics")
struct ComplicationMetricsTests {
    @Test func screenWidths() {
        #expect(ComplicationMetrics.forScreen(width: 162).caseSize == .mm40)
        #expect(ComplicationMetrics.forScreen(width: 176).caseSize == .mm41)
        #expect(ComplicationMetrics.forScreen(width: 184).caseSize == .mm44)
        #expect(ComplicationMetrics.forScreen(width: 187).caseSize == .mm44)
        #expect(ComplicationMetrics.forScreen(width: 198).caseSize == .mm45)
        #expect(ComplicationMetrics.forScreen(width: 205).caseSize == .mm45)
        #expect(ComplicationMetrics.forScreen(width: 208).caseSize == .mm45)
    }

    @Test func caseSizes() {
        for caseSize in WatchCaseSize.allCases {
            #expect(ComplicationMetrics.of(caseSize).caseSize == caseSize)
        }
    }

    @Test func largestWatchSizes() {
        let metrics = ComplicationMetrics.mm45
        #expect(metrics.size(for: .circular) == CGSize(width: 50, height: 50))
        #expect(metrics.size(for: .corner) == CGSize(width: 38, height: 38))
        #expect(metrics.size(for: .rectangular) == CGSize(width: 193, height: 82))
        #expect(metrics.size(for: .inline).width == 193)
    }

    @Test func sizesGrowWithTheWatch() {
        let all = WatchCaseSize.allCases.map(ComplicationMetrics.of)
        for family in ComplicationFamily.allCases {
            let widths = all.map { $0.size(for: family).width }
            #expect(widths == widths.sorted())
        }
    }
}

@Suite("ComplicationInk")
struct ComplicationInkTests {
    @Test func fullColorKeepsColors() {
        for role in ComplicationInkRole.allCases {
            #expect(ComplicationInk.resolve(role: role, mode: .fullColor, hasPreviewTint: true) == .original)
            #expect(ComplicationInk.resolve(role: role, mode: .fullColor, hasPreviewTint: false) == .original)
        }
    }

    @Test func accentedFaces() {
        #expect(ComplicationInk.resolve(role: .accent, mode: .accented, hasPreviewTint: true) == .tint)
        #expect(ComplicationInk.resolve(role: .accent, mode: .accented, hasPreviewTint: false) == .white(opacity: 1))
        #expect(ComplicationInk.resolve(role: .primary, mode: .accented, hasPreviewTint: true) == .white(opacity: 1))
        #expect(ComplicationInk.resolve(role: .secondary, mode: .accented, hasPreviewTint: true) == .white(opacity: 0.6))
    }

    @Test func vibrantLockScreen() {
        #expect(ComplicationInk.resolve(role: .accent, mode: .vibrant, hasPreviewTint: true) == .white(opacity: 1))
        #expect(ComplicationInk.resolve(role: .primary, mode: .vibrant, hasPreviewTint: false) == .white(opacity: 1))
        #expect(ComplicationInk.resolve(role: .secondary, mode: .vibrant, hasPreviewTint: false) == .white(opacity: 0.55))
    }
}
