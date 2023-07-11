//
//  RenderCropCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

struct RenderCropCommand: RenderCommand{
    
    var renderStore: VideoRenderStore
    var cropFrame: CGRect
    
    func execute() async {
        
        guard let duration = renderStore.composition?.duration, let videoCompositionTrack = renderStore.videoCompositionTrack else {return}
        
        let originalSize = renderStore.videoSize
        var instruction: AVMutableVideoCompositionInstruction?
        var layerInstruction: AVMutableVideoCompositionLayerInstruction?
        
        if renderStore.videoComposition?.instructions.count == 0 {
            instruction = AVMutableVideoCompositionInstruction()
            instruction?.timeRange = CMTimeRange(start: .zero, duration: duration)
            layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
            let transform = await getTransform(for: videoCompositionTrack, originalSize: originalSize)
            layerInstruction?.setTransform(transform, at: .zero)
            
        } else {
            instruction = renderStore.videoComposition?.instructions.last as? AVMutableVideoCompositionInstruction
            layerInstruction = instruction?.layerInstructions.last as? AVMutableVideoCompositionLayerInstruction
            
            let transform = await getTransform(for: videoCompositionTrack, originalSize: originalSize)
            layerInstruction?.setTransform(transform, at: .zero)
            
        }
        
        renderStore.videoComposition?.renderSize = cropFrame.size
        renderStore.videoSize = cropFrame.size
        
        if let instruction, let layerInstruction, renderStore.videoComposition?.instructions.isEmpty ?? true{
            instruction.layerInstructions.append(layerInstruction)
            renderStore.videoComposition?.instructions.append(instruction)
        }

    }
    
    private func getTransform(for track: AVAssetTrack, originalSize: CGSize) async -> CGAffineTransform{
        var finalTransform: CGAffineTransform = CGAffineTransform.identity // setup a transform that grows the video, effectively causing a crop
        let trackOrientation = await orientation(for: track)
        
        let cropRectIsPortrait = cropFrame.width <= cropFrame.height
        
        if trackOrientation == .up {
            if !cropRectIsPortrait { // center video rect vertically
                finalTransform = finalTransform
                    .translatedBy(x: originalSize.height, y: -(originalSize.width - cropFrame.size.height) / 2)
                    .rotated(by: CGFloat(90.0.radians))
            } else {
                finalTransform = finalTransform
                    .rotated(by: CGFloat(90.0.radians))
                    .translatedBy(x: 0, y: -originalSize.height)
            }
            
        } else if trackOrientation == .down {
            if !cropRectIsPortrait { // center video rect vertically (NOTE: did not test this case, since camera doesn't support .portraitUpsideDown in this app)
                finalTransform = finalTransform
                    .translatedBy(x: -originalSize.height, y: (originalSize.width - cropFrame.size.height) / 2)
                    .rotated(by: CGFloat(-90.0.radians))
            } else {
                finalTransform = finalTransform
                    .rotated(by: CGFloat(-90.0.radians))
                    .translatedBy(x: -originalSize.width, y: -(originalSize.height - cropFrame.size.height) / 2)
            }
            
        } else if trackOrientation == .right {
            if cropRectIsPortrait {
                finalTransform = finalTransform.translatedBy(x: -(originalSize.width - cropFrame.size.width) / 2, y: 0)
            } else {
                finalTransform = CGAffineTransform.identity
            }
            
        } else if trackOrientation == .left {
            if cropRectIsPortrait { // center video rect horizontally
                finalTransform = finalTransform
                    .rotated(by: CGFloat(-180.0.radians))
                    .translatedBy(x: -originalSize.width + (originalSize.width - cropFrame.size.width) / 2, y: -originalSize.height)
            } else {
                finalTransform = finalTransform
                    .rotated(by: CGFloat(-180.0.radians))
                    .translatedBy(x: -originalSize.width, y: -originalSize.height)
            }
        }
        
        return finalTransform
    }
    
    
    private enum Orientation {
        case up, down, right, left
    }
    
    private func orientation(for track: AVAssetTrack) async -> Orientation? {
        
        guard let t = try? await track.load(.preferredTransform) else{
            return .up
        }
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) {             // Portrait
            return .up
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0) {      // PortraitUpsideDown
            return .down
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0) {       // LandscapeRight
            return .right
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0) {     // LandscapeLeft
            return .left
        } else {
            return .up
        }
    }
}


extension Double{
    var radians: Double {
        self * .pi / 180
    }
}
