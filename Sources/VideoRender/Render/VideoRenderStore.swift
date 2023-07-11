//
//  VideoRenderStore.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation

final class VideoRenderStore {
    
    var composition: AVMutableComposition?
    var assetVideoTrack: AVAssetTrack?
    var assetAudioTrack: AVAssetTrack?
    var videoComposition: AVMutableVideoComposition?
    var videoCompositionTrack: AVMutableCompositionTrack?
    var audioCompositionTrack: AVMutableCompositionTrack?
    var videoSize: CGSize = .zero
    var cropTimeRange: CMTimeRange? = nil
    var mergedUrl: URL?
    var audioMix: AVAudioMix?
    
    
    /// Create render instances from a single video
    init(asset: AVAsset) async throws {
        try await self.loadAsset(asset: asset)
    }
    
    /// Creates a render instance from multiple videos merged into a single video
    init(urls: [URL]) async throws {
        let mergedVideo = try await createMergedVideo(urls)
        try await loadAsset(asset: mergedVideo)
    }
    
    
    /// Load asset data
    func loadAsset(asset: AVAsset) async throws {
        
        /// Load video/audio tracks
        guard let assetVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoRenderError.failedLoadVideoTrack }
        
        let assetAudioTrack = try? await asset.loadTracks(withMediaType: .audio).first
        
        self.assetVideoTrack = assetVideoTrack
        self.assetAudioTrack = assetAudioTrack
        
        /// Load video naturalSize
        guard let naturalSize = try? await assetVideoTrack.load(.naturalSize) else {
            throw VideoRenderError.failedLoadNaturalSize
        }
        
        /// Load video duration
        guard let duration = try? await asset.load(.duration) else {
            throw VideoRenderError.failedLoadDuration
        }
        
        videoSize = naturalSize
        
        composition = AVMutableComposition()
        videoComposition = AVMutableVideoComposition()
        videoComposition?.renderSize = videoSize
        
        
        let insertionPoint: CMTime = .zero
        
        ///Adding video track for AVMutableComposition
        if let assetVideoTrack = self.assetVideoTrack {
            videoCompositionTrack = composition?.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetVideoTrack, at: insertionPoint)
            } catch {
                throw VideoRenderError.unknown(error.localizedDescription)
            }
        }
        
        ///Adding audio track for AVMutableComposition
        if let assetAudioTrack = self.assetAudioTrack {
            audioCompositionTrack = composition?.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetAudioTrack, at: insertionPoint)
            } catch {
                throw VideoRenderError.unknown(error.localizedDescription)
            }
        }
    }
    
    
    private func createMergedVideo(_ urls: [URL]) async throws -> AVAsset{

        
        let fileManager = FileManager.default
        let composition = AVMutableComposition()
        
        do{
            try await mergeVideos(to: composition, from: urls, audioEnabled: false)
            ///Remove all cash videos
            urls.forEach { url in
                fileManager.removeFileIfExists(for: url)
            }
            
        }catch{
            print(error.localizedDescription)
        }
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        let exportUrl = URL.documentsDirectory.appending(path: "merged_video.mp4")
        fileManager.removeFileIfExists(for: exportUrl)
        
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = .mp4
        exporter?.shouldOptimizeForNetworkUse = false
        
        await exporter?.export()
        
        if exporter?.status == .completed {
            self.mergedUrl = exportUrl
            return AVAsset(url: exportUrl)
        }else{
            throw VideoRenderError.unknown(exporter?.error?.localizedDescription ?? "")
        }
    }
    
    private func mergeVideos(to composition: AVMutableComposition,
                             from urls: [URL], audioEnabled: Bool) async throws{
        
        let assets = urls.map({AVAsset(url: $0)})
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let compositionAudioTrack: AVMutableCompositionTrack? = audioEnabled ? composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) : nil
        
        var lastTime: CMTime = .zero
        
        for asset in assets {
            
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            let audioTracks = try? await asset.loadTracks(withMediaType: .audio)
            
            let duration = try await asset.load(.duration)
           
            let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
        
            if let audioTracks, !audioTracks.isEmpty, let audioTrack = audioTracks.first,
               let compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: lastTime)
                let audioPreferredTransform = try await audioTrack.load(.preferredTransform)
                compositionAudioTrack.preferredTransform = audioPreferredTransform
            }
            
            guard let videoTrack = videoTracks.first else {return}
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: lastTime)
            let videoPreferredTransform = try await videoTrack.load(.preferredTransform)
            compositionVideoTrack?.preferredTransform = videoPreferredTransform
            
            lastTime = CMTimeAdd(lastTime, duration)
        }
    }
}




extension FileManager{
    func removeFileIfExists(for url: URL){
        if fileExists(atPath: url.path), isDeletableFile(atPath: url.path){
            do{
                try removeItem(at: url)
            }catch{
                print("Error to remove item", error.localizedDescription)
            }
        }
    }
}
