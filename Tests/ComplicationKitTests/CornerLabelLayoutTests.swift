import CoreGraphics
import Foundation
import Testing
@testable import ComplicationKit

@Suite("CornerLabelLayout")
struct CornerLabelLayoutTests {
    /// A 46mm screen.
    let face = CGSize(width: 208, height: 248)

    @Test func corners() {
        #expect(ComplicationCorner(point: CGPoint(x: 10, y: 10), faceSize: face) == .topLeading)
        #expect(ComplicationCorner(point: CGPoint(x: 200, y: 10), faceSize: face) == .topTrailing)
        #expect(ComplicationCorner(point: CGPoint(x: 10, y: 240), faceSize: face) == .bottomLeading)
        #expect(ComplicationCorner(point: CGPoint(x: 200, y: 240), faceSize: face) == .bottomTrailing)
        #expect(ComplicationCorner.topLeading.isTop)
        #expect(!ComplicationCorner.bottomTrailing.isTop)
        #expect(ComplicationCorner.bottomLeading.isLeading)
        #expect(!ComplicationCorner.topTrailing.isLeading)
    }

    @Test func bottomLeadingStartsAtTheContentAndRunsRight() {
        let content = CGRect(x: 6, y: 204, width: 38, height: 38)
        let arc = CornerLabelLayout.arc(faceSize: face, content: content, length: 60, gap: 4, inset: 8)
        #expect(!arc.isTop)
        #expect(arc.center == CGPoint(x: 104, y: 124))
        #expect(arc.radius == 116)
        let start = arc.point(atAngle: arc.startAngle)
        #expect(isClose(Double(start.x), 48, tolerance: 1e-6))
        #expect(start.y > arc.center.y)
        let end = arc.point(atAngle: arc.endAngle)
        #expect(end.x > start.x)
        // The arc is as long as the label.
        let length = abs(arc.endAngle - arc.startAngle) * .pi / 180 * Double(arc.radius)
        #expect(isClose(length, 60, tolerance: 1e-6))
    }

    @Test func bottomTrailingEndsAtTheContent() {
        let content = CGRect(x: 164, y: 204, width: 38, height: 38)
        let arc = CornerLabelLayout.arc(faceSize: face, content: content, length: 40, gap: 4, inset: 8)
        #expect(!arc.isTop)
        let end = arc.point(atAngle: arc.endAngle)
        #expect(isClose(Double(end.x), 160, tolerance: 1e-6))
        #expect(arc.point(atAngle: arc.startAngle).x < end.x)
    }

    @Test func topCornersRunAlongTheTop() {
        let leading = CornerLabelLayout.arc(faceSize: face, content: CGRect(x: 6, y: 6, width: 38, height: 38), length: 50)
        #expect(leading.isTop)
        let leadingStart = leading.point(atAngle: leading.startAngle)
        #expect(leadingStart.y < leading.center.y)
        #expect(isClose(Double(leadingStart.x), 48, tolerance: 1e-6))

        let trailing = CornerLabelLayout.arc(faceSize: face, content: CGRect(x: 164, y: 6, width: 38, height: 38), length: 50)
        #expect(trailing.isTop)
        let trailingEnd = trailing.point(atAngle: trailing.endAngle)
        #expect(isClose(Double(trailingEnd.x), 160, tolerance: 1e-6))
    }

    @Test func distanceAlongTheArc() {
        let arc = CornerLabelArc(center: .zero, radius: 100, startAngle: 180, endAngle: 90)
        #expect(!arc.isTop)
        #expect(isClose(arc.angle(atDistance: 0), 180))
        #expect(isClose(arc.angle(atDistance: 50 * .pi), 90))
        let top = CornerLabelArc(center: .zero, radius: 100, startAngle: 200, endAngle: 260)
        #expect(isClose(top.angle(atDistance: 100 * .pi / 6), 230))
        let flat = CornerLabelArc(center: .zero, radius: 0, startAngle: 10, endAngle: 20)
        #expect(flat.angle(atDistance: 30) == 10)
    }

    @Test func glyphsStandUpright() {
        let bottom = CornerLabelArc(center: .zero, radius: 100, startAngle: 135, endAngle: 90)
        // At 90° (straight down) a glyph on the bottom is not rotated.
        #expect(isClose(bottom.glyphRotation(atAngle: 90), 0))
        let top = CornerLabelArc(center: .zero, radius: 100, startAngle: 225, endAngle: 270)
        // At 270° (straight up) a glyph on the top is upright too (a full turn).
        #expect(isClose(top.glyphRotation(atAngle: 270).truncatingRemainder(dividingBy: 360), 0))
        let point = top.point(atAngle: 270)
        #expect(isClose(Double(point.x), 0, tolerance: 1e-9))
        #expect(isClose(Double(point.y), -100, tolerance: 1e-9))
    }
}

@Suite("WatchFaceLayout")
struct WatchFaceLayoutTests {
    @Test func everySlotFitsOnTheScreen() {
        for size in [CGSize(width: 208, height: 248), CGSize(width: 205, height: 251), CGSize(width: 162, height: 197)] {
            let layout = WatchFaceLayout(size: size)
            let metrics = layout.metrics
            let slots: [(CGPoint, CGSize)] = [
                (layout.inlineCenter, CGSize(width: layout.inlineWidth, height: metrics.inline.height)),
                (layout.rectangularCenter, metrics.rectangular),
                (layout.circularCenter, metrics.circular),
                (layout.leadingCornerCenter, metrics.corner),
                (layout.trailingCornerCenter, metrics.corner),
            ]
            for (center, slotSize) in slots {
                #expect(center.x - slotSize.width / 2 >= 0)
                #expect(center.x + slotSize.width / 2 <= size.width)
                #expect(center.y - slotSize.height / 2 >= 0)
                #expect(center.y + slotSize.height / 2 <= size.height)
            }
        }
    }

    @Test func metricsFollowTheScreen() {
        #expect(WatchFaceLayout(size: CGSize(width: 208, height: 248)).metrics == .mm45)
        #expect(WatchFaceLayout(size: CGSize(width: 162, height: 197)).metrics == .mm40)
    }
}
