import AVFoundation
import Foundation

@main
struct MuxPauseDemo {
    static func main() async throws {
        guard CommandLine.arguments.count == 4 else {
            throw NSError(domain: "PauseDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Usage: mux_pause_demo video audio output"])
        }

        let videoURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let audioURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
        try? FileManager.default.removeItem(at: outputURL)

        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        let composition = AVMutableComposition()

        guard
            let sourceVideo = try await videoAsset.loadTracks(withMediaType: .video).first,
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let sourceAudio = try await audioAsset.loadTracks(withMediaType: .audio).first,
            let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            throw NSError(domain: "PauseDemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing video or audio track"])
        }

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: sourceVideo, at: .zero)
        videoTrack.preferredTransform = try await sourceVideo.load(.preferredTransform)

        let narrationStart = CMTime(seconds: 0.8, preferredTimescale: 600)
        let available = CMTimeSubtract(videoDuration, narrationStart)
        let narrationDuration = CMTimeMinimum(audioDuration, available)
        try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: narrationDuration), of: sourceAudio, at: narrationStart)

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "PauseDemo", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create exporter"])
        }
        try await exporter.export(to: outputURL, as: .mp4)
    }
}
