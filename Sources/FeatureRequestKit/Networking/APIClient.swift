import Foundation

struct FeaturesPage: Decodable {
    let features: [FeatureRequest]
    let nextCursor: String?
}

struct VoteResponse: Decodable {
    let upvoteCount: Int
    let hasVoted: Bool
}

/// `POST`/`DELETE /features/{id}/follow` return only `{ following }`. There is no count in the
/// response, so callers keep their optimistic `followerCount`.
struct FollowResponse: Decodable {
    let following: Bool
}

struct CommentsPage: Decodable {
    let comments: [Comment]
    let nextCursor: String?
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    /// Tests pass a fixed configuration so they never touch the global one.
    private let configurationOverride: Configuration?

    init(session: URLSession = .shared, configuration: Configuration? = nil) {
        self.session = session
        self.configurationOverride = configuration
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let configuration = configurationOverride ?? FeatureRequestKit.configuration else {
            throw APIError.notConfigured
        }
        guard let url = endpoint.url(relativeTo: configuration.baseURL) else {
            throw APIError.network
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(DeviceIdentity.current, forHTTPHeaderField: "X-Device-Id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.network
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.mapError(data: data, statusCode: httpResponse.statusCode)
        }

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(APIError.describe(error))
        }
    }

    /// Non-JSON bodies (Vercel 502/504 pages, Next.js 405s, empty bodies) never reach the user
    /// as text: they become `.server` with only the status code, for `debugDetail`.
    static func mapError(data: Data, statusCode: Int) -> APIError {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return .from(code: decoded.error.code, message: decoded.error.message, statusCode: statusCode)
        }
        return .server("HTTP \(statusCode)")
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { valueDecoder in
            let container = try valueDecoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = isoFormatterWithFractionalSeconds.date(from: string) {
                return date
            }
            if let date = isoFormatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(string)")
        }
        return decoder
    }()

    private static let isoFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
