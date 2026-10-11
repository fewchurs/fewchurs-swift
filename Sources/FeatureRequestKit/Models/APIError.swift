import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidKey
    case missingDeviceId
    case validationFailed(String)
    /// The server message, kept for `debugDetail`. Users see friendly copy.
    case rateLimited(String)
    case notFound
    /// `limit_reached` (402): the board's plan limit. The server message is debug-only.
    case limitReached(String)
    case unauthorized
    case forbidden
    /// `internal` (500). The server message is debug-only.
    case internalError(String)
    /// Anything the SDK can't name: an unknown error code, or a body that isn't the API's
    /// JSON (a Vercel 502/504 page, a Next.js 405, an empty body). The associated value is a
    /// debug description and is never shown as the user-facing message.
    case server(String)
    case network
    case decoding(String)
    case notConfigured

    /// Technical detail for the cases that have one, meant for debugging during integration
    /// rather than for end users. `nil` for cases where there's nothing more specific to show.
    var debugDetail: String? {
        switch self {
        case .decoding(let detail), .server(let detail):
            return detail
        case .rateLimited(let message), .limitReached(let message), .internalError(let message):
            return message.isEmpty ? nil : message
        default:
            return nil
        }
    }

    /// `debugDetail` in the host app's Debug builds, `nil` in Release, so App Store users only
    /// ever see `userMessage`.
    var presentableDebugDetail: String? {
        #if DEBUG
        return debugDetail
        #else
        return nil
        #endif
    }

    var userMessage: String {
        switch self {
        case .invalidKey:
            return String(sdk: "This app's API key is invalid. Please contact the developer.")
        case .missingDeviceId:
            return String(sdk: "Something went wrong identifying this device. Please try again.")
        case .validationFailed(let message):
            return message.isEmpty ? String(sdk: "Please check what you entered and try again.") : message
        case .rateLimited:
            return String(sdk: "You've reached today's limit for this. Please try again tomorrow.")
        case .notFound:
            return String(sdk: "That feature request no longer exists.")
        case .limitReached:
            return String(sdk: "This board isn't taking new requests right now. Please try again later.")
        case .unauthorized, .forbidden:
            return String(sdk: "This board isn't available right now. Please contact the developer.")
        case .internalError, .server:
            return String(sdk: "Something went wrong on our side. Please try again in a moment.")
        case .network:
            return String(sdk: "Couldn't reach the server. Check your connection and try again.")
        case .decoding:
            return String(sdk: "Received an unexpected response. Please try again later.")
        case .notConfigured:
            return String(sdk: "FeatureRequestKit has not been configured.")
        }
    }

    var errorDescription: String? { userMessage }

    static func from(code: String, message: String, statusCode: Int? = nil) -> APIError {
        switch code {
        case "invalid_key": return .invalidKey
        case "missing_device_id": return .missingDeviceId
        case "validation_failed": return .validationFailed(message)
        case "rate_limited": return .rateLimited(message)
        case "not_found": return .notFound
        case "limit_reached": return .limitReached(message)
        case "unauthorized": return .unauthorized
        case "forbidden": return .forbidden
        case "internal": return .internalError(message)
        default:
            let status = statusCode.map { " (HTTP \($0))" } ?? ""
            return .server("\(code)\(status): \(message)")
        }
    }

    /// Turns a `DecodingError` into a short, actionable description of what didn't match
    /// (missing key, wrong type, etc.), for surfacing during integration/debugging.
    static func describe(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }
        switch decodingError {
        case .keyNotFound(let key, let context):
            let path = (context.codingPath + [key]).map(\.stringValue).joined(separator: ".")
            return "Missing field '\(path)'"
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Field '\(path)' has the wrong type (expected \(type))"
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return "Field '\(path)' is null (expected \(type))"
        case .dataCorrupted(let context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return path.isEmpty ? context.debugDescription : "'\(path)': \(context.debugDescription)"
        @unknown default:
            return decodingError.localizedDescription
        }
    }
}

struct APIErrorResponse: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String
    }
    let error: Body
}
