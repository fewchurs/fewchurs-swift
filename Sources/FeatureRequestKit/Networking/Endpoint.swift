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
    static func features(sort: String, limit: Int, cursor: String?) -> Endpoint {
        var items = [
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: "features", method: .get, queryItems: items)
    }

    static func createFeature(title: String, description: String?) throws -> Endpoint {
        struct Body: Encodable {
            let title: String
            let description: String?
        }
        let data = try JSONEncoder().encode(Body(title: title, description: description))
        return Endpoint(path: "features", method: .post, body: data)
    }

    static func vote(featureId: String) -> Endpoint {
        Endpoint(path: "features/\(featureId)/vote", method: .post)
    }

    static func removeVote(featureId: String) -> Endpoint {
        Endpoint(path: "features/\(featureId)/vote", method: .delete)
    }
}
