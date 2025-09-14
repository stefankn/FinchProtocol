//
//  RequestMessage.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public enum RequestMessage: Sendable {
    case nowPlayingInfo
    case playPlaylist(playlistId: Int, shuffle: Bool)
    case playAlbum(albumId: Int, shuffle: Bool)
    case playPreviousTrack
    case playNextTrack
    
    
    
    // MARK: - Properties
    
    var messageType: MessageType {
        switch self {
        case .nowPlayingInfo:
            return .nowPlaying
        case .playPlaylist:
            return .playPlaylist
        case .playAlbum:
            return .playAlbum
        case .playPreviousTrack:
            return .playPreviousTrack
        case .playNextTrack:
            return .playNextTrack
        }
    }
}
