import Foundation
import Testing
@testable import FeatureRequestKit

@Test func apiErrorMapsKnownBackendCodes() {
    #expect(APIError.from(code: "invalid_key", message: "bad key") == .invalidKey)
    #expect(APIError.from(code: "missing_device_id", message: "no device") == .missingDeviceId)
    #expect(APIError.from(code: "rate_limited", message: "slow down") == .rateLimited("slow down"))
    #expect(APIError.from(code: "not_found", message: "gone") == .notFound)
    #expect(APIError.from(code: "limit_reached", message: "Plan limit") == .limitReached("Plan limit"))
    #expect(APIError.from(code: "unauthorized", message: "no") == .unauthorized)
    #expect(APIError.from(code: "forbidden", message: "no") == .forbidden)
    #expect(APIError.from(code: "internal", message: "Failed to create feature.") == .internalError("Failed to create feature."))
}

@Test func apiErrorPreservesValidationMessage() {
    let error = APIError.from(code: "validation_failed", message: "Title is required")
    #expect(error == .validationFailed("Title is required"))
    #expect(error.userMessage == "Title is required")
}

/// Server text for these codes is for developers. Users get friendly copy instead.
@Test func serverMessagesNeverBecomeTheUserMessage() {
    let raw = "Failed to create feature: Firestore DEADLINE_EXCEEDED"
    for error in [
        APIError.from(code: "internal", message: raw),
        APIError.from(code: "limit_reached", message: raw),
        APIError.from(code: "rate_limited", message: raw),
        APIError.from(code: "some_future_code", message: raw, statusCode: 418),
    ] {
        #expect(!error.userMessage.contains("Firestore"))
        #expect(error.debugDetail?.contains("Firestore") == true)
    }
}

@Test func apiErrorUnknownCodeKeepsCodeAndStatusForDebugging() {
    let error = APIError.from(code: "teapot", message: "Short and stout", statusCode: 418)
    #expect(error == .server("teapot (HTTP 418): Short and stout"))
    #expect(error.userMessage == "Something went wrong on our side. Please try again in a moment.")
}

@Test func apiErrorMapsHTTPResponseBody() {
    let json = """
    { "error": { "code": "rate_limited", "message": "Too many requests" } }
    """
    let mapped = APIClient.mapError(data: Data(json.utf8), statusCode: 429)
    #expect(mapped == .rateLimited("Too many requests"))
    #expect(mapped.userMessage == "You've reached today's limit for this. Please try again tomorrow.")
}

@Test func apiErrorFallsBackWhenBodyIsUnparseable() {
    let html = APIClient.mapError(data: Data("<html><body>502 Bad Gateway</body></html>".utf8), statusCode: 502)
    #expect(html == .server("HTTP 502"))
    #expect(!html.userMessage.contains("502"))
    #expect(html.debugDetail == "HTTP 502")

    let empty = APIClient.mapError(data: Data(), statusCode: 405)
    #expect(empty == .server("HTTP 405"))
    #expect(empty.userMessage == "Something went wrong on our side. Please try again in a moment.")
}

@Test func decodingErrorDescribesMissingKey() throws {
    struct Sample: Decodable { let upvoteCount: Int }
    do {
        _ = try JSONDecoder().decode(Sample.self, from: Data("{}".utf8))
        Issue.record("expected decoding to throw")
    } catch {
        #expect(APIError.describe(error) == "Missing field 'upvoteCount'")
    }
}

@Test func decodingErrorDescribesTypeMismatch() throws {
    struct Sample: Decodable { let upvoteCount: Int }
    do {
        _ = try JSONDecoder().decode(Sample.self, from: Data(#"{"upvoteCount":"forty-two"}"#.utf8))
        Issue.record("expected decoding to throw")
    } catch {
        #expect(APIError.describe(error) == "Field 'upvoteCount' has the wrong type (expected Int)")
    }
}

@Test func apiErrorDecodingExposesDebugDetail() {
    let error = APIError.decoding("Missing field 'id'")
    #expect(error.debugDetail == "Missing field 'id'")
    #expect(error.userMessage == "Received an unexpected response. Please try again later.")
}

@Test func apiErrorOtherCasesHaveNoDebugDetail() {
    #expect(APIError.invalidKey.debugDetail == nil)
    #expect(APIError.network.debugDetail == nil)
    #expect(APIError.rateLimited("").debugDetail == nil)
}
