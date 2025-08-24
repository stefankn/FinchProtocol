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

    
    
    // MARK: - Construction
    
    public init(host: String = "127.0.0.1", port: Int = 8888) {
        self.host = host
        self.port = port
    }
    
    
    
    // MARK: - Functions

    public func start(onMessage: @escaping @Sendable (RequestMessage) async throws -> Data?) async throws {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 16)
            .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        let channel = try await bootstrap.bind(host: host, port: port) { childChannel in
            childChannel.eventLoop.makeCompletedFuture {
                try NIOAsyncChannel<ByteBuffer, ByteBuffer>(wrappingChannelSynchronously: childChannel)
            }
        }
        
        try await withThrowingDiscardingTaskGroup { group in
            try await channel.executeThenClose { serverChannelInbound in
                
                for try await connectionChannel in serverChannelInbound {
                    group.addTask {
                        do {
                            try await connectionChannel.executeThenClose { inbound, outbound in
                                for try await inboundData in inbound {
                                    guard let typeValue = inboundData.getBytes(at: 0, length: 1)?.first, var type = MessageType(rawValue: typeValue) else { return }
                                    
                                    var messageData: Data? = nil
                                    
                                    switch type {
                                    case .nowPlaying:
                                        messageData = try await onMessage(.nowPlayingInfo)
                                    case .playPlaylist:
                                        if let playlistId = inboundData.getInteger(at: 1, endianness: .little, as: Int.self) {
                                            messageData = try await onMessage(.playPlaylist(playlistId: playlistId))
                                        } else {
                                            type = .error
                                            messageData = "Invalid parameter for 'playlistId'".data(using: .utf8)
                                        }
                                    case .error:
                                        type = .error
                                    }
                                    
                                    var data = Data([type.rawValue])
                                    
                                    if let messageData {
                                        data.append(messageData)
                                    }
                                    
                                    let buffer = ByteBuffer(bytes: data)
                                    try await outbound.write(buffer)
                                }
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
    }
}
