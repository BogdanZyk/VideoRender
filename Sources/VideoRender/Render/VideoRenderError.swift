//
//  VideoRenderError.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation

enum VideoRenderError {
    case unknown(String)
    case failedLoadVideoTrack
    case failedLoadAudioTrack
    case failedLoadNaturalSize
    case failedLoadDuration
    case failedInitExportSession
}

extension VideoRenderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknown(let error):
            return "Unknown render error \(error)"
        case .failedLoadAudioTrack:
            return "Failed to load audio track"
        case .failedLoadVideoTrack:
            return "Failed to load video track"
        case .failedLoadNaturalSize:
            return "Failed to load natural video size"
        case .failedLoadDuration:
            return "Failed to load duration"
        case .failedInitExportSession:
            return "Failed init AVAssetExportSession"
        }
    }
}
