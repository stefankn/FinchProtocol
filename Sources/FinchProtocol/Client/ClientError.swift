//
//  ClientError.swift
//  FinchProtocol
//
//  Created by Stefan Klein Nulent on 23/08/2025.
//

import Foundation

public enum ClientError: Error {
    case missingResponseMessageType
    case unknownResponseMessageType(UInt8)
    case connectionFailure(Error)
    case responseError(String)
}
