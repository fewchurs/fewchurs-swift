import Foundation
import Testing
@testable import FeatureRequestKit

/// These must equal the Zod schemas in the web repo's src/lib/validation/schemas.ts.
@Test func limitsMatchTheServerSchemas() {
    #expect(ValidationLimits.titleMin == 3)
    #expect(ValidationLimits.titleMax == 100)
    #expect(ValidationLimits.descriptionMax == 1000)
    #expect(ValidationLimits.commentMax == 1000)
    #expect(ValidationLimits.authorNameMax == 60)
}

@Test func titleIsTrimmedBeforeChecking() {
    #expect(ValidationLimits.isValidTitle("  ab  ") == false)
    #expect(ValidationLimits.isValidTitle("  abc  ") == true)
    #expect(ValidationLimits.isValidTitle(String(repeating: "a", count: 100) + "   ") == true)
    #expect(ValidationLimits.isValidTitle(String(repeating: "a", count: 101)) == false)
}

/// Zod measures UTF-16 code units, so an emoji takes more than one "character" of the limit.
@Test func lengthCountsUTF16LikeTheServer() {
    #expect(ValidationLimits.length(of: "👍🏽") == 4)
    #expect(ValidationLimits.fits(String(repeating: "👍🏽", count: 15), max: ValidationLimits.authorNameMax) == true)
    #expect(ValidationLimits.fits(String(repeating: "👍🏽", count: 16), max: ValidationLimits.authorNameMax) == false)
}

@Test func counterAppearsNearTheLimit() {
    #expect(ValidationLimits.showsCounter(for: String(repeating: "a", count: 79), max: 100) == false)
    #expect(ValidationLimits.showsCounter(for: String(repeating: "a", count: 80), max: 100) == true)
}
