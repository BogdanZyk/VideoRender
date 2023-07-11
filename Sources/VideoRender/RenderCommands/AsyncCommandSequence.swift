//
//  AsyncCommandSequence.swift
//  
//
//  Created by Bogdan Zykov on 11.07.2023.
//

import Foundation


struct AsyncCommandSequence: AsyncSequence {
    let commands: [RenderCommand]
    typealias Element = RenderCommand
    
    
    struct AsyncCommandIterator: AsyncIteratorProtocol {
        
        typealias Element = RenderCommand
        
        var arrayIterator: IndexingIterator<[RenderCommand]>
        
        mutating func next() async throws -> Element? {
            guard let command = arrayIterator.next() else { return nil }
            return command
        }
    }
    
    func makeAsyncIterator() -> AsyncCommandIterator {
        AsyncCommandIterator(arrayIterator: commands.makeIterator())
    }
}
