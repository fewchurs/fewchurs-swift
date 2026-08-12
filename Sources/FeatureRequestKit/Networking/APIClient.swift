import Foundation

struct FeaturesPage: Decodable {
    let features: [FeatureRequest]
    let nextCursor: String?
}

struct VoteResponse: Decodable {
    let upvoteCount: Int
    let hasVoted: Bool
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let configuration = FeatureRequestKit.configuration else {
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
            throw APIError.decoding
        }
    }

    static func mapError(data: Data, statusCode: Int) -> APIError {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return .from(code: decoded.error.code, message: decoded.error.message)
        }
        return .server("Something went wrong. Please try again. (\(statusCode))")
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
