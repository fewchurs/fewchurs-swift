import Foundation
import Testing
@testable import FeatureRequestKit

@Test func deviceIdentityIsAValidUUID() {
    #expect(UUID(uuidString: DeviceIdentity.current) != nil)
}

@Test func deviceIdentityIsStableAcrossAccesses() {
    let first = DeviceIdentity.current
    let second = DeviceIdentity.current
    #expect(first == second)
}
