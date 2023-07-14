//
//  RenderTextLayerCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

#if canImport(UIKit)

import UIKit

#endif

#if canImport(AppKit)

import AppKit

#endif


struct RenderTextLayerCommand: RenderCommand {
    
    var type: RenderCommandType = .textLayer
    var renderStore: VideoRenderStore
    var videoFrame: VideoFrame
    var textBoxes: [TextBox]
    var playerFrame: CGSize
    
    init(renderStore: VideoRenderStore,
         videoFrame: VideoFrame = .init(),
         textBoxes: [TextBox] = [],
         playerFrame: CGSize = .zero) {
        
        self.renderStore = renderStore
        self.videoFrame = videoFrame
        self.textBoxes = textBoxes
        self.playerFrame = playerFrame
    }
    
    func execute() async {

        let videoSize = renderStore.videoSize
        let duration = renderStore.videoCompositionTrack?.timeRange.duration
        
        let color = videoFrame.frameColor
        let scale = videoFrame.scale
        
        let scaleSize = CGSize(width: videoSize.width * scale, height: videoSize.height * scale)
        let centerPoint = CGPoint(x: (videoSize.width - scaleSize.width)/2, y: (videoSize.height - scaleSize.height)/2)
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: centerPoint, size: scaleSize)
        let bgLayer = CALayer()
        bgLayer.frame = CGRect(origin: .zero, size: videoSize)
        
#if os(iOS)
        bgLayer.backgroundColor = UIColor(color).cgColor
#else
        bgLayer.backgroundColor = NSColor(color).cgColor
#endif
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        
        outputLayer.addSublayer(bgLayer)
        outputLayer.addSublayer(videoLayer)
        
        
        if !textBoxes.isEmpty{
            textBoxes.forEach { text in
                let position = convertViewFrameToVideoFrame(text.offset, fromFrame: playerFrame, toFrame: videoSize)
                let textLayer = createTextLayer(with: text, size: videoSize, position: position.size, ratio: position.ratio, duration: duration?.seconds ?? .zero)
                outputLayer.addSublayer(textLayer)
            }
        }
        
        renderStore.videoComposition?.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
    }
    
    
    
   private func convertViewFrameToVideoFrame(_ size: CGSize, fromFrame frameSize1: CGSize, toFrame frameSize2: CGSize) -> (size: CGSize, ratio: Double) {
       
        let widthRatio = frameSize2.width / frameSize1.width
        let heightRatio = frameSize2.height / frameSize1.height
        let ratio = max(widthRatio, heightRatio)
        let newSizeWidth = size.width * ratio
        let newSizeHeight = size.height * ratio
        
        let newSize = CGSize(width: (frameSize2.width / 2) + newSizeWidth, height: (frameSize2.height / 2) + -newSizeHeight)
        
        return (CGSize(width: newSize.width, height: newSize.height), ratio)
    }
    
    private func createTextLayer(with model: TextBox, size: CGSize, position: CGSize, ratio: Double, duration: Double) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = model.text
        
#if os(iOS)
        textLayer.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textLayer.foregroundColor = UIColor(model.fontColor).cgColor
        textLayer.backgroundColor = UIColor(model.bgColor).cgColor
#else
        textLayer.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        textLayer.foregroundColor = NSColor(model.fontColor).cgColor
        textLayer.backgroundColor = NSColor(model.bgColor).cgColor
#endif
        textLayer.fontSize = model.fontSize * ratio
        textLayer.alignmentMode = .center
        textLayer.cornerRadius = 5
        let size = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: position.width, y: position.height, width: size.width + 6, height: size.height)
        
        if model.withAnimation{
            addOpacityAnimation(to: textLayer, with: model.timeRange, duration: duration)
        }
        
        return textLayer
    }

    private func addOpacityAnimation(to textLayer: CATextLayer, with timeRange: ClosedRange<Double>, duration: Double) {
        
        if timeRange.lowerBound > 0{
            let appearance = CABasicAnimation(keyPath: "opacity")
            appearance.fromValue = 0
            appearance.toValue = 1
            appearance.duration = 0.05
            appearance.beginTime = timeRange.lowerBound
            appearance.fillMode = .forwards
            appearance.isRemovedOnCompletion = false
            textLayer.add(appearance, forKey: "Appearance")
            textLayer.opacity = 0
        }
        
        if timeRange.upperBound < duration{
            let disappearance = CABasicAnimation(keyPath: "opacity")
            disappearance.fromValue = 1
            disappearance.toValue = 0
            disappearance.beginTime = timeRange.upperBound
            disappearance.duration = 0.05
            disappearance.fillMode = .forwards
            disappearance.isRemovedOnCompletion = false
            textLayer.add(disappearance, forKey: "Disappearance")
        }
    }
}





