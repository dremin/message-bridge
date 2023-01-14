//
//  SendChatRequest.swift
//  
//
//  Created by Sam Johnson on 12/20/22.
//

import Foundation
import Vapor

struct SendChatRequest: Content {
    var address: String
    var isReply: Bool
    var service: String? // not required for replies
    var message: String
}

// TODO: Add validator
