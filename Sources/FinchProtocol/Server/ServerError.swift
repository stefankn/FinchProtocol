//
//  ServerError.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public enum ServerError: Error {
    case invalidParameter(parameter: String)
}
