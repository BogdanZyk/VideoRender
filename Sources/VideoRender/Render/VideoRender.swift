//
//  VideoRender.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation


public class VideoRender{
    
    ///Render store - all the information about the video renderer
    private var renderStore: VideoRenderStore
    
    ///Render commands
    private var commands = [RenderCommand]()
        
    public init(videoURL: URL) async throws {
        let asset = AVURLAsset(url: videoURL)
        self.renderStore = try await VideoRenderStore(asset: asset)
    }
    
    public init(videoURLs: [URL]) async throws{
        self.renderStore = try await VideoRenderStore(urls: videoURLs)
    }
}

extension VideoRender{
    
    /// Start exporting video
    /// - Parameters:
    ///   - exportURL: URL of exported video
    ///   - presetName: PresetNameEnum export preset name, default exportPresetHighestQuality
    ///   - optimizeForNetworkUse: Optimize video quality for network
    ///   - frameRate: Video frameRateEnum default  30fps
    ///   - outputFileType: outputFileType
    /// - Returns: AVAssetExportSession
    public func export(exportURL: URL,
                       presetName: PresetNameEnum = .exportPresetHighestQuality,
                       optimizeForNetworkUse: Bool = true,
                       frameRate: VideoRate = .fps30,
                       outputFileType: AVFileType) async throws -> AVAssetExportSession{
        
        try await applyCommands()
        
        guard let videoDataComposition = renderStore.composition else {
            throw VideoRenderError.unknown("Empty AVMutableComposition")
        }
        
        guard let exportSession = AVAssetExportSession(asset: videoDataComposition, presetName: presetName.value) else {
            throw VideoRenderError.failedInitExportSession
        }
        
        if let videoComposition = renderStore.videoComposition {
            
            if videoComposition.instructions.isEmpty{
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: renderStore.videoCompositionTrack?.timeRange.duration ?? .zero)
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: renderStore.videoCompositionTrack!)
                
                instruction.layerInstructions = [layerInstruction]
                videoComposition.instructions = [instruction]
            }
            
            videoComposition.frameDuration = CMTime(value: 1, timescale: frameRate.rawValue)
            exportSession.videoComposition = videoComposition
            
        }
        
        ///Remove old video file
        let fileManager = FileManager.default
        fileManager.removeFileIfExists(for: exportURL)
        if let mergedUrl = renderStore.mergedUrl{
            fileManager.removeFileIfExists(for: mergedUrl)
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = exportURL
        exportSession.shouldOptimizeForNetworkUse = optimizeForNetworkUse
        
        if let audioMix = renderStore.audioMix{
            exportSession.audioMix = audioMix
        }
        
        if let newTime = renderStore.cropTimeRange{
            exportSession.timeRange = newTime
        }
        
        await exportSession.export()
        
        if let error = exportSession.error{
            throw VideoRenderError.unknown(error.localizedDescription)
        }
        
        return exportSession
    }
    
    private func applyCommands() async throws {
        
        let sortCommands = commands.sorted(by: {$0.type != .trimTime && $1.type == .trimTime})
        print(sortCommands.map({$0.type}))
        for try await command in AsyncCommandSequence(commands: commands) {
            await command.execute()
        }
    }
}


extension VideoRender{
    
    
    /// Rotate video
    /// - Parameter rotateDegree: Rotate degree enum
    /// Default rotation is 90 degrees to the right
    public func rotate(rotateDegree: RotateDegreeEnum = .rotateDegree90){
        let command = RenderRotateCommand(renderStore: renderStore, rotateDegree: rotateDegree)
        commands.append(command)
    }
    
    /// Scale video time scaled factor 0.1 - 8.0
    /// - Parameter timeScale: scaled factor 0.1 - 8.0
    public func scaleTime(timeScale: Float64){
        let command = RenderScaleTimeCommand(renderStore: renderStore, timeScale: timeScale)
        commands.append(command)
    }
    
    /// Crop video
    /// - Parameter cropFrame: Crop point, crop size width height
    public func crop(cropFrame: CGRect) {
        let command = RenderCropCommand(renderStore: renderStore, cropFrame: cropFrame)
        commands.append(command)
    }
    
    /// Mirror horizontally or vertically
    /// isHorizontal - true,  vertical - false
    public func mirror(isHorizontal: Bool = true){
        let command = RenderMirrorCommand(renderStore: renderStore, isHorizontal: isHorizontal)
        commands.append(command)
    }
    
    /// Crop video time
    /// - Parameter timeRange: Video trimming time range
    /// CMTime(seconds: 2, preferredTimescale: 1000)
    /// CMTime(seconds: 3, preferredTimescale: 1000)
    /// CMTimeRange(start: , duration: )
    public func cropTime(timeRange: CMTimeRange){
        let command = RenderTrimCommand(renderStore: renderStore, endTime: timeRange.end, startTime: timeRange.start)
        commands.append(command)
    }
    
    /// Add text or a frame to the video
    /// - Parameters:
    ///   - videoFrameLayer: Video frame model and size
    ///   - textBoxLayers: Text boxes for text layers
    ///   - playerFrame: Size of the displayed video area for calculating test box positions
    /// Use one of the methods for adding layers (addTextLayers or addLayers)
    /// Use only on real device, crash when adding layers on simulator!
    public func addTextLayers(videoFrameLayer: VideoFrame, textBoxLayers: [TextBox] = [], playerFrame: CGSize) {
        let command = RenderTextLayerCommand(renderStore: renderStore, videoFrame: videoFrameLayer, textBoxes: textBoxLayers, playerFrame: playerFrame)
        commands.append(command)
    }
    
    /// Add a CALayer to the video and any CATextLayer
    /// - Parameters:
    ///   - layers: [CALayer]
    ///   - textLayer: [CATextLayer]
    ///   Use one of the methods for adding layers (addTextLayers or addLayers)
    ///   Use only on real device, crash when adding layers on simulator!
    public func addLayers(layers: [CALayer], textLayer: [CATextLayer] = []){
        let command = RenderLayersCommand(renderStore: renderStore, layers: layers, textLayers: textLayer)
        commands.append(command)
    }
    
    /// Adds an audio track to a video
    /// - Parameters:
    ///   - asset: audio AVAsset
    ///   - startingAt: Track start in seconds or zero
    ///   - trackDuration: Track duration in seconds or all available video duration
    ///   - volume: audio volume 0...1
    public func addAudio(asset: AVAsset, startingAt: Double? = nil, trackDuration: Double? = nil, videoLevel: Float = 1.0, musicLevel: Float = 1.0) {
        let command = RenderAudioCommand(renderStore: renderStore, audioAsset: asset, startingAt: startingAt, trackDuration: trackDuration, videoLevel: videoLevel, musicLevel: musicLevel)
        commands.append(command)
    }
    
    /// Set video volume 0...1
    /// - Parameter value: volume 0...1
    public func setVolume(value: Float){
        let command = RenderVolumeCommand(renderStore: renderStore, volume: value)
        commands.append(command)
    }
}






