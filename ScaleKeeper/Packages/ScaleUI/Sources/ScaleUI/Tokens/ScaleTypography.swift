import SwiftUI

// MARK: - Scale Typography

/// Typography system for ScaleKeeper following the suite design system
public extension Font {
    // MARK: - Headers

    /// Large title - 32pt Bold
    static let scaleLargeTitle = Font.system(size: 32, weight: .bold)

    /// Title - 28pt Bold
    static let scaleTitle = Font.system(size: 28, weight: .bold)

    /// Title 2 - 24pt Bold
    static let scaleTitle2 = Font.system(size: 24, weight: .bold)

    /// Title 3 - 20pt Semibold
    static let scaleTitle3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Body

    /// Headline - 17pt Semibold
    static let scaleHeadline = Font.system(size: 17, weight: .semibold)

    /// Body - 17pt Regular
    static let scaleBody = Font.system(size: 17, weight: .regular)

    /// Subheadline - 15pt Regular
    static let scaleSubheadline = Font.system(size: 15, weight: .regular)

    /// Callout - 16pt Regular
    static let scaleCallout = Font.system(size: 16, weight: .regular)

    // MARK: - Captions

    /// Caption - 13pt Regular
    static let scaleCaption = Font.system(size: 13, weight: .regular)

    /// Caption 2 - 11pt Regular
    static let scaleCaption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Buttons

    /// Button text - 17pt Semibold
    static let scaleButton = Font.system(size: 17, weight: .semibold)

    /// Small button - 15pt Semibold
    static let scaleButtonSmall = Font.system(size: 15, weight: .semibold)

    // MARK: - Numbers

    /// Large numbers (stats) - 40pt Bold
    static let scaleStatLarge = Font.system(size: 40, weight: .bold)

    /// Medium numbers - 28pt Bold
    static let scaleStatMedium = Font.system(size: 28, weight: .bold)

    /// Small numbers - 20pt Semibold
    static let scaleStatSmall = Font.system(size: 20, weight: .semibold)

    // MARK: - Monospace (for data)

    /// Monospace body
    static let scaleMonospace = Font.system(size: 15, weight: .regular, design: .monospaced)

    /// Monospace caption
    static let scaleMonospaceSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Modifiers

public struct ScaleTextStyle: ViewModifier {
    public enum Style {
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case body
        case subheadline
        case caption
        case caption2
    }

    let style: Style
    let color: Color

    public init(_ style: Style, color: Color = .scaleTextPrimary) {
        self.style = style
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }

    private var font: Font {
        switch style {
        case .largeTitle: return .scaleLargeTitle
        case .title: return .scaleTitle
        case .title2: return .scaleTitle2
        case .title3: return .scaleTitle3
        case .headline: return .scaleHeadline
        case .body: return .scaleBody
        case .subheadline: return .scaleSubheadline
        case .caption: return .scaleCaption
        case .caption2: return .scaleCaption2
        }
    }
}

public extension View {
    func scaleTextStyle(_ style: ScaleTextStyle.Style, color: Color = .scaleTextPrimary) -> some View {
        modifier(ScaleTextStyle(style, color: color))
    }
}
