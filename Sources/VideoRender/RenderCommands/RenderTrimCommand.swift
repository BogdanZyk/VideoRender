//
//  RenderTrimCommand.swift
//  
//
//  Created by Bogdan Zykov on 14.07.2023.
//

import Foundation
import AVFoundation

class RenderTrimCommand: RenderCommand{
    
    var type: RenderCommandType = .trimTime
    var renderStore: VideoRenderStore
    let endTime: CMTime
    let startTime: CMTime
    
    init(renderStore: VideoRenderStore, endTime: CMTime, startTime: CMTime) {
        self.renderStore = renderStore
        self.endTime = endTime
        self.startTime = startTime
    }
    
    func execute() async {
        
        guard let compositionVideoTrack = renderStore.videoCompositionTrack, let compositionAudioTrack = renderStore.audioCompositionTrack  else { return }
        
        let duration = CMTimeSubtract(endTime, startTime)
        let timeRange = CMTimeRange(start: startTime, duration: duration)
        
        guard let videoTracks = try? await renderStore.asset?.loadTracks(withMediaType: .video) else {return}
        
        for track in videoTracks {
            try? compositionVideoTrack.insertTimeRange(timeRange, of: track, at: CMTime.zero)
        }
        
        
        if let audioTracks = try? await renderStore.asset?.loadTracks(withMediaType: .audio){
            
            for track in audioTracks {
                try? compositionAudioTrack.insertTimeRange(timeRange, of: track, at: CMTime.zero)
            }
        }
        
        renderStore.cropTimeRange = timeRange
    }
    
}
