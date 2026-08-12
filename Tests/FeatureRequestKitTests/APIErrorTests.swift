import Foundation
import Testing
@testable import FeatureRequestKit

@Test func apiErrorMapsKnownBackendCodes() {
    #expect(APIError.from(code: "invalid_key", message: "bad key") == .invalidKey)
    #expect(APIError.from(code: "missing_device_id", message: "no device") == .missingDeviceId)
    #expect(APIError.from(code: "rate_limited", message: "slow down") == .rateLimited)
    #expect(APIError.from(code: "not_found", message: "gone") == .notFound)
}

@Test func apiErrorPreservesValidationMessage() {
    let error = APIError.from(code: "validation_failed", message: "Title is required")
    #expect(error == .validationFailed("Title is required"))
    #expect(error.userMessage == "Title is required")
}

@Test func apiErrorFallsBackToServerForUnknownCode() {
    let error = APIError.from(code: "internal", message: "Something broke")
    #expect(error == .server("Something broke"))
}

@Test func apiErrorMapsHTTPResponseBody() {
    let json = """
    { "error": { "code": "rate_limited", "message": "Too many requests" } }
    """
    let data = Data(json.utf8)
    let mapped = APIClient.mapError(data: data, statusCode: 429)
    #expect(mapped == .rateLimited)
}

@Test func apiErrorFallsBackWhenBodyIsUnparseable() {
    let mapped = APIClient.mapError(data: Data("not json".utf8), statusCode: 500)
    #expect(mapped == .server("Something went wrong. Please try again. (500)"))
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
}
