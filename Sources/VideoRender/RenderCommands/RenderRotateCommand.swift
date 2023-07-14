//
//  RenderRotateCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderRotateCommand: RenderCommand{
    
    var type: RenderCommandType = .rotate
    var renderStore: VideoRenderStore
    var rotateDegree: RotateDegreeEnum
    
    
    init(renderStore: VideoRenderStore, rotateDegree: RotateDegreeEnum = .rotateDegree90) {
        self.renderStore = renderStore
        self.rotateDegree = rotateDegree
    }
    
    func execute() async {
        for _ in 0..<rotateDegree.rawValue {
            rotate()
        }
    }
    
    
    private func rotate(){
        var videoSize = renderStore.videoSize
        var instruction: AVMutableVideoCompositionInstruction?
        var layerInstruction: AVMutableVideoCompositionLayerInstruction?
        
        let t1 = CGAffineTransform(translationX: videoSize.height, y: 0.0)
        
        let t2 = t1.rotated(by: 90.0.radians)
        
        videoSize = CGSize(width: videoSize.height, height: videoSize.width)
        
        let duration = renderStore.videoCompositionTrack?.timeRange.duration
        
        if renderStore.videoComposition?.instructions.count == 0 {
            instruction = AVMutableVideoCompositionInstruction()
            instruction?.timeRange = CMTimeRange(start: .zero, duration: duration ?? .zero)
            if let videoCompositionTrack = renderStore.videoCompositionTrack {
                layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
                layerInstruction?.setTransform(t2, at: .zero)
            }
        } else {
            instruction = renderStore.videoComposition?.instructions.last as? AVMutableVideoCompositionInstruction
            layerInstruction = instruction?.layerInstructions.last as? AVMutableVideoCompositionLayerInstruction
            if let duration = duration {
                var start = CGAffineTransform()
                let success = layerInstruction?.getTransformRamp(for: duration, start: &start, end: nil, timeRange: nil) ?? false
                if !success {
                    layerInstruction?.setTransform(t2, at: .zero)
                } else {
                    let newTransform = start.concatenating(t2)
                    layerInstruction?.setTransform(newTransform, at: .zero)
                }
            }
        }
        renderStore.videoComposition?.renderSize = videoSize
        renderStore.videoSize = videoSize
        if let layerInstruction = layerInstruction {
            instruction?.layerInstructions = [layerInstruction]
        }
        if let instruction = instruction {
            renderStore.videoComposition?.instructions = [instruction]
        }
    }
}




