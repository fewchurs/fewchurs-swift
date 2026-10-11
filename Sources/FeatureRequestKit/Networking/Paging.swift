import Foundation

/// A cursor-paged response from `/features` or `/features/{id}/comments`.
protocol CursorPage {
    var isEmpty: Bool { get }
    var nextCursor: String? { get }
}

extension FeaturesPage: CursorPage {
    var isEmpty: Bool { features.isEmpty }
}

extension CommentsPage: CursorPage {
    var isEmpty: Bool { comments.isEmpty }
}

enum Paging {
    /// Follow-up fetches allowed after an empty page. Bounds the requests one scroll can make.
    static let maxEmptyPagesSkipped = 5

    /// A page can be empty yet still have a cursor: the server drops deleted comments after
    /// it has cut the page. Paging is driven by the last row appearing, so an empty page would
    /// stall it for good. This keeps fetching until a page has rows, the cursor runs out, or
    /// the cap is hit.
    static func fetchSkippingEmptyPages<Page: CursorPage>(
        from cursor: String?,
        _ fetch: (String?) async throws -> Page
    ) async throws -> Page {
        var page = try await fetch(cursor)
        var skipped = 0
        while page.isEmpty, let next = page.nextCursor, skipped < maxEmptyPagesSkipped {
            skipped += 1
            page = try await fetch(next)
        }
        return page
    }
}
