//
//  RenderMirrorCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderMirrorCommand: RenderCommand{
    
    var renderStore: VideoRenderStore
    var isHorizontal: Bool
    
    func execute() async {
        
        guard let duration = renderStore.composition?.duration, let videoCompositionTrack = renderStore.videoCompositionTrack else {return}
        
        let size = renderStore.videoSize
        var instruction: AVMutableVideoCompositionInstruction?
        var layerInstruction: AVMutableVideoCompositionLayerInstruction?
        
        if renderStore.videoComposition?.instructions.count == 0 {
            instruction = AVMutableVideoCompositionInstruction()
            instruction?.timeRange = CMTimeRange(start: .zero, duration: duration)
            layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        } else {
            
            instruction = renderStore.videoComposition?.instructions.last as? AVMutableVideoCompositionInstruction
            layerInstruction = instruction?.layerInstructions.last as? AVMutableVideoCompositionLayerInstruction
        }
        
        
        ///Mirror transform
        var transform: CGAffineTransform = CGAffineTransform(scaleX: isHorizontal ? -1.0 : 1.0, y: isHorizontal ? 1.0 : -1.0)
        transform = transform.translatedBy(x: isHorizontal ? -size.width : 0, y: isHorizontal ? 0 : -size.height)
        layerInstruction?.setTransform(transform, at: .zero)

        if let instruction, let layerInstruction, renderStore.videoComposition?.instructions.isEmpty ?? true{
            instruction.layerInstructions.append(layerInstruction)
            renderStore.videoComposition?.instructions.append(instruction)
        }
    }
}

