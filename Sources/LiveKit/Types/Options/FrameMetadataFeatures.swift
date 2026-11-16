/*
 * Copyright 2026 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// The kinds of per-frame metadata a published video track carries in its packet trailer.
///
/// Declaring a feature tells the server that the track's encoded frames end with a packet trailer
/// holding that field, so the server passes the trailer on to subscribers that can read it.
///
/// - Note: This only declares the features. The SDK does not write the trailer: the frames must
/// already carry it when they leave the encoder, for example from a custom ``VideoEncoderFactory``.
@objcMembers
public final class FrameMetadataFeatures: NSObject, Sendable {
    /// A capture timestamp set by the publisher.
    public let userTimestamp: Bool

    /// A frame identifier set by the publisher.
    public let frameId: Bool

    /// Opaque bytes set by the publisher.
    public let userData: Bool

    public init(userTimestamp: Bool = false,
                frameId: Bool = false,
                userData: Bool = false)
    {
        self.userTimestamp = userTimestamp
        self.frameId = frameId
        self.userData = userData
    }

    // MARK: - Equal

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return userTimestamp == other.userTimestamp &&
            frameId == other.frameId &&
            userData == other.userData
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(userTimestamp)
        hasher.combine(frameId)
        hasher.combine(userData)
        return hasher.finalize()
    }
}

extension FrameMetadataFeatures {
    func toPBType() -> [Livekit_PacketTrailerFeature] {
        var features: [Livekit_PacketTrailerFeature] = []
        if userTimestamp { features.append(.ptfUserTimestamp) }
        if frameId { features.append(.ptfFrameID) }
        if userData { features.append(.ptfUserData) }
        return features
    }
}
