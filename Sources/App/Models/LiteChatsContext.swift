//
//  LiteChatsContext.swift
//  
//
//  Created by Sam Johnson on 1/25/23.
//

import Foundation
import Vapor

struct LiteChatsContext: Encodable {
    var chats: [Chat]
}
