import Foundation
@testable import FeatureRequestKit

/// An in-process fake of the Fewchurs API, served through `URLProtocol` so tests exercise the
/// real `APIClient` path: URL building, headers, body encoding, status handling and decoding.
///
/// Each server gets its own random host, so tests running in parallel never see each other's
/// routes or requests.
final class StubServer: @unchecked Sendable {
    struct Request {
        let method: String
        /// Path relative to `/api/v1/`, e.g. `features/f1/vote`.
        let path: String
        let query: [String: String]
        let headers: [String: String]
        let body: Data?

        var json: [String: Any]? {
            body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        }
    }

    enum Reply {
        case json(Int, String)
        case raw(Int, String)
        case failure(URLError.Code)
    }

    let host = "\(UUID().uuidString.lowercased()).stub.test"
    var baseURL: URL { URL(string: "https://\(host)/api/v1")! }

    private let lock = NSLock()
    private var routes: [String: [Reply]] = [:]
    private var recorded: [Request] = []

    init() {
        StubURLProtocol.register(self)
    }

    deinit {
        StubURLProtocol.unregister(host: host)
    }

    /// Queues replies for `METHOD path`. Each request takes the next one; the last is repeated.
    func on(_ method: String, _ path: String, _ replies: Reply...) {
        lock.withLock { routes["\(method) \(path)", default: []].append(contentsOf: replies) }
    }

    var requests: [Request] {
        lock.withLock { recorded }
    }

    func requests(_ method: String, _ path: String) -> [Request] {
        requests.filter { $0.method == method && $0.path == path }
    }

    func makeClient(apiKey: String = "fr_test_key") -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(
            session: URLSession(configuration: configuration),
            configuration: Configuration(apiKey: apiKey, baseURL: baseURL, theme: .system)
        )
    }

    fileprivate func handle(_ request: URLRequest, body: Data?) -> Reply {
        let url = request.url!
        let prefix = "/api/v1/"
        let path = url.path.hasPrefix(prefix) ? String(url.path.dropFirst(prefix.count)) : url.path
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let method = request.httpMethod ?? "GET"
        let entry = Request(
            method: method,
            path: path,
            query: Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 }),
            headers: request.allHTTPHeaderFields ?? [:],
            body: body
        )
        return lock.withLock {
            recorded.append(entry)
            let key = "\(method) \(path)"
            guard var queue = routes[key], !queue.isEmpty else {
                return .json(404, #"{"error":{"code":"not_found","message":"No stub for \#(key)"}}"#)
            }
            let reply = queue.count > 1 ? queue.removeFirst() : queue[0]
            routes[key] = queue
            return reply
        }
    }
}

final class StubURLProtocol: URLProtocol {
    private final class Registry: @unchecked Sendable {
        let lock = NSLock()
        var servers: [String: StubServer] = [:]
    }

    private static let registry = Registry()

    static func register(_ server: StubServer) {
        registry.lock.withLock { registry.servers[server.host] = server }
    }

    static func unregister(host: String) {
        registry.lock.withLock { _ = registry.servers.removeValue(forKey: host) }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let host = request.url?.host,
              let server = Self.registry.lock.withLock({ Self.registry.servers[host] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        switch server.handle(request, body: Self.body(of: request)) {
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case .json(let status, let text):
            respond(status: status, contentType: "application/json", body: Data(text.utf8))
        case .raw(let status, let text):
            respond(status: status, contentType: "text/html", body: Data(text.utf8))
        }
    }

    override func stopLoading() {}

    private func respond(status: Int, contentType: String, body: Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": contentType]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    /// URLSession moves `httpBody` into a stream before a protocol sees the request.
    private static func body(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

/// Server-shaped JSON for a feature, matching `FeatureWithVote` in the web repo's
/// `src/types/index.ts`, including fields the SDK deliberately ignores.
func featureJSON(
    id: String,
    title: String = "Dark mode",
    status: String = "open",
    upvoteCount: Int = 0,
    hasVoted: Bool = false,
    followerCount: Int = 0,
    isFollowing: Bool = false,
    isMine: Bool = false
) -> String {
    """
    {"id":"\(id)","title":"\(title)","description":"","status":"\(status)",\
    "upvoteCount":\(upvoteCount),"commentCount":0,"followerCount":\(followerCount),\
    "hasVoted":\(hasVoted),"isFollowing":\(isFollowing),"isMine":\(isMine),\
    "authorDeviceId":"someone-elses-device","authorIsSubscriber":false,"translation":null,\
    "createdAt":"2026-10-01T10:00:00.000Z","updatedAt":"2026-10-01T10:00:00.000Z"}
    """
}

func featuresPageJSON(_ features: [String], nextCursor: String? = nil) -> String {
    let cursor = nextCursor.map { "\"\($0)\"" } ?? "null"
    return #"{"features":[\#(features.joined(separator: ","))],"nextCursor":\#(cursor)}"#
}

func commentJSON(id: String, text: String = "Nice", isMine: Bool? = nil) -> String {
    let mine = isMine.map { #","isMine":\#($0)"# } ?? ""
    return """
    {"id":"\(id)","text":"\(text)","authorName":"App User","deviceId":"someone-elses-device",\
    "isDeveloper":false,"createdAt":"2026-10-01T10:00:00.000Z"\(mine)}
    """
}

func commentsPageJSON(_ comments: [String], nextCursor: String? = nil) -> String {
    let cursor = nextCursor.map { "\"\($0)\"" } ?? "null"
    return #"{"comments":[\#(comments.joined(separator: ","))],"nextCursor":\#(cursor)}"#
}
