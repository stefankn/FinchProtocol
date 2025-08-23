//
//  Server.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation
import NIO

public actor Server {
    
    // MARK: - Private Properties
    
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    private let host: String
    private let port: Int
    
    private let onMessage: @Sendable (RequestMessage) -> Data?
    
    
    
    // MARK: - Construction
    
    public init(host: String, port: Int, onMessage: @escaping @Sendable (RequestMessage) -> Data?) {
        self.host = host
        self.port = port
        self.onMessage = onMessage
    }
    
    
    
    // MARK: - Functions

    public func start() throws {
        defer {
            try? shutdown()
        }
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(BackPressureHandler())
                    try channel.pipeline.syncOperations.addHandler(ServerChannelHandler(onMessage: self.onMessage))
                }
            }
            .childChannelOption(.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 16)
            .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        let channel = try bootstrap.bind(host: host, port: port).wait()
        
        print("SERVER: started and listening on \(channel.localAddress!)")
        try channel.closeFuture.wait()
        print("SERVER: closed")
    }
    
    public func shutdown() throws {
        try group.syncShutdownGracefully()
    }
}
