import Foundation
import Testing
@testable import FeatureRequestKit

/// Guards the follow regression: the server returns `{ following }` and nothing else. The old
/// `{ followerCount, isFollowing }` shape threw `.decoding` after a follow that had succeeded.
@Test func followResponseDecodesServerPayload() throws {
    let followed = try APIClient.decoder.decode(FollowResponse.self, from: Data(#"{"following":true}"#.utf8))
    #expect(followed.following == true)

    let unfollowed = try APIClient.decoder.decode(FollowResponse.self, from: Data(#"{"following":false}"#.utf8))
    #expect(unfollowed.following == false)
}
