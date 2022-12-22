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
    var service: String
    var message: String
}

// TODO: Add validator
