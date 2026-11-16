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
@testable import LiveKit
import Testing
#if canImport(LiveKitTestSupport)
import LiveKitTestSupport
#endif

@Suite(.tags(.media))
struct FrameMetadataFeaturesTests {
    @Test func defaultVideoPublishOptionsDeclareNoFeatures() {
        #expect(VideoPublishOptions().frameMetadataFeatures == FrameMetadataFeatures())
        #expect(VideoPublishOptions().frameMetadataFeatures.toPBType().isEmpty)
    }

    @Test func eachFeatureMapsToItsPacketTrailerFeature() {
        #expect(FrameMetadataFeatures(userTimestamp: true).toPBType() == [.ptfUserTimestamp])
        #expect(FrameMetadataFeatures(frameId: true).toPBType() == [.ptfFrameID])
        #expect(FrameMetadataFeatures(userData: true).toPBType() == [.ptfUserData])
        #expect(FrameMetadataFeatures(userTimestamp: true, frameId: true, userData: true).toPBType()
            == [.ptfUserTimestamp, .ptfFrameID, .ptfUserData])
    }

    @Test func optionsDifferingOnlyInFeaturesAreNotEqual() {
        let plain = VideoPublishOptions()
        let declared = VideoPublishOptions(frameMetadataFeatures: FrameMetadataFeatures(frameId: true))
        #expect(plain != declared)
        #expect(declared == VideoPublishOptions(frameMetadataFeatures: FrameMetadataFeatures(frameId: true)))
        #expect(declared.hash == VideoPublishOptions(frameMetadataFeatures: FrameMetadataFeatures(frameId: true)).hash)
    }
}

@Suite(.serialized, .tags(.media, .e2e), TestLimits.e2e)
struct FrameMetadataFeaturesPublishTests {
    @Test func declaredFeaturesReachTheSubscriber() async throws {
        let features = FrameMetadataFeatures(userTimestamp: true, frameId: true)

        try await TestEnvironment.withRooms([RoomTestingOptions(canPublish: true), RoomTestingOptions(canSubscribe: true)]) { rooms in
            let publisher = rooms[0].localParticipant
            let publisherIdentity = try #require(publisher.identity)
            let remote = try #require(rooms[1].remoteParticipants[publisherIdentity])

            let track = await LocalVideoTrack.createBufferTrack(options: BufferCaptureOptions(dimensions: .h360_169))
            let capturer = try #require(track.capturer as? BufferCapturer)
            let captureTask = try await createSampleVideoTrack { buffer in
                capturer.capture(buffer)
            }
            defer { captureTask.cancel() }

            try await publisher.publish(videoTrack: track,
                                        options: VideoPublishOptions(simulcast: false, frameMetadataFeatures: features))

            let deadline = Date().addingTimeInterval(15)
            while Date() < deadline, remote.videoTracks.isEmpty {
                try await Task.sleep(nanoseconds: 200_000_000)
            }
            let publication = try #require(remote.videoTracks.first)
            #expect(publication._state.latestInfo?.packetTrailerFeatures == features.toPBType())
        }
    }
}
