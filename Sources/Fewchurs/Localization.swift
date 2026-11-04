import Foundation

extension String {
    /// A user-facing string from this package's `Localizable.xcstrings`.
    ///
    /// Every visible string goes through here. A bare literal handed to SwiftUI (`Text("Retry")`)
    /// would be looked up in the host app's bundle, never this package's, so it could not be
    /// translated with the SDK.
    init(sdk key: String.LocalizationValue) {
        self.init(localized: key, bundle: .module)
    }
}
