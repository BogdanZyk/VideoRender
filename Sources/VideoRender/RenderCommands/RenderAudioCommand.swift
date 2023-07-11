//
//  RenderAudioCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderAudioCommand: RenderCommand {
    
    var renderStore: VideoRenderStore
    var audioAsset: AVAsset
    var startingAt: Double
    var trackDuration: Double
    var volume: Float = 1.0
    
    init(renderStore: VideoRenderStore, audioAsset: AVAsset, startingAt: Double?, trackDuration: Double?, volume: Float = 1.0) {
        self.renderStore = renderStore
        self.audioAsset = audioAsset
        self.startingAt = startingAt ?? 0
        self.trackDuration = trackDuration ?? .greatestFiniteMagnitude
        self.volume = volume
    }
    
    func execute() async {
        
        guard let track = try? await audioAsset.load(.tracks).first,
              let audioDuration = try? await audioAsset.load(.duration),
              let videoDuration = renderStore.videoCompositionTrack?.timeRange.duration else { return }
        
        let audioCompositionTrack = renderStore.composition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let startTime = CMTime(seconds: startingAt, preferredTimescale: videoDuration.timescale)
        
        let trackDurationTime = CMTime(seconds: trackDuration, preferredTimescale: videoDuration.timescale)
        
        if CMTimeCompare(videoDuration, startTime) == -1 {
            return
        }
        
        let availableTrackDuration = CMTimeSubtract(videoDuration, CMTime(seconds: startingAt, preferredTimescale: videoDuration.timescale))
        
        var duration: CMTime
        
        if CMTimeCompare(availableTrackDuration, audioDuration) == -1 {
            duration = availableTrackDuration
        } else {
            duration = audioDuration
        }
        
        if CMTimeCompare(trackDurationTime, duration) == -1 {
            duration = trackDurationTime
        }
        
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        
        do {
            try audioCompositionTrack?.insertTimeRange(timeRange, of: track, at: startTime)
            audioCompositionTrack?.preferredVolume = volume
        } catch {
            print("RenderAudioCommand error: \(error.localizedDescription)")
        }
    }
}

