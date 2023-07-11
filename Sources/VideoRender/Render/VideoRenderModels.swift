//
//  VideoRenderModels.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation
import AVFoundation
import SwiftUI


public enum RotateDegreeEnum: Int{
    case rotateDegree90 = 1
    case rotateDegree180 = 2
    case rotateDegree270 = 3
}

public enum VideoRate: Int32{
    
    case fps15 = 15
    case fps30 = 30
    case fps24 = 24
    case fps60 = 60
    case fps120 = 120
}

public enum PresetNameEnum: String{
    
    case exportPreset1280x720
    case exportPreset640x480
    case exportPreset960x540
    case exportPreset1920x1080
    case exportPreset3840x2160
    case exportPresetAppleM4A
    case exportPresetPassthrough
    case exportPresetLowQuality
    case exportPresetHEVC1920x1080
    case exportPresetHEVC3840x2160
    case exportPresetMediumQuality
    case exportPresetHighestQuality
    case exportPresetHEVC1920x1080WithAlpha
    case exportPresetHEVCHighestQualityWithAlpha
    
    
    var value: String{
        switch self{
        case .exportPreset1280x720:
            return AVAssetExportPreset1280x720
        case .exportPreset640x480:
            return AVAssetExportPreset640x480
        case .exportPreset960x540:
            return AVAssetExportPreset960x540
        case .exportPreset3840x2160:
            return AVAssetExportPreset3840x2160
        case .exportPresetAppleM4A:
            return AVAssetExportPresetAppleM4A
        case .exportPresetPassthrough:
            return AVAssetExportPresetPassthrough
        case .exportPresetLowQuality:
            return AVAssetExportPresetLowQuality
        case .exportPresetHEVC1920x1080:
            return AVAssetExportPresetHEVC1920x1080
        case .exportPresetHEVC3840x2160:
            return AVAssetExportPresetHEVC3840x2160
        case .exportPresetMediumQuality:
            return AVAssetExportPresetMediumQuality
        case .exportPresetHighestQuality:
            return AVAssetExportPresetHighestQuality
        case .exportPresetHEVC1920x1080WithAlpha:
            return AVAssetExportPresetHEVC1920x1080WithAlpha
        case .exportPresetHEVCHighestQualityWithAlpha:
            return AVAssetExportPresetHEVCHighestQualityWithAlpha
        case .exportPreset1920x1080:
            return AVAssetExportPreset1920x1080
        }
    }
    
}


public struct VideoFrame{
    
    var scaleValue: Double
    var frameColor: Color
    let scale: Double

    init(scaleValue: Double = 0, frameColor: Color = .white) {
        self.scaleValue = scaleValue
        self.frameColor = frameColor
        self.scale = 1 - scaleValue
    }
}


public struct TextBox{
    
    var text: String = ""
    var fontSize: CGFloat = 20
    var bgColor: Color = .white
    var fontColor: Color = .black
    var offset: CGSize = .zero
    var timeRange: ClosedRange<Double> = 0...3
    var withAnimation: Bool = true
}

