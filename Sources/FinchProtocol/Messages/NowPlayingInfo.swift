//
//  NowPlayingInfo.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public struct NowPlayingInfo: Codable {
    
    // MARK: - Properties
    
    public let artist: String
    public let title: String
    
    
    
    // MARK: - Construction
    
    public init(artist: String, title: String) {
        self.artist = artist
        self.title = title
    }
}
