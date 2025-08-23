//
//  ServerChannelHandler.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation
import NIO

class ServerChannelHandler: ChannelInboundHandler, @unchecked Sendable {
    
    // MARK: - Types
    
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    
    // MARK: - Private Properties
    
    private let onMessage: @Sendable (RequestMessage) -> Data?
    
    
    
    // MARK: - Construction
    
    init(onMessage: @escaping @Sendable (RequestMessage) -> Data?) {
        self.onMessage = onMessage
    }
    
    
    
    // MARK: - Functions
    
    // MARK: ChannelInboundHandler Functions
    
    nonisolated func channelRegistered(context: ChannelHandlerContext) {
        print("SERVER: Incoming connection registered")
    }
    
    nonisolated func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let input = unwrapInboundIn(data)
        
        guard let typeValue = input.getBytes(at: 0, length: 1)?.first, var type = MessageType(rawValue: typeValue) else { return }

        var messageData: Data? = nil
        
        switch type {
        case .nowPlaying:
            messageData = onMessage(.nowPlayingInfo)
        case .playPlaylist:
            if let playlistId = input.getInteger(at: 1, endianness: .little, as: Int.self) {
                messageData = onMessage(.playPlaylist(playlistId: playlistId))
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
        context.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }
    
    nonisolated func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("SERVER: error - \(error)")
        context.close(promise: nil)
    }
}
