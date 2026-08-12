import SwiftUI

public struct FeatureRequestTheme: Sendable {
    public var background: Color
    public var accent: Color
    public var cornerRadius: CGFloat

    /// Forces dark appearance so foreground colors stay legible against a fixed dark
    /// `background`, regardless of the host app's current system appearance.
    var forcesDarkAppearance = false

    public init(background: Color, accent: Color, cornerRadius: CGFloat) {
        self.background = background
        self.accent = accent
        self.cornerRadius = cornerRadius
    }

    public static let system = FeatureRequestTheme(
        background: Color(.systemBackground),
        accent: .accentColor,
        cornerRadius: 12
    )

    public static let midnight: FeatureRequestTheme = {
        var theme = FeatureRequestTheme(background: .black, accent: .white, cornerRadius: 16)
        theme.forcesDarkAppearance = true
        return theme
    }()
}

private struct FeatureRequestThemeKey: EnvironmentKey {
    static let defaultValue: FeatureRequestTheme = .system
}

extension EnvironmentValues {
    var featureRequestTheme: FeatureRequestTheme {
        get { self[FeatureRequestThemeKey.self] }
        set { self[FeatureRequestThemeKey.self] = newValue }
    }
}
