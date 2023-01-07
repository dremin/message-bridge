//
//  ChatMessage.swift
//  
//
//  Created by Sam Johnson on 12/20/22.
//

import Foundation
import Vapor

struct ChatMessage: Content {
    var id: Int64
    var chatId: Int64
    var from: String
    var isMe: Bool
    var body: String
    var received: String
    var attachments: [Attachment]?
}
