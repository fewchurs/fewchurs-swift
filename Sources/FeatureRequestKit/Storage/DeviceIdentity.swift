import Foundation
import Security

enum DeviceIdentity {
    private static let service = "com.featurerequestkit.device"
    private static let account = "deviceId"

    static let current: String = loadOrCreate()

    private static func loadOrCreate() -> String {
        if let existing = read() {
            return existing
        }
        let newId = UUID().uuidString
        write(newId)
        return newId
    }

    private static func read() -> String? {
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

    @discardableResult
    private static func write(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
}
