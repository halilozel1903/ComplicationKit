import SwiftUI

/// One line of text with an optional symbol, for `.accessoryInline`.
///
/// Inline complications are drawn by the face in its own font and color: only one symbol and one text are shown,
/// and anything else is ignored. When the text does not fit, the shorter `compactText` is used.
///
/// ```swift
/// InlineComplication(symbolName: "drop.fill", text: "1.2 of 2 L", compactText: "1.2 L")
/// ```
public struct InlineComplication: View {
    private let symbolName: String?
    private let text: String
    private let compactText: String?

    public init(symbolName: String? = nil, text: String, compactText: String? = nil) {
        self.symbolName = symbolName
        self.text = text
        self.compactText = compactText
    }

    public var body: some View {
        ComplicationStyleReader { style in
            ViewThatFits(in: .horizontal) {
                line(text)
                if let compactText {
                    line(compactText)
                }
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(style.color(.white, role: .primary))
        }
    }

    private func line(_ text: String) -> some View {
        HStack(spacing: 4) {
            if let symbolName {
                Image(systemName: symbolName)
            }
            Text(text)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
}
