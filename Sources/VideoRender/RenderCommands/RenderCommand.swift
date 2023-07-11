//
//  RenderCommand.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation

protocol RenderCommand {
    
    var renderStore: VideoRenderStore { get set }
    
    func execute() async
}
