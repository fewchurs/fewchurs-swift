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
    private let retryDelay: TimeInterval

    init(session: URLSession = APIClient.makeSession(), configuration: Configuration? = nil, retryDelay: TimeInterval = 0.5) {
        self.session = session
        self.configurationOverride = configuration
        self.retryDelay = retryDelay
    }

    /// Its own session rather than `.shared`, so the host app's URLSession settings and cache
    /// never leak in. 15s per request: the board is interactive, and a GET gets one retry.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 40
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    /// Failures worth one more try: the request may never have reached the server, or a proxy
    /// in front of it hiccupped.
    static func isTransient(_ code: URLError.Code) -> Bool {
        [.timedOut, .networkConnectionLost].contains(code)
    }

    static func isTransient(statusCode: Int) -> Bool {
        [502, 503, 504].contains(statusCode)
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
        request.setValue("swift/\(FeatureRequestKit.sdkVersion)", forHTTPHeaderField: "X-Fewchurs-Sdk")
        request.setValue(Self.acceptLanguage, forHTTPHeaderField: "Accept-Language")

        let (data, httpResponse) = try await perform(request, retrying: endpoint.isIdempotent)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw Self.mapError(data: data, statusCode: httpResponse.statusCode)
        }

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(APIError.describe(error))
        }
    }

    /// Idempotent requests get one retry after a transient failure. Creates never do: if the
    /// first attempt reached the server and only the response was lost, a retry would post
    /// the same feature or comment twice.
    private func perform(_ request: URLRequest, retrying: Bool) async throws -> (Data, HTTPURLResponse) {
        let attempts = retrying ? 2 : 1
        for attempt in 1...attempts {
            let isLastAttempt = attempt == attempts
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.network }
                if !isLastAttempt && Self.isTransient(statusCode: httpResponse.statusCode) {
                    await pauseBeforeRetry()
                    continue
                }
                return (data, httpResponse)
            } catch let error as URLError where !isLastAttempt && Self.isTransient(error.code) {
                await pauseBeforeRetry()
            } catch let error as APIError {
                throw error
            } catch {
                throw APIError.network
            }
        }
        throw APIError.network
    }

    private func pauseBeforeRetry() async {
        guard retryDelay > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
    }

    /// Non-JSON bodies (Vercel 502/504 pages, Next.js 405s, empty bodies) never reach the user
    /// as text: they become `.server` with only the status code, for `debugDetail`.
    static func mapError(data: Data, statusCode: Int) -> APIError {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return .from(code: decoded.error.code, message: decoded.error.message, statusCode: statusCode)
        }
        return .server("HTTP \(statusCode)")
    }

    /// The user's first preferred language as a BCP 47 tag, e.g. `en-US`. Not used by the
    /// server yet; sent now so localisation can start without an SDK update.
    static var acceptLanguage: String {
        Locale.preferredLanguages.first ?? "en"
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
