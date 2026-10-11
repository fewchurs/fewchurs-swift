import Foundation
import Testing
@testable import FeatureRequestKit

/// Strings resolve from this package's catalog, including interpolated ones.
@Test func stringsResolveFromThePackageCatalog() {
    #expect(String(sdk: "Retry") == "Retry")
    #expect(String(sdk: "Powered by Fewchurs") == "Powered by Fewchurs")
    let count = 42
    #expect(String(sdk: "\(count) votes") == "42 votes")
    #expect(FeatureStatus.inProgress.displayName == "In Progress")
}

@Test func catalogShipsInThePackageBundle() {
    let localizations = Bundle.module.localizations
    #expect(localizations.contains("en"))
    #expect(Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en") != nil
        || Bundle.module.url(forResource: "Localizable", withExtension: "xcstrings") != nil
        || Bundle.module.path(forResource: "Localizable", ofType: "stringsdict", inDirectory: nil, forLocalization: "en") != nil)
}

/// Every `String(sdk:)` key in the sources must be in Localizable.xcstrings, or a translator
/// would never see it. (Simulator tests can read the package sources from disk.)
@Test func catalogContainsEveryKeyUsedInCode() throws {
    let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/FeatureRequestKit")
    let catalogData = try Data(contentsOf: sources.appendingPathComponent("Localizable.xcstrings"))
    let catalog = try #require(try JSONSerialization.jsonObject(with: catalogData) as? [String: Any])
    let catalogKeys = Set((catalog["strings"] as? [String: Any] ?? [:]).keys)

    let call = try NSRegularExpression(pattern: #"String\(sdk: "((?:[^"\\]|\\.)*)"\)"#)
    let interpolation = try NSRegularExpression(pattern: #"\\\([^)]*\)"#)
    var codeKeys = Set<String>()
    let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)?
        .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" } ?? []
    for file in files {
        let text = try String(contentsOf: file, encoding: .utf8)
        for match in call.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            let literal = String(text[Range(match.range(at: 1), in: text)!])
            let key = interpolation
                .stringByReplacingMatches(in: literal, range: NSRange(literal.startIndex..., in: literal), withTemplate: "%lld")
                .replacingOccurrences(of: #"\""#, with: "\"")
            codeKeys.insert(key)
        }
    }
    #expect(!codeKeys.isEmpty)
    #expect(codeKeys.subtracting(catalogKeys).isEmpty, "Missing from Localizable.xcstrings: \(codeKeys.subtracting(catalogKeys).sorted())")
}
