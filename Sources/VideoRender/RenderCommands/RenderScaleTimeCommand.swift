//
//  RenderScaleTimeCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderScaleTimeCommand: RenderCommand{
    
    var type: RenderCommandType = .scaleTime
    var renderStore: VideoRenderStore
    var timeScale: Float64
    
    
    func execute() async {
        
        guard let videoTrack = renderStore.assetVideoTrack,
              let duration = renderStore.videoCompositionTrack?.timeRange.duration else {return}
        
        let audioTrack = renderStore.assetAudioTrack
        
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
        let destinationTimeRange = CMTimeMultiplyByFloat64(duration, multiplier: 1 / timeScale)
        
        ///Set audio speed
        if let audioTrack{
            do{
                renderStore.audioCompositionTrack?.scaleTimeRange(timeRange, toDuration: destinationTimeRange)
                let audioPreferredTransform = try await audioTrack.load(.preferredTransform)
                renderStore.audioCompositionTrack?.preferredTransform = audioPreferredTransform
            }catch{
                print(error.localizedDescription)
            }
        }
        
        ///Set video speed
        do{
            renderStore.videoCompositionTrack?.scaleTimeRange(timeRange, toDuration: destinationTimeRange)
            let audioPreferredTransform = try await videoTrack.load(.preferredTransform)
            renderStore.videoCompositionTrack?.preferredTransform = audioPreferredTransform
        }catch{
            print(error.localizedDescription)
        }
    }
}


