//
//  RenderAudioCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderAudioCommand: RenderCommand {
    
    var type: RenderCommandType = .audio
    var renderStore: VideoRenderStore
    var audioAsset: AVAsset
    var startingAt: Double
    var trackDuration: Double
    var videoLevel: Float = 1.0
    var musicLevel: Float = 1.0
    
    init(renderStore: VideoRenderStore,
         audioAsset: AVAsset,
         startingAt: Double?,
         trackDuration: Double?,
         videoLevel: Float = 1.0,
         musicLevel: Float = 1.0) {
        
        self.renderStore = renderStore
        self.audioAsset = audioAsset
        self.startingAt = startingAt ?? 0
        self.trackDuration = trackDuration ?? .greatestFiniteMagnitude
        self.videoLevel = videoLevel
        self.musicLevel = musicLevel
    }
    
    func execute() async {
        
        guard let musicTrack = try? await audioAsset.load(.tracks).first,
              let audioDuration = try? await audioAsset.load(.duration),
              let videoDuration = renderStore.videoCompositionTrack?.timeRange.duration,
              let musicCompositionTrack = renderStore.composition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        let audioMix = AVMutableAudioMix()
        var mixParameters = [AVMutableAudioMixInputParameters]()
        
        if let audioAssetTrack = renderStore.assetAudioTrack, let audioCompositionTrack = renderStore.audioCompositionTrack{
            let audioParameters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
            audioParameters.trackID = audioCompositionTrack.trackID
            audioParameters.setVolume(videoLevel, at: .zero)
            mixParameters.append(audioParameters)
        }
        
        let musicParameters = AVMutableAudioMixInputParameters(track: musicTrack)
        musicParameters.trackID = musicCompositionTrack.trackID
        musicParameters.setVolume(musicLevel, at: .zero)
        mixParameters.append(musicParameters)
        
        audioMix.inputParameters = mixParameters
    
        let startTime = CMTime(seconds: startingAt, preferredTimescale: videoDuration.timescale)
        
        guard let timeRange = calcTimeRange(videoDuration: videoDuration, audioDuration: audioDuration, startTime: startTime) else { return }
        
        do {
            try musicCompositionTrack.insertTimeRange(timeRange, of: musicTrack, at: startTime)
            renderStore.audioMix = audioMix
        } catch {
            print("RenderAudioCommand error: \(error.localizedDescription)")
        }
    }
    
    private func calcTimeRange(videoDuration: CMTime, audioDuration: CMTime, startTime: CMTime) -> CMTimeRange?{
    

        let trackDurationTime = CMTime(seconds: trackDuration, preferredTimescale: videoDuration.timescale)
        
        if CMTimeCompare(videoDuration, startTime) == -1 {
            return nil
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
        
       return CMTimeRange(start: .zero, duration: duration)
    }
}

