//
//  Client.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation
import NIO

public actor Client {
    
    // MARK: - Private Properties

    private let host: String
    private let port: Int
    private let onResponse: @Sendable (ResponseMessage) -> Void
    private let onError: @Sendable (ClientError) -> Void
    
    
    
    // MARK: - Construction
    
    public init(host: String, port: Int, onResponse: @escaping @Sendable (ResponseMessage) -> Void, onError: @escaping @Sendable (ClientError) -> Void) {
        self.host = host
        self.port = port
        self.onResponse = onResponse
        self.onError = onError
    }
    
    
    
    // MARK: - Functions
    
    public func send(_ message: RequestMessage) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandlers(ClientChannelHandler(message: message, onResponse: self.onResponse, onError: self.onError))
                }
            }
        defer {
            try? group.syncShutdownGracefully()
        }
        
        let channel = try bootstrap.connect(host: host, port: port).wait()
        try channel.closeFuture.wait()
        
        print("CLIENT: closed")
    }
}
