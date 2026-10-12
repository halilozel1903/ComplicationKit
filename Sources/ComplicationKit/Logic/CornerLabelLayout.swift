import CoreGraphics
import Foundation

/// A corner of the watch face.
public enum ComplicationCorner: String, CaseIterable, Hashable, Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    /// The corner that a frame centered at `point` belongs to on a face of `faceSize`.
    public init(point: CGPoint, faceSize: CGSize) {
        let isTop = point.y < faceSize.height / 2
        let isLeading = point.x < faceSize.width / 2
        switch (isTop, isLeading) {
        case (true, true): self = .topLeading
        case (true, false): self = .topTrailing
        case (false, true): self = .bottomLeading
        case (false, false): self = .bottomTrailing
        }
    }

    /// `true` for the two top corners.
    public var isTop: Bool { self == .topLeading || self == .topTrailing }

    /// `true` for the two leading corners.
    public var isLeading: Bool { self == .topLeading || self == .bottomLeading }
}

/// Where the curved label of a corner complication goes: an arc of a circle around the center of the face.
///
/// Angles are in degrees, measured clockwise from the positive x axis in SwiftUI's coordinates (y grows
/// downwards), so 90° is straight down and 270° straight up. The label reads from `startAngle` to `endAngle`:
/// on top corners the angle grows (left to right along the top, letters standing outwards), on bottom corners it
/// shrinks (left to right along the bottom, letters standing towards the center).
public struct CornerLabelArc: Equatable, Sendable {
    /// The center of the circle, the center of the face.
    public var center: CGPoint
    /// The radius of the circle the middle of the label follows.
    public var radius: CGFloat
    /// The angle where reading starts.
    public var startAngle: Double
    /// The angle where reading ends.
    public var endAngle: Double

    public init(center: CGPoint, radius: CGFloat, startAngle: Double, endAngle: Double) {
        self.center = center
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
    }

    /// `true` when the label runs along the top of the face.
    public var isTop: Bool { endAngle > startAngle }

    /// The angle `distance` points along the label from its start.
    public func angle(atDistance distance: CGFloat) -> Double {
        guard radius > 0 else { return startAngle }
        let degrees = Double(distance / radius) * 180 / .pi
        return isTop ? startAngle + degrees : startAngle - degrees
    }

    /// The point at `angle` on a circle of `radius` (by default the arc's own) around the center.
    public func point(atAngle angle: Double, radius: CGFloat? = nil) -> CGPoint {
        let radians = angle * .pi / 180
        let radius = radius ?? self.radius
        return CGPoint(x: center.x + radius * CGFloat(cos(radians)), y: center.y + radius * CGFloat(sin(radians)))
    }

    /// The rotation for a glyph at `angle` so that its baseline follows the arc in reading direction.
    public func glyphRotation(atAngle angle: Double) -> Double {
        isTop ? angle + 90 : angle - 90
    }
}

/// Places the curved labels of corner complications on a watch face.
public enum CornerLabelLayout {
    /// The arc for a label `length` points long next to a corner complication whose content occupies `content`
    /// on a face of `faceSize`. The label starts `gap` points past the content and follows a circle around the face
    /// center, `inset` points inside the top and bottom edges, running towards the middle of the face.
    public static func arc(
        faceSize: CGSize,
        content: CGRect,
        length: CGFloat,
        gap: CGFloat = 4,
        inset: CGFloat = 8
    ) -> CornerLabelArc {
        let center = CGPoint(x: faceSize.width / 2, y: faceSize.height / 2)
        let radius = max(min(faceSize.height, faceSize.width * 1.4) / 2 - inset, 1)
        let corner = ComplicationCorner(point: CGPoint(x: content.midX, y: content.midY), faceSize: faceSize)
        let span = Double(max(length, 0) / radius) * 180 / .pi

        // The x where the label touches the content, and the angle of that point on the circle.
        let edgeX = corner.isLeading ? content.maxX + gap : content.minX - gap
        let cosine = Double(min(max((edgeX - center.x) / radius, -1), 1))
        let lowerAngle = acos(cosine) * 180 / .pi   // 0...180: the bottom half
        let edgeAngle = corner.isTop ? 360 - lowerAngle : lowerAngle

        switch corner {
        case .topLeading:
            // Starts at the content and runs right, towards 270°.
            return CornerLabelArc(center: center, radius: radius, startAngle: edgeAngle, endAngle: edgeAngle + span)
        case .topTrailing:
            // Ends at the content.
            return CornerLabelArc(center: center, radius: radius, startAngle: edgeAngle - span, endAngle: edgeAngle)
        case .bottomLeading:
            // Starts at the content and runs right, towards 90°.
            return CornerLabelArc(center: center, radius: radius, startAngle: edgeAngle, endAngle: edgeAngle - span)
        case .bottomTrailing:
            return CornerLabelArc(center: center, radius: radius, startAngle: edgeAngle + span, endAngle: edgeAngle)
        }
    }
}
