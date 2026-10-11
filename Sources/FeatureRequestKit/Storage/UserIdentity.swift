import Foundation
import Security

/// Optional email and display name the user gave once, persisted so we never ask again.
/// Same Keychain approach as `DeviceIdentity`: fails soft, never crashes the host app.
enum UserIdentity {
    private static let service = "com.featurerequestkit.useridentity"
    private static let emailAccount = "email"
    private static let displayNameAccount = "displayName"

    static var email: String? {
        get { read(account: emailAccount) }
        set { write(newValue, account: emailAccount) }
    }

    /// The email to use for following and as the submit form's default: what the user typed
    /// into the board before, otherwise what the host passed to `identify(email:)`.
    static var preferredEmail: String? {
        if let email, !email.isEmpty { return email }
        return FeatureRequestKit.identifiedEmail
    }

    static var displayName: String? {
        get { read(account: displayNameAccount) }
        set { write(newValue, account: displayNameAccount) }
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private static func write(_ value: String?, account: String) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(baseQuery as CFDictionary)

        guard let value, let data = value.data(using: .utf8) else { return }
        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
