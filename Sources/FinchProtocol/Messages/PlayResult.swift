//
//  PlayResult.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 14/09/2025.
//

import Foundation

public enum PlayResult: Codable, Sendable {
    case track(NowPlayingInfo)
    case unavailable(String)
}
