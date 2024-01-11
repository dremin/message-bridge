//
//  Chat.swift
//  
//
//  Created by Sam Johnson on 12/20/22.
//

import Foundation
import Vapor

struct Chat: Content {
    var id: Int64
    var replyId: String
    var name: String
    var lastMessage: String
    var lastMessageId: Int64
    var lastReceived: String
    var service: String
}
