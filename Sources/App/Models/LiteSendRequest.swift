//
//  LiteSendRequest.swift
//  
//
//  Created by Sam Johnson on 1/25/23.
//

import Foundation
import Vapor

struct LiteSendRequest: Content {
    var address: String
    var chatId: Int
    var message: String
}

// TODO: Add validator
