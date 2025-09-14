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
    
    
    
    // MARK: - Construction
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    
    
    // MARK: - Functions
    
    public func send(_ message: RequestMessage) async throws -> ResponseMessage {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(.socketOption(.so_reuseaddr), value: 1)
        
        let channel = try await bootstrap.connect(host: host, port: port) { channel in
            channel.eventLoop.makeCompletedFuture {
                try NIOAsyncChannel<ByteBuffer, ByteBuffer>(wrappingChannelSynchronously: channel)
            }
        }
        
        var response: ResponseMessage?
        
        try await channel.executeThenClose { inbound, outbound in
            var data = Data([message.messageType.rawValue])
            
            switch message {
            case .nowPlayingInfo, .playPreviousTrack, .playNextTrack, .play, .pause:
                break
            case .playPlaylist(let playlistId, let shuffle):
                data.append(withUnsafeBytes(of: playlistId.littleEndian) { Data($0)})
                data.append(contentsOf: [shuffle ? 1 : 0])
            case .playAlbum(albumId: let albumId, shuffle: let shuffle):
                data.append(withUnsafeBytes(of: albumId.littleEndian) { Data($0)})
                data.append(contentsOf: [shuffle ? 1 : 0])
            }
            
            let buffer = ByteBuffer(bytes: data)
            
            try await outbound.write(buffer)
            
            for try await inboundData in inbound {
                guard let typeValue = inboundData.getBytes(at: 0, length: 1)?.first else { throw ClientError.missingResponseMessageType }
                guard let type = MessageType(rawValue: typeValue) else { throw ClientError.unknownResponseMessageType(typeValue) }
                
                switch type {
                case .nowPlaying:
                    guard inboundData.readableBytes > 1 else { throw ClientError.responseError("Invalid response") }
                    let bytes = inboundData.getBytes(at: 1, length: inboundData.readableBytes - 1) ?? []
                    let info = try JSONDecoder().decode(NowPlayingInfo.self, from: Data(bytes))
                    response = .nowPlayingInfo(info)
                    return
                case .playPlaylist:
                    response = .playPlaylist
                    return
                case .error:
                    guard inboundData.readableBytes > 1 else { throw ClientError.responseError("Response failure") }
                    
                    let errorMessage = inboundData.getString(at: 1, length: inboundData.readableBytes - 1) ?? ""
                    throw ClientError.responseError(errorMessage)
                case .playAlbum:
                    response = .playAlbum
                    return
                case .playPreviousTrack:
                    response = .playPreviousTrack
                    return
                case .playNextTrack:
                    guard inboundData.readableBytes > 1 else { throw ClientError.responseError("Invalid response") }
                    let bytes = inboundData.getBytes(at: 1, length: inboundData.readableBytes - 1) ?? []
                    let result = try JSONDecoder().decode(PlayResult.self, from: Data(bytes))
                    response = .playNextTrack(result)
                    return
                case .play:
                    response = .play
                    return
                case .pause:
                    response = .pause
                    return
                }
            }
        }
        
        if let response {
            return response
        }
        
        throw ClientError.responseError("Invalid response")
    }
}
