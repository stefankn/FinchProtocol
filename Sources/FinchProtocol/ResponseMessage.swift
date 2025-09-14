//
//  ResponseMessage.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public enum ResponseMessage: Sendable {
    case nowPlayingInfo(NowPlayingInfo)
    case playPlaylist
    case playAlbum
    case playPreviousTrack
    case playNextTrack
    case play
    case pause
}
