import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidKey
    case missingDeviceId
    case validationFailed(String)
    case rateLimited
    case notFound
    case server(String)
    case network
    case decoding
    case notConfigured

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
}

struct APIErrorResponse: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String
    }
    let error: Body
}
