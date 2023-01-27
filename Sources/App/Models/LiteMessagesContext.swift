//
//  LiteMessagesContext.swift
//  
//
//  Created by Sam Johnson on 1/25/23.
//

import Foundation
import Vapor

struct LiteMessagesContext: Encodable {
    var chat: Chat
    var messages: [ChatMessage]
}
