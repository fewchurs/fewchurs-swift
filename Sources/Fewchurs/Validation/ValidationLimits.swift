import Foundation

/// The server's input limits, mirrored so the UI can say so before a request fails.
///
/// Source of truth: `createFeatureSchema` and `createCommentSchema` in the web repo's
/// `src/lib/validation/schemas.ts`. Zod trims first, then measures JavaScript string length,
/// which is UTF-16 code units, so `length(of:)` does the same. An emoji such as 👍🏽 counts as 4.
enum ValidationLimits {
    static let titleMin = 3
    static let titleMax = 100
    static let descriptionMax = 1000
    static let commentMax = 1000
    static let authorNameMax = 60

    /// Length as the server measures it: trimmed, in UTF-16 code units.
    static func length(of text: String) -> Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count
    }

    static func isValidTitle(_ text: String) -> Bool {
        (titleMin...titleMax).contains(length(of: text))
    }

    static func fits(_ text: String, max: Int) -> Bool {
        length(of: text) <= max
    }

    /// Counters appear once the text reaches 80% of its limit, so short input stays quiet.
    static func showsCounter(for text: String, max: Int) -> Bool {
        length(of: text) * 5 >= max * 4
    }
}
