//
//  RenderLayersCommand.swift
//  
//
//  Created by Bogdan Zykov on 12.07.2023.
//

import Foundation
import AVFoundation

struct RenderLayersCommand: RenderCommand{
    
    var type: RenderCommandType = .anyLayer
    var renderStore: VideoRenderStore
    var layers: [CALayer]
    var textLayers: [CATextLayer]
    
    func execute() async {
        
        let videoSize = renderStore.videoSize
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        parentLayer.addSublayer(videoLayer)
        
        layers.forEach{
            parentLayer.addSublayer($0)
        }
        
        textLayers.forEach {
            parentLayer.addSublayer($0)
        }
                
        renderStore.videoComposition?.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
}
