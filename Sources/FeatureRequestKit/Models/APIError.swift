import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidKey
    case missingDeviceId
    case validationFailed(String)
    case rateLimited
    case notFound
    case server(String)
    case network
    case decoding(String)
    case notConfigured

    /// Technical detail for the cases that have one, meant for debugging during integration
    /// rather than for end users. `nil` for cases where there's nothing more specific to show.
    var debugDetail: String? {
        switch self {
        case .decoding(let detail): return detail
        default: return nil
        }
    }

    var userMessage: String {
        switch self {
        case .invalidKey:
            return "This app's API key is invalid. Please contact the developer."
        case .missingDeviceId:
            return "Something went wrong identifying this device. Please try again."
        case .validationFailed(let message):
            return message
        case .rateLimited:
            return "You're doing that too fast. Please wait a moment and try again."
        case .notFound:
            return "That feature request no longer exists."
        case .server(let message):
            return message
        case .network:
            return "You appear to be offline. Check your connection and try again."
        case .decoding:
            return "Received an unexpected response. Please try again later."
        case .notConfigured:
            return "FeatureRequestKit has not been configured."
        }
    }

    var errorDescription: String? { userMessage }

    static func from(code: String, message: String) -> APIError {
        switch code {
        case "invalid_key": return .invalidKey
        case "missing_device_id": return .missingDeviceId
        case "validation_failed": return .validationFailed(message)
        case "rate_limited": return .rateLimited
        case "not_found": return .notFound
        default: return .server(message)
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
