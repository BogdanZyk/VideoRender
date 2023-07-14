//
//  RenderVolumeCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderVolumeCommand: RenderCommand{
    
    var type: RenderCommandType = .volume
    var renderStore: VideoRenderStore
    var volume: Float
    
    func execute() async {
        
        guard let audioAssetTrack = renderStore.assetAudioTrack, let audioCompositionTrack = renderStore.audioCompositionTrack else { return }
        
        let audioMix = AVMutableAudioMix()
        var mixParameters = [AVMutableAudioMixInputParameters]()
        
        let audioParameters = AVMutableAudioMixInputParameters(track: audioAssetTrack)
        audioParameters.trackID = audioCompositionTrack.trackID
        audioParameters.setVolume(volume, at: .zero)
        mixParameters.append(audioParameters)
        
        audioMix.inputParameters = mixParameters
        
        renderStore.audioMix = audioMix
    }
    
    
}
