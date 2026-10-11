import Foundation

struct Endpoint {
    enum HTTPMethod: String, Equatable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var body: Data?

    func url(relativeTo baseURL: URL) -> URL? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}

extension Endpoint {
    /// `statuses` narrows the list (the server ignores names it doesn't know); empty means all.
    static func features(sort: String, limit: Int, cursor: String?, statuses: [FeatureStatus] = []) -> Endpoint {
        var items = [
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if !statuses.isEmpty {
            items.append(URLQueryItem(name: "status", value: statuses.map(\.rawValue).joined(separator: ",")))
        }
        return Endpoint(path: "features", method: .get, queryItems: items)
    }

    /// With an `email`, the server creates the feature and follows it in the same request, so
    /// there is no separate `/follow` call. Nil fields are left out of the body.
    static func feature(id: String) -> Endpoint {
        Endpoint(path: "features/\(id)", method: .get)
    }

    static func createFeature(
        title: String,
        description: String?,
        email: String? = nil,
        isSubscriber: Bool = false
    ) throws -> Endpoint {
        struct Body: Encodable {
            let title: String
            let description: String?
            let email: String?
            let isSubscriber: Bool
        }
        let body = Body(title: title, description: description, email: email, isSubscriber: isSubscriber)
        return Endpoint(path: "features", method: .post, body: try JSONEncoder().encode(body))
    }

    static func vote(featureId: String) -> Endpoint {
        Endpoint(path: "features/\(featureId)/vote", method: .post)
    }

    static func removeVote(featureId: String) -> Endpoint {
        Endpoint(path: "features/\(featureId)/vote", method: .delete)
    }

    static func follow(featureId: String, email: String) throws -> Endpoint {
        struct Body: Encodable {
            let email: String
        }
        let data = try JSONEncoder().encode(Body(email: email))
        return Endpoint(path: "features/\(featureId)/follow", method: .post, body: data)
    }

    static func unfollow(featureId: String) -> Endpoint {
        Endpoint(path: "features/\(featureId)/follow", method: .delete)
    }

    static func comments(featureId: String, limit: Int, cursor: String?) -> Endpoint {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "features/\(featureId)/comments", method: .get, queryItems: items)
    }

    /// Posts to the flat `/comments` collection, not `features/{id}/comments` — that nested
    /// path is read-only on the server (GET only), so POSTing to it returns 405. The feature
    /// is identified by `featureId` in the body instead.
    static func createComment(featureId: String, text: String, authorName: String?) throws -> Endpoint {
        struct Body: Encodable {
            let featureId: String
            let text: String
            let authorName: String?
        }
        let data = try JSONEncoder().encode(Body(featureId: featureId, text: text, authorName: authorName))
        return Endpoint(path: "comments", method: .post, body: data)
    }

    static let config = Endpoint(path: "config", method: .get)
}
