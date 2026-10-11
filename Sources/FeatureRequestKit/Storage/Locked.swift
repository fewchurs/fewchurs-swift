import Foundation

/// A value behind a lock, for the few pieces of global state (`configure`, `identify`) that
/// the host may touch from any thread.
final class Locked<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }
}
