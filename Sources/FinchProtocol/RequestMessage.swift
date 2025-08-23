//
//  RequestMessage.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public enum RequestMessage: Sendable {
    case nowPlayingInfo
    case playPlaylist(playlistId: Int)
    
    
    
    // MARK: - Properties
    
    var messageType: MessageType {
        switch self {
        case .nowPlayingInfo:
            return .nowPlaying
        case .playPlaylist:
            return .playPlaylist
        }
    }
}
