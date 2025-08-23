//
//  MessageType.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

enum MessageType: UInt8 {
    case nowPlaying
    case playPlaylist
    
    case error = 255
}
