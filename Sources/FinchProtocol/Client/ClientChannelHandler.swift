//
//  ClientChannelHandler.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation
import NIO

final class ClientChannelHandler: ChannelInboundHandler {
    
    // MARK: - Types
    
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    
    
    // MARK: - Private Properties
    
    private let message: RequestMessage
    private let onResponse: @Sendable (ResponseMessage) -> Void
    private let onError: @Sendable (ClientError) -> Void
    
    
    
    // MARK: - Construction
    
    init(message: RequestMessage, onResponse: @escaping @Sendable (ResponseMessage) -> Void, onError: @escaping @Sendable (ClientError) -> Void) {
        self.message = message
        self.onResponse = onResponse
        self.onError = onError
    }
    
    
    
    // MARK: - Functions
    
    // MARK: ChannelInboundHandler Functions
    
    func channelActive(context: ChannelHandlerContext) {
        print("CLIENT: Connected to \(context.remoteAddress?.description ?? "unknown")")
        
        var data = Data([message.messageType.rawValue])
        
        switch message {
        case .nowPlayingInfo:
            break
        case .playPlaylist(let playlistId):
            data.append(withUnsafeBytes(of: playlistId.littleEndian) { Data($0)})
        }
        
        let buffer = ByteBuffer(bytes: data)
        
        context.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let input = unwrapInboundIn(data)
        
        guard let typeValue = input.getBytes(at: 0, length: 1)?.first else {
            onError(.missingResponseMessageType)
            context.close(promise: nil)
            return
        }
        guard let type = MessageType(rawValue: typeValue) else {
            onError(.unknownResponseMessageType(typeValue))
            context.close(promise: nil)
            return
        }
        
        if input.readableBytes > 1 {
            do {
                switch type {
                case .nowPlaying:
                    let bytes = input.getBytes(at: 1, length: input.readableBytes - 1) ?? []
                    let info = try JSONDecoder().decode(NowPlayingInfo.self, from: Data(bytes))
                    onResponse(.nowPlayingInfo(info))
                case .playPlaylist:
                    onResponse(.playPlaylist)
                case .error:
                    let errorMessage = input.getString(at: 1, length: input.readableBytes - 1) ?? ""
                    onError(.responseError(errorMessage))
                }
            } catch {
                onError(.responseDecodingFailure(error))
            }
        }
        
        context.close(promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        onError(.connectionFailure(error))
        context.close(promise: nil)
    }
}
